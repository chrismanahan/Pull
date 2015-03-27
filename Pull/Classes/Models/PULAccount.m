//
//  PULAccountOld.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULAccount.h"

@implementation PULAccount

#pragma mark - Fireable Protocol

- (NSDictionary*)firebaseRepresentation
{
    return nil;
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    [super loadFromFirebaseRepresentation:repr];
    
    if (repr[@"friends"])
    {
        NSMutableArray *friends = [[NSMutableArray alloc] init];
        for (NSString *uid in repr[@"friends"])
        {
            PULUser *user = [[PULUser alloc] initWithUid:uid];
            [friends addObject:user];
        }
        
        self.allFriends = [[NSArray alloc] initWithArray:friends];
    }
    
    if (repr[@"pulls"])
    {
        NSMutableArray *pulls = [[NSMutableArray alloc] init];
        for (NSString *uid in repr[@"pulls"])
        {
            PULPull *pull = [[PULPull alloc] initWithUid:uid];
            [pulls addObject:pull];
        }
        
        self.pulls = [[NSArray alloc] initWithArray:pulls];
    }
}

#pragma mark - Properties
- (void)setAllFriends:(NSArray *)allFriends
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(allFriends))];
    _allFriends = allFriends;
    [self didChangeValueForKey:NSStringFromSelector(@selector(allFriends))];
}

- (void)setPulls:(NSArray *)pulls
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(pulls))];
    _pulls = pulls;
    [self didChangeValueForKey:NSStringFromSelector(@selector(pulls))];
}

@end
