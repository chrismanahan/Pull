//
//  PULUser.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULPull.h"

#import "PULAccount.h"

@import CoreLocation;

@implementation PULUser

#pragma mark - Fireable Protocol
- (NSString*)rootName
{
    return @"users";
}

- (NSDictionary*)firebaseRepresentation
{
    return @{
             @"fbId": _fbId,
             @"deviceToken": _deviceToken,
             @"email": _email,
             @"firstName": _firstName,
             @"lastName": _lastName,
             @"location": @{
                        @"lat": @(_location.coordinate.latitude),
                        @"lon": @(_location.coordinate.longitude),
                        @"alt": @(_location.altitude)
                     },
             @"friends": [self _friendKeys],
             @"pulls": [self _pullKeys],
             @"blocked": [self _blockedKeys],
             self.settings.rootName: self.settings.firebaseRepresentation
             };
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{    
    if (repr[@"fbId"] && ![_fbId isEqualToString:repr[@"fbId"]])
    {
        self.fbId = repr[@"fbId"];
    }
    if (repr[@"deviceToken"] && ![_deviceToken isEqualToString:repr[@"deviceToken"]])
    {
        self.deviceToken = repr[@"deviceToken"];
    }
    if (repr[@"phoneNumber"] && ![_phoneNumber isEqualToString:repr[@"phoneNumber"]])
    {
        self.phoneNumber = repr[@"phoneNumber"];
    }
    if (repr[@"email"] && ![_email isEqualToString:repr[@"email"]])
    {
        self.email = repr[@"email"];
    }
    if (repr[@"firstName"] && ![_firstName isEqualToString:repr[@"firstName"]])
    {
        self.firstName = repr[@"firstName"];
    }
    if (repr[@"lastName"] && ![_lastName isEqualToString:repr[@"lastName"]])
    {
        self.lastName = repr[@"lastName"];
    }
    
    BOOL isAcct = [self isMemberOfClass:[PULAccount class]];
    
    if (repr[@"friends"])
    {
        NSMutableArray *friends = [[NSMutableArray alloc] init];
        for (NSString *uid in repr[@"friends"])
        {
            PULUser *user;
            if (isAcct)
            {
                user = [[PULUser alloc] initWithUid:uid];
            }
            else
            {
                user = [[PULUser alloc] initEmptyWithUid:uid];
            }
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
    
    if (repr[@"location"])
    {
        double lat = [repr[@"location"][@"lat"] doubleValue];
        double lon = [repr[@"location"][@"lon"] doubleValue];
    //    double alt = [repr[@"location"][@"alt"] doubleValue];
        self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    }
    
    if (repr[@"settings"])
    {
        PULUserSettings *settings = [[PULUserSettings alloc] init];
        [settings loadFromFirebaseRepresentation:repr];
        self.settings = settings;
    }
}

#pragma mark - Private
- (NSArray*)_friendKeys
{
    return [self _keysForFireObjects:self.allFriends];
}

- (NSArray*)_pullKeys
{
    return [self _keysForFireObjects:self.pulls];
}

- (NSArray*)_blockedKeys
{
    return [self _keysForFireObjects:self.blockedUsers];
}

- (NSArray*)_keysForFireObjects:(NSArray*)objects
{
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:objects.count];
    
    for (FireObject *obj in objects)
    {
        [keys addObject:obj.uid];
    }
    
    return (NSArray*)keys;
}

#pragma mark - Properties
- (void)setSettings:(PULUserSettings *)settings
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(settings))];
    _settings = settings;
    [self didChangeValueForKey:NSStringFromSelector(@selector(settings))];
}

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

- (NSArray*)nearbyFriends
{
    return self.allFriends;
}

- (NSArray*)pulledFriends
{
    return [self _friendsWithPullStatus:PULPullStatusPulled];
}

- (NSArray*)pullInvitedFriends
{
    return [self _friendsWithPullStatus:PULPullStatusPending initiateBySelf:YES];
}

- (NSArray*)pullPendingFriends
{
    return [self _friendsWithPullStatus:PULPullStatusPending initiateBySelf:NO];
}

- (NSArray*)blockedUsers
{
    return nil;
}

#pragma mark - Private
- (NSArray*)_friendsWithPullStatus:(PULPullStatus)status
{
    NSMutableArray *friends = [[NSMutableArray alloc] initWithCapacity:_allFriends.count];
    
    for (PULUser *friend in self.allFriends)
    {
        for (PULPull *pull in self.pulls)
        {
            if ([pull containsUser:friend] && pull.status == status)
            {
                [friends addObject:friend];
                break;
            }
        }
    }
    return (NSArray*)friends;
}

- (NSArray*)_friendsWithPullStatus:(PULPullStatus)status initiateBySelf:(BOOL)startedBySelf
{
    NSMutableArray *friends = [[NSMutableArray alloc] initWithCapacity:_allFriends.count];
    
    for (PULUser *friend in self.allFriends)
    {
        for (PULPull *pull in self.pulls)
        {
            if (([pull containsUser:friend] && pull.status == status &&
                ((startedBySelf && [pull initiatedBy:self]) || (!startedBySelf && ![pull initiatedBy:self]))))
            {
                [friends addObject:friend];
                break;
            }
        }
    }
    return (NSArray*)friends;
}

@end
