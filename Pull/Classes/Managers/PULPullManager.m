//
//  PULPullManager.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullManager.h"

#import "PULAccount.h"

#import "PULConstants.h"

#import "NSDate+Utilities.h"

#import <Firebase/Firebase.h>

const NSInteger kPULPullExirationHours = 6;

@interface PULPullManager ()

@property (nonatomic, strong) Firebase *fireRef;

- (PULPull*)p_pullWithUser:(PULUser*)user;
- (void)p_pruneExpiredPulls;

@end

@implementation PULPullManager

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    }
    return self;
}

- (void)initializePullsWithFriends:(NSArray*)friends;
{
    // initialize pulls array
    _pulls = [[NSMutableArray alloc] init];
    
    Firebase *myPullRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:@"pulls"];
    
    // get list of my pull uids
    [myPullRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *pulls = snapshot.value;
        
        __block NSInteger pullCount = pulls.count;
        
        [pulls enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *pullId = (NSString*)key;
            
            // try to get pull from firebase
            Firebase *pullRef = [[_fireRef childByAppendingPath:@"pulls"] childByAppendingPath:pullId];
            [pullRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (![snapshot hasChildren])
                {
                    // pull no longer exists, remove from my pulls silently
                    [[myPullRef childByAppendingPath:pullId] removeValue];
                }
                else
                {
                    NSDictionary *data = snapshot.value;
                    
                    // instantiate pull
                    // we need to find the friend as a user obj associated with this pull
                    PULPullStatus status = (PULPullStatus)[data[@"status"] integerValue];
                    
                    // convert epoch seconds to date
                    NSTimeInterval secondsToExpire = [data[@"expiration"] integerValue];
                    NSDate *expiration = [NSDate dateWithTimeIntervalSince1970:secondsToExpire];
                    
                    // get uids of users involved
                    NSString *sendingUserUid   = data[@"sendingUser"];
                    NSString *receivingUserUid = data[@"receivingUser"];
                    
                    // determine which user is which
                    PULUser *sendingUser   = nil;
                    PULUser *receivingUser = nil;
                    
                    // block to find a user from the passed in array
                    PULUser* (^findUserFromUid)(NSString *uid) = ^PULUser* (NSString *uid) {
                        PULUser *retUser = nil;
                        for (PULUser *otherUser in friends)
                        {
                            if ([otherUser.uid isEqualToString:uid])
                            {
                                retUser = otherUser;
                            }
                        }
                        
                        return retUser;
                    };
                    
                    // determine which user is which
                    if ([sendingUser.uid isEqualToString:[PULAccount currentUser].uid])
                    {
                        sendingUser = [PULAccount currentUser];
                        receivingUser = findUserFromUid(receivingUserUid);
                    }
                    else
                    {
                        receivingUser = [PULAccount currentUser];
                        sendingUser = findUserFromUid(sendingUserUid);
                    }
                    
                    PULPull *pull = [[PULPull alloc] initExistingPullWithSender:sendingUser receiver:receivingUser status:status expiration:expiration];
                    pull.delegate = self;
                    
                    // start observing
                    [pull startObservingStatus];
                    
                    [_pulls addObject:pull];
                }
                
                // decrement pulls count and see if we're done
                if (--pullCount == 0)
                {
                    // we're done, notify delegate
                    if ([_delegate respondsToSelector:@selector(pullManagerDidLoadPulls:)])
                    {
                        [_delegate pullManagerDidLoadPulls:_pulls];
                    }
                }
            }];
        }];
    }];
}

#pragma mark - Pull Delegate
- (void)pull:(PULPull *)pull didUpdateStatus:(PULPullStatus)status
{
    if ([_delegate respondsToSelector:@selector(pullManagerDidDetectPullStatusChange:)])
    {
        [_delegate pullManagerDidDetectPullStatusChange:pull];
    }
}

#pragma mark - Public
- (void)sendPullToUser:(PULUser*)user
{
    PULLog(@"Sending pull to user: %@", user);
    // create new pull
    PULPull *pull = [[PULPull alloc] initNewPullBetweenSender:[PULAccount currentUser] receiver:user];
    
    // save pull to firebase and get uid
    PULLog(@"Saving pull to firebase");
    Firebase *pullRef = [[_fireRef childByAppendingPath:@"pulls"] childByAutoId];
    pull.uid = pullRef.key;
    
    [pullRef setValue:pull.firebaseRepresentation withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (![self p_handleError:error])
        {
            PULLog(@"Saved pull to firebase");
            
            // completion block for adding to my and friend's pulls
            __block NSInteger blocksToRun = 2;
            void (^addToUsersPullsBlock)(NSError *error, Firebase *ref) = ^void(NSError *error, Firebase *ref){
                if (![self p_handleError:error])
                {
                    PULLog(@"Added pull to my pulls");
                    
                    if (--blocksToRun == 0)
                    {
                        // we're done, start observing pull's status
                        [pull startObservingStatus];
                        
                        // add to pull array
                        [_pulls addObject:pull];
                        
                        pull.delegate = self;
                        [pull startObservingStatus];
                        
                        // notify delegate
                        if ([_delegate respondsToSelector:@selector(pullManagerDidSendPull:)])
                        {
                            [_delegate pullManagerDidSendPull:pull];
                        }
                    }
                }

            };
            
            PULLog(@"Adding pull to my pulls");
            Firebase *myPullRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:@"pulls"];
            [myPullRef setValue:@{pull.uid: @(YES)} withCompletionBlock:addToUsersPullsBlock];
            
            PULLog(@"Added pull to friend's pulls");
            Firebase *friendsPullRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:user.uid] childByAppendingPath:@"pulls"];
            [friendsPullRef setValue:@{pull.uid: @(YES)} withCompletionBlock:addToUsersPullsBlock];
        }
    }];
    
}

- (void)acceptPullFromUser:(PULUser*)user
{
    NSParameterAssert(user);
    
    PULPull *pull = [self p_pullWithUser:user];
    NSDate *expiration = [NSDate dateWithHoursFromNow:kPULPullExirationHours];
    pull.expiration = expiration;
    
    [self p_updatePull:pull status:PULPullStatusPulled];
    
}

- (void)unpullUser:(PULUser*)user
{
    NSParameterAssert(user);
    
    PULPull *pull = [self p_pullWithUser:user];
    
    [self p_updatePull:pull status:PULPullStatusNone];
}

- (void)suspendPullWithUser:(PULUser*)user
{
    NSParameterAssert(user);
    
    PULPull *pull = [self p_pullWithUser:user];
    
    [self p_updatePull:pull status:PULPullStatusSuspended];
}

- (void)resumePullWithUser:(PULUser*)user
{
    // doing the same thing as accept
    [self acceptPullFromUser:user];
}

#pragma mark - Private
/**
 *  Locally and remotely updates the status of a pull and notifies the delegate
 *
 *  @param pull      PUll
 *  @param newStatus New status
 */
- (void)p_updatePull:(PULPull*)pull status:(PULPullStatus)newStatus;
{
    NSParameterAssert(pull);
    
    pull.status = newStatus;
    
    Firebase *pullRef = [[_fireRef childByAppendingPath:@"pulls"] childByAppendingPath:pull.uid];
    [pullRef setValue:pull.firebaseRepresentation withCompletionBlock:^(NSError *error, Firebase *ref) {
        // we don't need to notify the delegate because we're already observing changes to status in the pull itself, and it'll report back here when it changes
        [self p_handleError:error];
        
    }];
}

/**
 *  Gets a pull with the specified user
 *
 *  @param user User
 *
 *  @return Pull
 */
- (PULPull*)p_pullWithUser:(PULUser*)user
{
    NSParameterAssert(user);
    
    PULPull *retPull = nil;
    for (PULPull *pull in _pulls)
    {
        if ([pull containsUser:user])
        {
            retPull = pull;
            
            break;
        }
    }
    
    return retPull;
}

/**
 *  Checks if there is an error, and notifies the delegate if there is
 *
 *  @param error Error
 *
 *  @return Yes if error, No if error is nil
 */
- (BOOL)p_handleError:(NSError*)error
{
    if (error)
    {
        PULLogError(@"Pull", @"%@", error.localizedDescription);
        
        if ([_delegate respondsToSelector:@selector(pullManagerEncounteredError:)])
        {
            [_delegate pullManagerEncounteredError:error];
        }
        
        return YES;
    }
    return NO;
}

/**
 *  Does everything necessary to remove a pull locally and remotely
 */
- (void)p_removePull:(PULPull*)pull
{
    PULLog(@"Removing pull: %@", pull);
    [pull stopObservingStatus];
    // remove from _pulls
    [_pulls removeObject:pull];
    
    Firebase *pullsRef = [[_fireRef childByAppendingPath:@"pulls"] childByAppendingPath:pull.uid];
    [pullsRef removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
        if (![self p_handleError:error])
        {
            PULLog(@"Removed pull");
            
            if ([_delegate respondsToSelector:@selector(pullManagerDidRemovePull)])
            {
                [_delegate pullManagerDidRemovePull];
            }
        }
    }];
}

/**
 *  Checks all pulls in _pulls. Removes pulls locally and from firebase if status is none or expired, or if expiration has passed
 */
- (void)p_pruneExpiredPulls
{
    PULLog(@"Pruning pulls");
    
    NSMutableIndexSet *markedPulls = [NSMutableIndexSet indexSet];
    
    for (int i = 0; i < _pulls.count; i++)
    {
        PULPull *pull = _pulls[i];
        
        // check expiration
        NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
        if ([now isLaterThanDate:pull.expiration])
        {
            pull.status = PULPullStatusExpired;
        }
        
        // check status
        if (pull.status == PULPullStatusNone || pull.status == PULPullStatusExpired)
        {
            [markedPulls addIndex:i];
        }
    }
    
    [markedPulls enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        PULPull *pull = _pulls[idx];
        
        [self p_removePull:pull];
        
    }];
}

@end
