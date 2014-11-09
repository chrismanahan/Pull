//
//  PULFriendManager.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULUser.h"

@class PULPull;
@class PULFriendManager;

/*****************************************
        Delegate Protocol
 *****************************************/

@protocol PULFriendManagerDelegate <NSObject>

- (void)friendManagerDidReorganize:(PULFriendManager*)pullManager;
- (void)friendManager:(PULFriendManager*)pullManager didSendFriendRequestToUser:(PULUser*)user;
- (void)friendManager:(PULFriendManager*)pullManager didAcceptFriendRequestFromUser:(PULUser*)user;
- (void)friendManager:(PULFriendManager*)pullManager unfriendUser:(PULUser*)user;

@end

@interface PULFriendManager : NSObject

/*****************************************
        Properties
 *****************************************/

@property (nonatomic, weak) id <PULFriendManagerDelegate> delegate;

@property (nonatomic, strong, readonly) NSArray *allFriends;
@property (nonatomic, strong, readonly) NSArray *invitedFriends;
@property (nonatomic, strong, readonly) NSArray *pendingFriends;

@property (nonatomic, strong, readonly) NSArray *pulledFriends;
@property (nonatomic, strong, readonly) NSArray *pullPendingFriends;
@property (nonatomic, strong, readonly) NSArray *pullInvitedFriends;
@property (nonatomic, strong, readonly) NSArray *nearbyFriends;
@property (nonatomic, strong, readonly) NSArray *farAwayFriends;

/*****************************************
        Instance Methods
 *****************************************/

- (void)reorganizeWithPulls:(NSArray*)pulls;
- (void)updateOrganizationWithPull:(PULPull*)pull;

- (void)sendFriendRequestToUser:(PULUser*)user;
- (void)acceptFriendRequestFromUser:(PULUser*)user;
- (void)unfriendUser:(PULUser*)user;

@end
