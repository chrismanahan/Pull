//
//  PULCache.h
//  Pull
//
//  Created by Chris M on 10/5/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PULUser;
@class PULPull;

NS_ASSUME_NONNULL_BEGIN

@interface PULCache : NSObject

/*****************************
 Users
 *****************************/
- (void)addUserToCache:(PULUser*)user;
- (void)setUsers:(nullable NSArray<PULUser*>*)users;
- (void)addBlockedUserToCache:(PULUser*)user;
- (void)setBlockedUsers:(nullable NSArray<PULUser*>*)users;

/**
 *  Gets the cached array of friends
 *
 *  @return Array of friends or nil
 */
- (nullable NSArray<PULUser*>*)cachedFriends;
- (nullable NSArray<PULUser*>*)cachedFriendsNotPulled;
- (nullable NSArray<PULUser*>*)cachedFriendsPulled;
/**
 *  Gets the cached array of blocked users
 *
 *  @return Array of blocked users or nil
 */
- (nullable NSArray<PULUser*>*)cachedBlockedUsers;


/*****************************
 Pulls
 *****************************/
- (void)addPullToCache:(PULPull*)pull;
- (void)setPulls:(nullable NSArray<PULPull*>*)pulls;
- (void)removePull:(PULPull*)pull;

- (nullable NSArray<PULPull*>*)cachedPulls;
- (nullable NSArray<PULPull*>*)cachedPullsOrdered;
- (nullable NSArray<PULPull*>*)cachedPullsPending;
- (nullable NSArray<PULPull*>*)cachedPullsWaiting;
- (nullable NSArray<PULPull*>*)cachedPullsNearby;
- (nullable NSArray<PULPull*>*)cachedPullsFar;
- (nullable NSArray<PULPull*>*)cachedPullsPulled;

- (nullable PULPull*)nearestPull;

@end


NS_ASSUME_NONNULL_END