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

#pragma mark - Initialization
- (instancetype)initWithUid:(NSString *)uid
{
    if (self = [super initWithUid:uid])
    {
        [self initialize];
    }
    
    return self;
}

- (instancetype)initEmptyWithUid:(NSString *)uid
{
    if (self = [super initEmptyWithUid:uid])
    {
        [self initialize];
    }
    
    return self;
}

- (instancetype)initNew
{
    if (self = [super initNew])
    {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    BOOL isAcct = [self isMemberOfClass:[PULAccount class]];
    
    _friends = [[FireMutableArray alloc] initForClass:[PULUser class] relatedObject:self path:@"friends"];
    _pulls = [[FireMutableArray alloc] initForClass:[PULPull class] relatedObject:self path:@"pulls"];
    _blocked = [[FireMutableArray alloc] initForClass:[PULUser class] relatedObject:self path:@"blocked"];
    
    _friends.emptyObjects = !isAcct;
    _blocked.emptyObjects = !isAcct;
}

#pragma mark - Fireable Protocol
- (NSString*)rootName
{
    return @"users";
}

- (NSDictionary*)firebaseRepresentation
{
    NSDictionary *rep = @{
                          @"fbId": _fbId,
                          @"deviceToken": _deviceToken ?:@"",
                          @"email": _email ?:@"",
                          @"firstName": _firstName ?:@"",
                          @"lastName": _lastName ?:@"",
                          @"location": @{
                                  @"lat": @(_location.coordinate.latitude),
                                  @"lon": @(_location.coordinate.longitude),
                                  @"alt": @(_location.altitude)
                                  },
                          @"friends": [_friends firebaseRepresentation],
                          @"pulls": [_pulls firebaseRepresentation],
                          @"blocked": [_blocked firebaseRepresentation],
                          self.settings.rootName: self.settings.firebaseRepresentation
                          };
    
    return rep;
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
    
    if (repr[@"friends"])
    {
        [self willChangeValueForKey:@"friends"];
        [self.friends loadFromFirebaseRepresentation:repr[@"friends"]];
        [self didChangeValueForKey:@"friends"];
    }
    
    if (repr[@"pulls"])
    {
        [self willChangeValueForKey:@"pulls"];
        [self.pulls loadFromFirebaseRepresentation:repr[@"pulls"]];
        [self didChangeValueForKey:@"pulls"];
    }
    
    if (repr[@"blocked"])
    {
        [self willChangeValueForKey:@"blocked"];
        [self.blocked loadFromFirebaseRepresentation:repr[@"blocked"]];
        [self didChangeValueForKey:@"blocked"];
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
    
    [super loadFromFirebaseRepresentation:repr];
}

#pragma mark - Subclass
- (NSArray*)allKeys
{
    NSMutableArray *keys = [[super allKeys] mutableCopy];
    
    [keys removeObjectsInArray:@[@"fullName",
                                 @"image",
                                 @"address",
                                 @"placemark",
                                 @"nearbyFriends",
                                 @"pulledFriends",
                                 @"pullInvitedFriends",
                                 @"pullPendingFriends"
                                 ]];
    
    return keys;
}

#pragma mark - Properties
- (void)setSettings:(PULUserSettings *)settings
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(settings))];
    _settings = settings;
    [self didChangeValueForKey:NSStringFromSelector(@selector(settings))];
}

- (void)setFriends:(FireMutableArray *)friends
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(friends))];
    _friends = friends;
    [self didChangeValueForKey:NSStringFromSelector(@selector(friends))];
}

- (void)setPulls:(FireMutableArray *)pulls
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(pulls))];
    _pulls = pulls;
    [self didChangeValueForKey:NSStringFromSelector(@selector(pulls))];
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



#pragma mark - Private
- (NSArray*)_friendsWithPullStatus:(PULPullStatus)status
{
    NSMutableArray *friends = [[NSMutableArray alloc] initWithCapacity:_friends.count];
    
    for (PULUser *friend in self.friends)
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
    NSMutableArray *friends = [[NSMutableArray alloc] initWithCapacity:_friends.count];
    
    for (PULUser *friend in self.friends)
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
