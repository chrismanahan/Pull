//
//  NSArray+Sorting.m
//  Pull
//
//  Created by Chris M on 8/18/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "NSArray+Sorting.h"

#import "PULPull.h"
#import "PULUser.h"

@implementation NSArray (Sorting)

- (NSArray*)sortedPullsByExpiration;
{
    [self _assertClass:[PULPull class]];
    
    return [self sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 expiration] compare:[obj2 expiration]];
    }];
}

- (NSArray*)sortedPullsByDistance;
{
    [self _assertClass:[PULPull class]];
    
    return nil;
}

- (NSArray*)sortedUsersByFirstName;
{
    [self _assertClass:[PULUser class]];
    
    return nil;
}

- (NSArray*)sortedUsersByLastName;
{
    [self _assertClass:[PULUser class]];
    
    return nil;
}

#pragma mark - Private
- (void)_assertClass:(Class)class
{
    if (self.count > 0)
    {
        id obj = self[0];
        NSAssert([obj isKindOfClass:class], @"array needs to have objects of type %@", class);
    }
}

@end
