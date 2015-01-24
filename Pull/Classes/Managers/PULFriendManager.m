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

#import "PULPush.h"

#import "PULConstants.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>
#import <CoreLocation/CoreLocation.h>

const float kPULMaxDistanceToBeNearby = 99999999;// 48280.3;    // 30 miles

NSString * const kPULFriendRemovedKey = @"kPULFriendRemovedKey";

@interface PULFriendManager ()

@property (nonatomic, strong) Firebase *fireRef;

@property (nonatomic) FirebaseHandle pendingFriendsObserver;
@property (nonatomic) FirebaseHandle invitedFriendsObserver;

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
    _allFriends         = [[NSMutableArray alloc] init];
    _nearbyFriends      = [[NSMutableArray alloc] init];
    _farAwayFriends     = [[NSMutableArray alloc] init];
    _pulledFriends      = [[NSMutableArray alloc] init];
    _pullPendingFriends = [[NSMutableArray alloc] init];
    _pullInvitedFriends = [[NSMutableArray alloc] init];
    _pendingFriends     = [[NSMutableArray alloc] init];
    _invitedFriends     = [[NSMutableArray alloc] init];
    
    __block NSInteger arraysToFill = 3;
    
    void (^completion)() = ^void(){
        if (--arraysToFill == 0)
        {
            // done
            if ([_delegate respondsToSelector:@selector(friendManagerDidLoadFriends:)])
            {
                [_delegate friendManagerDidLoadFriends:self];
            }
            
            [self p_stopObservingFriendsPending];
            [self p_stopObservingFriendsInvited];
            
            [self p_startObservingFriendsPending];
            [self p_startObservingFriendsInvited];
        }
    };
    
    [self p_usersFromEndpoint:@"friends" completion:^(NSArray *users) {
        if (users)
        {
            PULLog(@"added %i users to friends", users.count);
            _allFriends = [[NSMutableArray alloc] initWithArray:users];
        }
        else
        {
            PULLog(@"added NO users to friends");
        }
        
        completion();
    }];
    
    [self p_usersFromEndpoint:@"pending" completion:^(NSArray *users) {
        if (users)
        {
            PULLog(@"added %i users to pending", users.count);
            _pendingFriends = [[NSMutableArray alloc] initWithArray:users];
        }
        else
        {
            PULLog(@"added NO users to pending");
        }
        
        completion();
    }];
    
    [self p_usersFromEndpoint:@"invited" completion:^(NSArray *users) {
        if (users)
        {
            PULLog(@"added %i users to invited", users.count);
            _invitedFriends = [[NSMutableArray alloc] initWithArray:users];
        }
        else
        {
            PULLog(@"added NO users to invited");
        }
        
        completion();
    }];
}

- (void)addFriendsFromFacebook
{
    PULLog(@"Trying to add friends from facebook");
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (![PULError handleError:error target:_delegate selector:@selector(friendManagerDidEncounterError:) object:error])
        {
            NSArray *friends = ((NSDictionary*)result)[@"data"];
            PULLog(@"got %zd friends", friends.count);
            
            for (NSDictionary *friend in friends)
            {
                NSString *fbId = friend[@"id"];
                
                // check if this is in the list of user's previously removed
                NSString *key = [NSString stringWithFormat:@"%@-facebook:%@", kPULFriendRemovedKey, fbId];
                BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:key];
                if (!val)
                {
                    // haven't previously removed, check users
                    BOOL needToAdd = YES;
                    NSString *userUID = [NSString stringWithFormat:@"facebook:%@", fbId];
                    
                    for (PULUser *user in _allFriends)
                    {
                        if ([user.uid isEqualToString:userUID])
                        {
                            needToAdd = NO;
                            break;
                        }
                    }
                    
                    if (needToAdd)
                    {
                        // found a user we need to add
                        // create a user out of the fbId
                        PULLog(@"force adding %@", fbId);
                        [self p_userFromUid:userUID completion:^(PULUser *user) {
                            
                            if (user)
                            {
                                [self p_forceAddUserAsFriend:user completion:^(PULUser *friend) {
                                    if (![PULError handleError:error target:_delegate selector:@selector(friendManagerDidEncounterError:) object:error])
                                    {
                                        // add to friends
                                        [_allFriends addObject:friend];
                                        [_nearbyFriends addObject:friend];
                                        
//                                        [self updateOrganizationForUser:friend];
                                        
                                        PULLog(@"force added user");
                                        if ([_delegate respondsToSelector:@selector(friendManager:didForceAddUser:)])
                                        {
                                            [_delegate friendManager:self didForceAddUser:user];
                                        }
                                        
                                    }
                                }];
                            }
                        }];
                    }
                }
            }
        }
    }];
}

#pragma mark - User Delegate
//- (void)userDidRefresh:(PULUser *)user
//{
//    if ([_delegate respondsToSelector:@selector(friendManager:didDetectFriendChange:)])
//    {
//        [_delegate friendManager:self didDetectFriendChange:user];
//    }
//}

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

//- (void)updateOrganizationForUser:(PULUser*)user;
//{
//    PULLog(@"updating organization with user: %@", user.fullName);
//    // verify we're still friends with this person
//    if ([_allFriends containsObject:user])
//    {
//        BOOL haveLocation = (BOOL)[PULAccount currentUser].location;
//
//        if (([_nearbyFriends containsObject:user] || [_farAwayFriends containsObject:user]) && haveLocation)
//        {
//            BOOL didChange = NO;
//            
//            CLLocationDistance distance = [user.location distanceFromLocation:[PULAccount currentUser].location];
//            
//            if (distance <= kPULMaxDistanceToBeNearby && ![_nearbyFriends containsObject:user])
//            {
//                PULLog(@"user is nearby now");
//                // we're nearby
//                [self p_moveUser:user toArray:_nearbyFriends];
//                [self p_sortArrayByDistanceFromMe:_nearbyFriends];
//                
//                didChange = YES;
//            }
//            else if (![_farAwayFriends containsObject:user] && distance > kPULMaxDistanceToBeNearby)
//            {
//                PULLog(@"user is far now");
//                [self p_moveUser:user toArray:_farAwayFriends];
//                [self p_sortArrayByDistanceFromMe:_farAwayFriends];
//                
//                didChange = YES;
//            }
//
//            if (didChange)
//            {
//                PULLog(@"organization changed");
//                if ([_delegate respondsToSelector:@selector(friendManagerDidReorganize:)])
//                {
//                    [_delegate friendManagerDidReorganize:self];
//                }
//            }
//        }
//    }
//    else
//    {
//        // remove user from all arrays
//        [self p_moveUser:user toArray:nil];
//    }
//}

- (void)sendFriendRequestToUser:(PULUser*)user
{
    
    [self p_addRelationshipFromMeToYouWithEndpoints:@[@"invited", @"pending"] friend:user completion:^{
        
        [_invitedFriends addObject:user];
        if ([_delegate respondsToSelector:@selector(friendManager:didSendFriendRequestToUser:)])
        {
            [_delegate friendManager:self didSendFriendRequestToUser:user];
        }
        
        // push
        [PULPush sendPushType:kPULPushTypeSendFriendRequest to:user from:[PULAccount currentUser]];
    }];
}

- (void)acceptFriendRequestFromUser:(PULUser*)user
{
    
    [self p_removeRelationshipFromMeToYouWithEndpoints:@[@"pending", @"invited"] friend:user completion:^{
        ;
    }];
    
    [self p_addRelationshipFromMeToYouWithEndpoints:@[@"friends", @"friends"] friend:user completion:^{
        
        [_pendingFriends removeObject:user];
        [_allFriends addObject:user];
        
        if ([_delegate respondsToSelector:@selector(friendManager:didAcceptFriendRequestFromUser:)])
        {
            [_delegate friendManager:self didAcceptFriendRequestFromUser:user];
        }
        
        // push
        [PULPush sendPushType:kPULPushTypeAcceptFriendRequest to:user from:[PULAccount currentUser]];
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
/**
 *  Starts observing account's pulls
 */
- (void)p_startObservingFriendsPending
{
    PULLog(@"starting to observe pending friends");
    Firebase *pendingRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:@"pending"];
    _pendingFriendsObserver =  [pendingRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        PULLog(@"observed added pending friend: %@", snapshot.key);
        
        BOOL needsAdd = YES;
        // check if this user is already in pending
        for (PULUser *friend in _pendingFriends)
        {
            if ([friend.uid isEqualToString:snapshot.key])
            {
                needsAdd = NO;
                break;
            }
        }
        
        if (needsAdd)
        {
            [self p_userFromUid:snapshot.key completion:^(PULUser *user) {
                if (user)
                {
                    [_pendingFriends addObject:user];
                    
                    if ([_delegate respondsToSelector:@selector(friendManager:didReceiveFriendRequestFromUser:)])
                    {
                        [_delegate friendManager:self didReceiveFriendRequestFromUser:user];
                    }
                }
            }];
        }
        
    }];
}

- (void)p_stopObservingFriendsPending
{
    if (_pendingFriendsObserver)
    {
        [_fireRef removeObserverWithHandle:_pendingFriendsObserver];
    }
}

- (void)p_startObservingFriendsInvited
{
    PULLog(@"starting to observe invited friends");
    Firebase *pendingRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:@"invited"];
    _invitedFriendsObserver =  [pendingRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        PULLog(@"observed removal of invited friend: %@", snapshot.key);
        
        PULUser *userToRemove = nil;
        // check if this user is in invited
        for (PULUser *friend in _invitedFriends)
        {
            if ([friend.uid isEqualToString:snapshot.key])
            {
                userToRemove = friend;
                break;
            }
        }
        
        if (userToRemove)
        {
            [_invitedFriends removeObject:userToRemove];
            [_allFriends addObject:userToRemove];
            
            if ([_delegate respondsToSelector:@selector(friendManager:friendRequestWasAcceptedWithUser:)])
            {
                [_delegate friendManager:self friendRequestWasAcceptedWithUser:userToRemove];
            }
        }
        
    }];

}

- (void)p_stopObservingFriendsInvited
{
    if (_invitedFriendsObserver)
    {
        [_fireRef removeObserverWithHandle:_invitedFriendsObserver];
    }
}


- (void)p_userFromUid:(NSString*)uid completion:(void(^)(PULUser *user))completion
{
    Firebase *ref = [[_fireRef childByAppendingPath:@"users"] childByAppendingPath:uid];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *data = snapshot.value;
        
        PULUser *user = nil;
        if (![data isKindOfClass:[NSNull class]])
        {
            user = [[PULUser alloc] initFromFirebaseData:data uid:snapshot.key];
        }
        
        if (completion)
        {
            completion(user);
        }
    }];
}

- (void)p_usersFromEndpoint:(NSString*)endpoint completion:(void(^)(NSArray *users))completion
{
    Firebase *ref = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:[PULAccount currentUser].uid] childByAppendingPath:endpoint];
    
    // get uids at this point
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *data = snapshot.value;

        if (![data isKindOfClass:[NSNull class]])
        {
            __block NSInteger userCount = data.count;
            __block NSMutableArray *usersToReturn = [[NSMutableArray alloc] initWithCapacity:userCount];
            
            // enumerate over friends uids
            [data enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *uid = key;
                
                // create user and add to array
                [self p_userFromUid:uid completion:^(PULUser *user) {
                    
                    if (user)
                    {
                        // add user to array
                        [usersToReturn addObject:user];
                    }
                    if (--userCount == 0)
                    {
                        // done loading users, call completion
                        completion(usersToReturn);
                    }
                }];
            }];
        }
        else
        {
            completion(nil);
        }
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

- (void)p_forceAddUserAsFriend:(PULUser*)friend completion:(void (^)(PULUser* friend))completion
{
    PULLog(@"Force adding friend: %@", friend);

    [self p_addRelationshipFromMeToYouWithEndpoints:@[@"friends", @"friends"] friend:friend completion:^{
        completion(friend);
    }];
}

- (void)p_addRelationshipFromMeToYouWithEndpoints:(NSArray*)endpoints friend:(PULUser*)friend completion:(void(^)())completion;
{
    NSString *myEndpoint = endpoints[0];
    NSString *friendEndpoint = endpoints[1];
    
    __block NSInteger blockCount = 2;
    void (^friendAddCompletion)(NSError *error, Firebase *ref) = ^(NSError *error, Firebase *ref)
    {
        if (![PULError handleError:error target:_delegate selector:@selector(friendManagerDidEncounterError:) object:error])
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
        if (![PULError handleError:error target:_delegate selector:@selector(friendManagerDidEncounterError:) object:error])
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

@end
