//
//  PULAccountOld.h
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULPull.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const PULAccountDidLoginNotification;

@class FBSDKAccessToken;

@interface PULAccount : PULUser

+ (void)loginWithFacebookToken:(FBSDKAccessToken*)accessToken completion:(nullable void(^)(PULAccount *account, NSError *error))completion;

+ (instancetype)initializeCurrentUser:(NSString*)uid;

+ (instancetype)currentUser;

- (void)logout;

// Pulling
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration;
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration caption:(nullable NSString*)caption;
- (void)acceptPull:(PULPull*)pull;
- (void)cancelPull:(PULPull*)pull;
- (void)cancelPullWithUser:(PULUser*)user;

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

- (double)angleWithHeading:(CLHeading*)heading fromUser:(PULUser*)user;

NS_ASSUME_NONNULL_END

@end
