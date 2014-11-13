//
//  PULFriendManager.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULFriendManager.h"

#import "PULAccount.h"
#import "PULPull.h"

#import "PULConstants.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>
#import <CoreLocation/CoreLocation.h>

const float kPULMaxDistanceToBeNearby = 48280.3;    // 30 miles

NSString * const kPULFriendRemovedKey = @"kPULFriendRemovedKey";

@interface PULFriendManager ()

@property (nonatomic, strong) Firebase *fireRef;

@end

@implementation PULFriendManager

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    }
    return self;
}

- (void)initializeFriends
{
    _allFriends = [[NSMutableArray alloc] init];
    _pendingFriends = [[NSMutableArray alloc] init];
    _invitedFriends = [[NSMutableArray alloc] init];
    
    __block NSInteger arraysToFill = 3;
    
    void (^completion)() = ^void(){
        if (--arraysToFill == 0)
        {
            // done
            if ([_delegate respondsToSelector:@selector(friendManagerDidLoadFriends:)])
            {
                [_delegate friendManagerDidLoadFriends:self];
            }
        }
    };
    
    [self p_usersFromEndpoint:@"friends" userBlock:^(PULUser *user, BOOL done) {
        [_allFriends addObject:user];
        user.delegate = self;
        
        if (done)
        {
            completion();
        }
    }];
    
    [self p_usersFromEndpoint:@"pending" userBlock:^(PULUser *user, BOOL done) {
        [_pendingFriends addObject:user];
        
        if (done)
        {
            completion();
        }
    }];
    
    [self p_usersFromEndpoint:@"invited" userBlock:^(PULUser *user, BOOL done) {
        [_invitedFriends addObject:user];
        
        if (done)
        {
            completion();
        }
    }];
}

- (void)addFriendsFromFacebook
{
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (![self p_handleError:error])
        {
            NSArray *friends = ((NSDictionary*)result)[@"data"];
            
            for (NSDictionary *friend in friends)
            {
                NSString *fbId = friend[@"id"];
                
                // check if this is in the list of user's previously removed
                NSString *key = [NSString stringWithFormat:@"%@-facebook:%@", kPULFriendRemovedKey, fbId];
                BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:key];
                if (!val)
                {
                    // haven't previously removed, check users
                    for (PULUser *user in _allFriends)
                    {
                        NSString *userUID = [NSString stringWithFormat:@"facebook:%@", fbId];
                        if (![user.uid isEqualToString:userUID])
                        {
                            // found a user we need to add
                            // create a user out of the fbId
                            [self p_userFromUid:userUID completion:^(PULUser *user) {
                                user.delegate = self;
                                
                                [self p_forceAddUserAsFriend:user completion:^(NSError *error) {
                                    if (![self p_handleError:error])
                                    {
                                        // add to friends
                                        [_allFriends addObject:user];
                                        if ([_delegate respondsToSelector:@selector(friendManager:didForceAddUser:)])
                                        {
                                            [_delegate friendManager:self didForceAddUser:user];
                                        }
                                        
                                    }
                                }];
                            }];
                        }
                    }
                }
            }
        }
    }];
}

#pragma mark - User Delegate
- (void)userDidRefresh:(PULUser *)user
{
    if ([_delegate respondsToSelector:@selector(friendManager:didDetectFriendChange:)])
    {
        [_delegate friendManager:self didDetectFriendChange:user];
    }
}

#pragma mark - Public
- (void)reorganizeWithPulls:(NSArray*)pulls
{
    _pulledFriends      = [[NSMutableArray alloc] init];
    _pullPendingFriends = [[NSMutableArray alloc] init];
    _pullInvitedFriends = [[NSMutableArray alloc] init];
    _nearbyFriends      = [[NSMutableArray alloc] init];
    _farAwayFriends     = [[NSMutableArray alloc] init];
    
    for (PULUser *user in _allFriends)
    {
        BOOL isAdded = NO;
        
        for (PULPull *pull in pulls)
        {
            if ([pull containsUser:user])
            {
                // we found this user's pull. Lets figure out where they go
                if (pull.status == PULPullStatusPulled || pull.status == PULPullStatusSuspended)
                {
                    [_pulledFriends addObject:user];
                    isAdded = YES;
                }
                else if (pull.status == PULPullStatusPending)
                {
                    // what end is the other user on?
                    if ([pull.sendingUser isEqual:user])
                    {
                        // other user sent to me
                        [_pullPendingFriends addObject:user];
                    }
                    else
                    {
                        // we sent pull to this user
                        [_pullInvitedFriends addObject:user];
                    }
                    
                    isAdded = YES;
                }
                
                break;
            }
        }
        
        // if user hasn't been added yet, we need to determine if they are nearby or faraway
        if (!isAdded)
        {
            CLLocationDistance distance = [user.location distanceFromLocation:[PULAccount currentUser].location];
            
            if (distance <= kPULMaxDistanceToBeNearby)
            {
                // we're nearby
                [_nearbyFriends addObject:user];
            }
            else
            {
                [_farAwayFriends addObject:user];
            }
        }
    }
    
    [self p_sortAllArrays];
    
    if ([_delegate respondsToSelector:@selector(friendManagerDidReorganize:)])
    {
        [_delegate friendManagerDidReorganize:self];
    }
}

- (void)updateOrganizationWithPull:(PULPull*)pull
{
    // find user we need to move
    PULUser *user;
    NSMutableArray *arrayToMoveTo;
    if ([pull.sendingUser isEqual:[PULAccount currentUser]])
    {
        user = pull.receivingUser;
    }
    else
    {
        user = pull.sendingUser;
    }
    
    // determine which array this user needs to be in
    if (pull.status == PULPullStatusPulled || pull.status == PULPullStatusSuspended)
    {
        arrayToMoveTo = _pulledFriends;
    }
    else if (pull.status == PULPullStatusPending)
    {
        // what end is the other user on?
        if ([pull.sendingUser isEqual:user])
        {
            // other user sent to me
            arrayToMoveTo = _pullPendingFriends;
        }
        else
        {
            // we sent pull to this user
            arrayToMoveTo = _pullInvitedFriends;
        }
    }
    else
    {
        CLLocationDistance distance = [user.location distanceFromLocation:[PULAccount currentUser].location];
        
        if (distance <= kPULMaxDistanceToBeNearby)
        {
            // we're nearby
            arrayToMoveTo = _nearbyFriends;
        }
        else
        {
            arrayToMoveTo = _farAwayFriends;
        }
    }
    
    [self p_moveUser:user toArray:arrayToMoveTo];
    
    [self p_sortArrayByDistanceFromMe:arrayToMoveTo];
    
    if ([_delegate respondsToSelector:@selector(friendManagerDidReorganize:)])
    {
        [_delegate friendManagerDidReorganize:self];
    }

}

- (void)updateOrganizationForUser:(PULUser*)user;
{
    // verify we're still friends with this person
    if ([_allFriends containsObject:user])
    {
        if ([_nearbyFriends containsObject:user] || [_farAwayFriends containsObject:user])
        {
            BOOL didChange = NO;
            
            CLLocationDistance distance = [user.location distanceFromLocation:[PULAccount currentUser].location];
            
            if (distance <= kPULMaxDistanceToBeNearby && ![_nearbyFriends containsObject:user])
            {
                // we're nearby
                [self p_moveUser:user toArray:_nearbyFriends];
                [self p_sortArrayByDistanceFromMe:_nearbyFriends];
                
                didChange = YES;
            }
            else if (![_farAwayFriends containsObject:user])
            {
                [self p_moveUser:user toArray:_farAwayFriends];
                [self p_sortArrayByDistanceFromMe:_farAwayFriends];
                
                didChange = YES;
            }

            if (didChange)
            {
                if ([_delegate respondsToSelector:@selector(friendManagerDidReorganize:)])
                {
                    [_delegate friendManagerDidReorganize:self];
                }
            }
        }
    }
    else
    {
        // remove user from all arrays
        [self p_moveUser:user toArray:nil];
    }
}

- (void)sendFriendRequestToUser:(PULUser*)user
{
    
    [self p_addRelationshipFromMeToYouWithEndpoints:@[@"invited", @"pending"] friend:user completion:^{
        
        [_invitedFriends addObject:user];
        if ([_delegate respondsToSelector:@selector(friendManager:didSendFriendRequestToUser:)])
        {
            [_delegate friendManager:self didSendFriendRequestToUser:user];
        }
    }];
}

- (void)acceptFriendRequestFromUser:(PULUser*)user
{
    
    [self p_removeRelationshipFromMeToYouWithEndpoints:@[@"invited", @"pending"] friend:user completion:^{
        ;
    }];
    
    [self p_addRelationshipFromMeToYouWithEndpoints:@[@"friends", @"friends"] friend:user completion:^{
        
        [_pendingFriends removeObject:user];
        [_allFriends addObject:user];
        user.delegate = self;
        
        if ([_delegate respondsToSelector:@selector(friendManager:didAcceptFriendRequestFromUser:)])
        {
            [_delegate friendManager:self didAcceptFriendRequestFromUser:user];
        }
    }];
}

- (void)unfriendUser:(PULUser*)user
{
    
    [self p_removeRelationshipFromMeToYouWithEndpoints:@[@"friends", @"friends"] friend:user completion:^{
        
        [_allFriends removeObject:user];

        if ([_delegate respondsToSelector:@selector(friendManager:didUnfriendUser:)])
        {
            [_delegate friendManager:self didUnfriendUser:user];
        }
    }];
    
    // mark that we're deleting this user
    NSString *key = [NSString stringWithFormat:@"%@-%@", kPULFriendRemovedKey, user.uid];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
}

#pragma mark - Private
- (void)p_userFromUid:(NSString*)uid completion:(void(^)(PULUser *user))completion
{
    Firebase *ref = [[_fireRef childByAppendingPath:@"users"] childByAppendingPath:uid];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *data = snapshot.value;
        
        PULUser *user = [[PULUser alloc] initFromFirebaseData:data uid:snapshot.key];
        
        completion(user);
    }];
}

- (void)p_usersFromEndpoint:(NSString*)endpoint userBlock:(void(^)(PULUser *user, BOOL done))completion
{
    Firebase *ref = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:endpoint];
    
    // get uids at this point
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *data = snapshot.value;

        __block NSInteger userCount = data.count;
        
        [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *uid = key;
            [self p_userFromUid:uid completion:^(PULUser *user) {
                
                BOOL isDone = NO;
                if (--userCount == 0)
                {
                    isDone = YES;
                }
                
                completion(user, isDone);
            }];
        }];
    }];

}

- (void)p_sortAllArrays
{
    [self p_sortArrayByDistanceFromMe:_allFriends];
    [self p_sortArrayByDistanceFromMe:_pulledFriends];
    [self p_sortArrayByDistanceFromMe:_pullPendingFriends];
    [self p_sortArrayByDistanceFromMe:_pullInvitedFriends];
}

- (void)p_sortArrayByDistanceFromMe:(NSMutableArray*)array
{
    NSParameterAssert(array);
    
    [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        PULUser *user1 = obj1;
        PULUser *user2 = obj2;
        
        CLLocationDistance dist1 = [user1.location distanceFromLocation:[PULAccount currentUser].location];
        CLLocationDistance dist2 = [user2.location distanceFromLocation:[PULAccount currentUser].location];
        
        NSComparisonResult result;
        
        if (dist1 < dist2)
        {
            result = NSOrderedAscending;
        }
        else if (dist1 > dist2)
        {
            result = NSOrderedDescending;
        }
        else
        {
            result = NSOrderedSame;
        }

        return result;
    }];
}

- (void)p_moveUser:(PULUser*)user toArray:(NSMutableArray*)array
{
    // block to check if user is in an array and remove them if they are
    void (^removeUserFromArray)(PULUser *user, NSMutableArray *array) = ^void (PULUser *user, NSMutableArray *array)
    {
        if ([array containsObject:user])
        {
            [array removeObject:user];
        }
    };
    
    removeUserFromArray(user, _pulledFriends);
    removeUserFromArray(user, _pullPendingFriends);
    removeUserFromArray(user, _pullInvitedFriends);
    removeUserFromArray(user, _nearbyFriends);
    removeUserFromArray(user, _farAwayFriends);
    
    if (array)
    {
        [array addObject:user];
    }
}

- (void)p_forceAddUserAsFriend:(PULUser*)friend completion:(void (^)(NSError *error))completion
{
    PULLog(@"Force adding friend: %@", friend);

    [self p_addRelationshipFromMeToYouWithEndpoints:@[@"friends", @"friends"] friend:friend completion:^{
        [self updateOrganizationForUser:friend];
    }];
}

- (void)p_addRelationshipFromMeToYouWithEndpoints:(NSArray*)endpoints friend:(PULUser*)friend completion:(void(^)())completion;
{
    NSString *myEndpoint = endpoints[0];
    NSString *friendEndpoint = endpoints[1];
    
    __block NSInteger blockCount = 2;
    void (^friendAddCompletion)(NSError *error, Firebase *ref) = ^(NSError *error, Firebase *ref)
    {
        if (![self p_handleError:error])
        {
            if (--blockCount == 0)
            {
                completion();
            }
        }
    };
    
    Firebase *myRef = [[[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:myEndpoint] childByAppendingPath:friend.uid];
    [myRef setValue:@(YES) withCompletionBlock:friendAddCompletion];
    
    Firebase *friendRef = [[[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:friend.uid] childByAppendingPath:friendEndpoint] childByAppendingPath:[PULAccount currentUser].uid];
    [friendRef setValue:@(YES) withCompletionBlock:friendAddCompletion];
}

- (void)p_removeRelationshipFromMeToYouWithEndpoints:(NSArray*)endpoints friend:(PULUser*)friend completion:(void(^)())completion;
{
    NSString *myEndpoint = endpoints[0];
    NSString *friendEndpoint = endpoints[1];
    
    __block NSInteger blockCount = 2;
    void (^friendRemoveCompletion)(NSError *error, Firebase *ref) = ^(NSError *error, Firebase *ref)
    {
        if (![self p_handleError:error])
        {
            if (--blockCount == 0)
            {
                completion();
            }
        }
    };
    
    Firebase *myRef = [[[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:myEndpoint] childByAppendingPath:friend.uid];
    [myRef removeValueWithCompletionBlock:friendRemoveCompletion];
    
    Firebase *friendRef = [[[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:friend.uid] childByAppendingPath:friendEndpoint] childByAppendingPath:[PULAccount currentUser].uid];
    [friendRef removeValueWithCompletionBlock:friendRemoveCompletion];

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
        PULLogError(@"Friending", @"%@", error.localizedDescription);
        
        if ([_delegate respondsToSelector:@selector(pullManagerEncounteredError:)])
        {
            [_delegate friendManager:self didEncounterError:error];
        }
        
        return YES;
    }
    return NO;
}

@end
