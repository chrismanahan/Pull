//
//  PULPullManager.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullManager.h"

#import "PULAccount.h"
#import "PULFriendManager.h"

#import "PULConstants.h"

#import "NSDate+Utilities.h"

#import <Firebase/Firebase.h>

const NSInteger kPULPullExirationHours = 6;

const NSInteger kPULPullManagerPruneInterval = 30; //seconds

@interface PULPullManager ()

@property (nonatomic, strong) Firebase *fireRef;

@property (nonatomic) FirebaseHandle accountPullAddObserver;
@property (nonatomic) FirebaseHandle accountPullRemoveObserver;

@property (nonatomic, strong) NSTimer *pruneTimer;

@end

@implementation PULPullManager

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
        
        _pulls = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)initializePulls
{
    NSAssert([PULAccount currentUser].friendManager.allFriends != nil, @"Need to have an array of friends to proceed");
    
    PULLog(@"initializing pulls with friends");
    // initialize pulls array
    _pulls = [[NSMutableArray alloc] init];
    
    Firebase *myPullRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:@"pulls"];
    
    // get list of my pull uids
    [myPullRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *pulls = snapshot.value;
        
        if (![pulls isKindOfClass:[NSNull class]])
        {
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
                        PULPull *pull = [self p_pullFromFirebaseSnapshot:snapshot];
                        
                        [_pulls addObject:pull];
                    }
                    
                    
                    BOOL done = --pullCount == 0;
                    // decrement pulls count and see if we're done
                    if (done)
                    {
                        // we're done, notify delegate
                        if ([_delegate respondsToSelector:@selector(pullManagerDidLoadPulls:)])
                        {
                            [_delegate pullManagerDidLoadPulls:_pulls];
                        }
                        
                        // we should prune pulls that are expired
                        [self p_pruneExpiredPulls];
                        
                        if (_pruneTimer)
                        {
                            [_pruneTimer invalidate];
                            _pruneTimer = nil;
                        }
                        
                        PULLog(@"starting pruning timer");
                        _pruneTimer = [NSTimer scheduledTimerWithTimeInterval:kPULPullManagerPruneInterval
                                                                       target:self
                                                                     selector:@selector(p_pruneExpiredPulls)
                                                                     userInfo:nil
                                                                      repeats:YES];
                    }
                }];
            }];
        }
        else
        {
            PULLog(@"we have no pulls right now");
            
            // we're done, notify delegate
            if ([_delegate respondsToSelector:@selector(pullManagerDidLoadPulls:)])
            {
                [_delegate pullManagerDidLoadPulls:_pulls];
            }
        }
        
        // start watching our pulls
        [self p_stopObservingAccountPulls];
        [self p_startObservingAccountPulls];
    }];
}

- (PULPull*)p_pullFromFirebaseSnapshot:(FDataSnapshot*)snapshot
{
    NSAssert([PULAccount currentUser].friendManager.allFriends != nil, @"need to initialize friends first");
    
    NSDictionary *data = snapshot.value;
    PULPull *pull = nil;
    
    if (![data isKindOfClass:[NSNull class]])
    {
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
            NSArray *friends = [PULAccount currentUser].friendManager.allFriends;
            for (PULUser *otherUser in friends)
            {
                if ([otherUser.uid isEqualToString:uid])
                {
                    retUser = otherUser;
                    break;
                }
            }
            
            return retUser;
        };
        
        // determine which user is which
        if ([sendingUserUid isEqualToString:[PULAccount currentUser].uid])
        {
            sendingUser = [PULAccount currentUser];
            receivingUser = findUserFromUid(receivingUserUid);
        }
        else
        {
            receivingUser = [PULAccount currentUser];
            sendingUser = findUserFromUid(sendingUserUid);
        }
        
        pull = [[PULPull alloc] initExistingPullWithUid:snapshot.key sender:sendingUser receiver:receivingUser status:status expiration:expiration];
        pull.delegate = self;
        
        // start observing
        [pull startObservingStatus];
    }
    return pull;
}

#pragma mark - Pull Delegate
- (void)pull:(PULPull *)pull didUpdateStatus:(PULPullStatus)status
{
    if ([_delegate respondsToSelector:@selector(pullManagerDidDetectPullStatusChange:)])
    {
        [_delegate pullManagerDidDetectPullStatusChange:pull];
    }
}

- (void)pull:(PULPull *)pull didUpdateExpiration:(NSDate *)date
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
        if (![PULError handleError:error target:_delegate selector:@selector(pullManagerEncounteredError:) object:error])
        {
            PULLog(@"Saved pull to firebase");
            
            // completion block for adding to my and friend's pulls
            __block NSInteger blocksToRun = 2;
            void (^addToUsersPullsBlock)(NSError *error, Firebase *ref) = ^void(NSError *error, Firebase *ref){
                if (![PULError handleError:error target:_delegate selector:@selector(pullManagerEncounteredError:) object:error])
                {
                    if (--blocksToRun == 0)
                    {
                        PULLog(@"Added pull to my pulls");
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
            [myPullRef updateChildValues:@{pull.uid: @(YES)} withCompletionBlock:addToUsersPullsBlock];
            
            PULLog(@"Added pull to friend's pulls");
            Firebase *friendsPullRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:user.uid] childByAppendingPath:@"pulls"];
            [friendsPullRef updateChildValues:@{pull.uid: @(YES)} withCompletionBlock:addToUsersPullsBlock];
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
    
    [self p_removePull:pull];
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
 *  Starts observing account's pulls
 */
- (void)p_startObservingAccountPulls
{
    PULLog(@"starting to observe my pulls");
    Firebase *pullRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:@"pulls"];
    _accountPullAddObserver =  [pullRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        PULLog(@"observed added pull: %@", snapshot.key);
        
        Firebase *newPullRef = [[_fireRef childByAppendingPath:@"pulls"]  childByAppendingPath:snapshot.key];
        [newPullRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            PULPull *pull = [self p_pullFromFirebaseSnapshot:snapshot];
            
            if (pull)
            {
                [_pulls addObject:pull];
                
                if ([_delegate respondsToSelector:@selector(pullManagerDidReceivePull:)])
                {
                    [_delegate pullManagerDidReceivePull:pull];
                }
            }
        }];
        
    }];
    
    _accountPullRemoveObserver = [pullRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        PULLog(@"observed removed pull");
        
        NSInteger removeIndex = -1;
        for (int i = 0; i < _pulls.count; i++)
        {
            PULPull *pull = _pulls[i];
            
            if ([pull.uid isEqualToString:snapshot.key])
            {
                removeIndex = i;
                break;
            }
        }
        
        if (removeIndex >= 0)
        {
            [_pulls removeObjectAtIndex:removeIndex];
        }
        
        if ([_delegate respondsToSelector:@selector(pullManagerDidRemovePull)])
        {
            [_delegate pullManagerDidRemovePull];
        }
        
        PULLog(@"%@", snapshot.key);
    }];
}

/**
 *  Stops observing account's pulls
 */
- (void)p_stopObservingAccountPulls
{
    if (_accountPullAddObserver || _accountPullRemoveObserver)
    {
        [_fireRef removeObserverWithHandle:_accountPullAddObserver];
        [_fireRef removeObserverWithHandle:_accountPullRemoveObserver];
    }
}

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
        [PULError handleError:error target:_delegate selector:@selector(pullManagerEncounteredError:) object:error];
        
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
 *  Does everything necessary to remove a pull locally and remotely
 */
- (void)p_removePull:(PULPull*)pull
{
    PULLog(@"Removing pull: %@", pull);
    [pull stopObservingStatus];
    // remove from _pulls
    [_pulls removeObject:pull];
    
    __block NSInteger blocksToRun = 3;
    void (^removeBlock)(NSError *error, Firebase *ref) = ^void(NSError *error, Firebase *ref){
        if (![PULError handleError:error target:_delegate selector:@selector(pullManagerEncounteredError:) object:error])
        {
            PULLog(@"Removed pull");
            
            if (--blocksToRun == 0)
            {
                if ([_delegate respondsToSelector:@selector(pullManagerDidRemovePull)])
                {
                    [_delegate pullManagerDidRemovePull];
                }
            }
        }
    };

    
    Firebase *pullsRef = [[_fireRef childByAppendingPath:@"pulls"] childByAppendingPath:pull.uid];
    [pullsRef removeValueWithCompletionBlock:removeBlock];
    
    Firebase *sendRef = [[[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:pull.sendingUser.uid] childByAppendingPath:@"pulls"] childByAppendingPath:pull.uid];
    Firebase *recRef = [[[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:pull.receivingUser.uid] childByAppendingPath:@"pulls"] childByAppendingPath:pull.uid];
    
    [sendRef removeValueWithCompletionBlock:removeBlock];
    [recRef removeValueWithCompletionBlock:removeBlock];
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
        if ([now isLaterThanDate:pull.expiration] && [pull.expiration isLaterThanDate:[NSDate dateWithTimeIntervalSince1970:0]])
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
