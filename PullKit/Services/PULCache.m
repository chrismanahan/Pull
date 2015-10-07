//
//  PULCache.m
//  Pull
//
//  Created by Chris M on 10/5/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULCache.h"

#import "PULUser.h"
#import "PULPull.h"

#import <LinqToObjectiveC/NSArray+LinqExtensions.h>

@interface PULCache ()

@property (nonatomic, strong) NSMutableDictionary *cacheStorage;

@end

@implementation NSArray (PullSorting)

- (NSArray*)pull_sortByDistance
{
    return [self linq_sort:^id(PULPull *pull) {
        return @([[PULUser currentUser].location.coordinate distanceInMilesTo:[pull otherUser].location.coordinate]);
    }];
}

@end


@implementation PULCache

#pragma mark - Init
- (instancetype)init
{
    if (self = [super init])
    {
        _cacheStorage = [[NSMutableDictionary alloc] init];
        [_cacheStorage setObject:@[] forKey:@"pulls"];
        [_cacheStorage setObject:@[] forKey:@"friends"];
        [_cacheStorage setObject:@[] forKey:@"blocked"];
    }
    
    return self;
}

#pragma mark - Adding / Setting
#pragma mark Pulls
- (void)addPullToCache:(PULPull*)pull
{
    NSMutableArray *pulls = [_cacheStorage objectForKey:@"pulls"];
    [pulls addObject:pull];
    [self setPulls:pulls];
}

- (void)setPulls:(nullable NSArray<PULPull*>*)pulls;
{
    if (pulls)
    {
        [_cacheStorage setObject:pulls forKey:@"pulls"];
    }
}

- (void)removePull:(PULPull*)pull;
{
    NSMutableArray *pulls = [[self cachedPulls] mutableCopy];
    [pulls removeObject:pull];
    if (pulls)
    {
        [self setPulls:pulls];
    }

}

#pragma mark Users
- (void)addUserToCache:(PULUser*)user
{
    NSMutableArray *users = [_cacheStorage objectForKey:@"friends"];
    [users addObject:user];
    [self setUsers:users];
}

- (void)setUsers:(nullable NSArray<PULUser*>*)users;
{
    if (users)
    {
        [_cacheStorage setObject:users forKey:@"friends"];
    }
}

- (void)addBlockedUserToCache:(PULUser*)user;
{
    NSMutableArray *users = [_cacheStorage objectForKey:@"blocked"];
    [users addObject:user];
    [self setBlockedUsers:users];
}

- (void)setBlockedUsers:(nullable NSArray<PULUser*>*)users;
{
    if (users)
    {
        [_cacheStorage setObject:users forKey:@"blocked"];
    }
}

#pragma mark - Removing

#pragma mark - Getting
#pragma mark Users
- (nullable NSArray<PULUser*>*)cachedFriends
{
    return [[_cacheStorage objectForKey:@"friends"] linq_sort:^id(PULUser *user) {
        return user.firstName;
    }];
}

- (nullable NSArray<PULUser*>*)cachedFriendsNotPulled;
{
    return [[self cachedFriends]
            linq_where:^BOOL(PULUser *user) {
                return ![[self cachedFriendsPulled] containsObject:user];
            }];
}

- (nullable NSArray<PULUser*>*)cachedFriendsPulled
{
    return [[self cachedPulls]
            linq_select:^id(id item) {
                return [item otherUser];
            }];
}

- (nullable NSArray<PULUser*>*)cachedBlockedUsers
{
    return [_cacheStorage objectForKey:@"blocked"];
}

#pragma mark Pulls
- (nullable NSArray<PULPull*>*)cachedPulls
{
    return [_cacheStorage objectForKey:@"pulls"];
}

- (nullable NSArray<PULPull*>*)cachedPullsOrdered
{
    return [[[self cachedPullsPulled]
             linq_concat:[self cachedPullsPending]]
            linq_concat:[self cachedPullsWaiting]];
}

- (nullable NSArray<PULPull*>*)cachedPullsPending
{
    return [[self cachedPulls]
            linq_where:^BOOL(PULPull *pull) {
                return pull.status == PULPullStatusPending && ![pull initiatedBy:[PULUser currentUser]];
            }];
}

- (nullable NSArray<PULPull*>*)cachedPullsWaiting
{
    return [[self cachedPulls]
            linq_where:^BOOL(PULPull *pull) {
                return pull.status == PULPullStatusPending && [pull initiatedBy:[PULUser currentUser]];
            }];
}

- (nullable NSArray<PULPull*>*)cachedPullsNearby
{
    return [[[self cachedPulls]
            linq_where:^BOOL(PULPull *pull) {
                PULUser *friend = [pull otherUser];
                CGFloat distance = [friend.location.location distanceFromLocation:[PULUser currentUser].location.location];
                return pull.status == PULPullStatusPulled && distance <= kPULDistanceNearbyMeters;
            }]
            pull_sortByDistance];
}

- (nullable NSArray<PULPull*>*)cachedPullsFar
{
    return [[[self cachedPulls]
            linq_where:^BOOL(PULPull *pull) {
                PULUser *friend = [pull otherUser];
                CGFloat distance = [friend.location.location distanceFromLocation:[PULUser currentUser].location.location];
                return pull.status == PULPullStatusPulled && distance > kPULDistanceNearbyMeters;
            }]
            pull_sortByDistance];
}

- (nullable NSArray<PULPull*>*)cachedPullsPulled
{
    return [[self cachedPullsNearby]
            linq_concat:[self cachedPullsFar]];
}

- (nullable PULPull*)nearestPull
{
    NSArray *pulls = [self cachedPullsPulled];
    if (pulls && pulls.count > 0)
    {
        return pulls[0];
    }
    
    return nil;
}


@end
