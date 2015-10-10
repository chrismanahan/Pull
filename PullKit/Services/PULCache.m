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

@property (nonatomic, strong) NSMutableDictionary *sortedPulls;


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
        [_cacheStorage setObject:[@[] mutableCopy] forKey:@"pulls"];
        [_cacheStorage setObject:[@[] mutableCopy] forKey:@"friends"];
        [_cacheStorage setObject:[@[] mutableCopy] forKey:@"blocked"];
        
        _sortedPulls = [[NSMutableDictionary alloc] init];
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
    // clear out sorted pulls
    [self resetPullSorting];
    
    if (pulls)
    {
        [_cacheStorage setObject:[pulls mutableCopy] forKey:@"pulls"];
    }
    else
    {
        [_cacheStorage removeObjectForKey:@"pulls"];
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
- (void)addFriendToCache:(PULUser*)user
{
    NSMutableArray *users = [_cacheStorage objectForKey:@"friends"];
    [users addObject:user];
    [self setFriends:users];
}

- (void)setFriends:(nullable NSArray<PULUser*>*)users;
{
    if (users)
    {
        [_cacheStorage setObject:[users mutableCopy] forKey:@"friends"];
    }
}

- (void)removeFriend:(PULUser*)user;
{
    NSMutableArray *users = [_cacheStorage objectForKey:@"friends"];
    [users removeObject:user];
    [self setFriends:users];

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
        [_cacheStorage setObject:[users mutableCopy] forKey:@"blocked"];
    }
}

- (void)removeBlockedUser:(PULUser*)user;
{
    NSMutableArray *users = [_cacheStorage objectForKey:@"blocked"];
    [users removeObject:user];
    [self setBlockedUsers:users];
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
- (void)resetPullSorting;
{
    [_sortedPulls removeAllObjects];
}

- (nullable NSArray<PULPull*>*)cachedPulls
{
    return [_cacheStorage objectForKey:@"pulls"];
}

- (nullable NSArray<PULPull*>*)_sortedPullsForKey:(NSString*)key sortingBlock:(NSArray*(^)())sortBlock
{
    if (_sortedPulls[key] == nil)
    {
        _sortedPulls[key] = sortBlock();
    }
    
    return _sortedPulls[key];
}

- (nullable NSArray<PULPull*>*)cachedPullsOrdered
{
    return [self _sortedPullsForKey:@"ordered"
                       sortingBlock:^NSArray *{
                           return [[[self cachedPullsPulled]
                                    linq_concat:[self cachedPullsPending]]
                                   linq_concat:[self cachedPullsWaiting]];
                       }];
}

- (nullable NSArray<PULPull*>*)cachedPullsPending
{
    return [self _sortedPullsForKey:@"pending"
                       sortingBlock:^NSArray *{
                           return [[self cachedPulls]
                                   linq_where:^BOOL(PULPull *pull) {
                                       return pull.status == PULPullStatusPending && ![pull initiatedBy:[PULUser currentUser]];
                                   }];
                       }];
}

- (nullable NSArray<PULPull*>*)cachedPullsWaiting
{
    return [self _sortedPullsForKey:@"waiting"
                       sortingBlock:^NSArray *{
                           return [[self cachedPulls]
                                   linq_where:^BOOL(PULPull *pull) {
                                       return pull.status == PULPullStatusPending && [pull initiatedBy:[PULUser currentUser]];
                                   }];
                       }];
}

- (nullable NSArray<PULPull*>*)cachedPullsNearby
{
    return [self _sortedPullsForKey:@"nearby" sortingBlock:^NSArray *{
        return [[[self cachedPulls]
                 linq_where:^BOOL(PULPull *pull) {
                     PULUser *friend = [pull otherUser];
                     CGFloat distance = [friend.location distanceInMeters:[PULUser currentUser].location];
                     return pull.status == PULPullStatusPulled && distance <= kPULDistanceNearbyMeters;
                 }]
                pull_sortByDistance];
    }];
}

- (nullable NSArray<PULPull*>*)cachedPullsFar
{
    return [self _sortedPullsForKey:@"far"
                       sortingBlock:^NSArray *{
                           return [[[self cachedPulls]
                                    linq_where:^BOOL(PULPull *pull) {
                                        PULUser *friend = [pull otherUser];
                                        CGFloat distance = [friend.location distanceInMeters:[PULUser currentUser].location];
                                        return pull.status == PULPullStatusPulled && distance > kPULDistanceNearbyMeters;
                                    }]
                                   pull_sortByDistance];
                       }];
}

- (nullable NSArray<PULPull*>*)cachedPullsPulled
{
    return [self _sortedPullsForKey:@"pulled"
                       sortingBlock:^NSArray *{
                           return [[self cachedPullsNearby]
                                   linq_concat:[self cachedPullsFar]];

                       }];
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
