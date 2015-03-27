//
//  PULFriendManager.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULUserOld.h"

@class PULPullOld;
@class PULFriendManager;

/*****************************************
        Delegate Protocol
 *****************************************/

@protocol PULFriendManagerDelegate <NSObject>

@required
- (void)friendManagerDidReorganize:(PULFriendManager*)friendManager;
- (void)friendManagerDidLoadFriends:(PULFriendManager*)friendManager;
- (void)friendManager:(PULFriendManager*)friendManager didForceAddUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager*)friendManager didSendFriendRequestToUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager*)friendManager didAcceptFriendRequestFromUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager *)friendManager friendRequestWasAcceptedWithUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager *)friendManager didReceiveFriendRequestFromUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager*)friendManager didUnfriendUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager*)friendManager didBlockUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager*)friendManager didUnBlockUser:(PULUserOld*)user;
- (void)friendManager:(PULFriendManager*)friendManager didDetectNewFriend:(PULUserOld*)user;
//- (void)friendManager:(PULFriendManager*)friendManager didDetectFriendChange:(PULUserOld*)user;

- (void)friendManagerDidEncounterError:(NSError*)error;

@end

@interface PULFriendManager : NSObject

/*****************************************
        Properties
 *****************************************/

@property (nonatomic, weak) id <PULFriendManagerDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray *allFriends;
@property (nonatomic, strong, readonly) NSMutableArray *invitedFriends;
@property (nonatomic, strong, readonly) NSMutableArray *pendingFriends;

@property (nonatomic, strong, readonly) NSMutableArray *blockedUsers;

@property (nonatomic, strong, readonly) NSMutableArray *pulledFriends;
@property (nonatomic, strong, readonly) NSMutableArray *pullPendingFriends;
@property (nonatomic, strong, readonly) NSMutableArray *pullInvitedFriends;
@property (nonatomic, strong, readonly) NSMutableArray *nearbyFriends;
@property (nonatomic, strong, readonly) NSMutableArray *farAwayFriends;

/*****************************************
        Instance Methods
 *****************************************/

- (void)initializeFriends;

/**
 *  Gets all friend's from facebook and checks if they exist as a friend in firebase. If we find a new facebook friend that use's pull, we check our userDefaults if we have previously removed this uid generated from the fb id. If we don't find it, we add this user to our friends array locally and on facebook. Also adds us to that friend's friends array remotely
 */
- (void)addFriendsFromFacebook;

- (void)reorganizeWithPulls:(NSArray*)pulls;
- (void)updateOrganizationWithPull:(PULPullOld*)pull;
/**
 *  Updates the organization based on a specific friend. This really only changes things when the user's location changes significantly
 *
 *  @param user User to move
 */
//- (void)updateOrganizationForUser:(PULUserOld*)user;

- (void)sendFriendRequestToUser:(PULUserOld*)user;
- (void)acceptFriendRequestFromUser:(PULUserOld*)user;
- (void)unfriendUser:(PULUserOld*)user;
- (void)blockUser:(PULUserOld*)user;
- (void)unBlockUser:(PULUserOld*)user;

@end
