//
//  PULAccountOld.h
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULPull.h"

extern NSString * const PULAccountDidLoginNotification;

@interface PULAccount : PULUser

+ (void)loginWithFacebookToken:(NSString*)accessToken completion:(void(^)(PULAccount *account, NSError *error))completion;

+ (instancetype)initializeCurrentUser:(NSString*)uid;

+ (instancetype)currentUser;

- (void)logout;

// Pulling
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration;
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration caption:(NSString*)caption;
- (void)acceptPull:(PULPull*)pull;
- (void)cancelPull:(PULPull*)pull;

// User management
- (void)blockUser:(PULUser*)user;
- (void)unblockUser:(PULUser*)user;
- (void)addUser:(PULUser*)user;
- (void)addNewFriendsFromFacebook;

// helpers
- (NSArray*)pullsPending;
- (NSArray*)pullsWaiting;
- (NSArray*)pullsPulledNearby;
- (NSArray*)pullsPulledFar;

@end
