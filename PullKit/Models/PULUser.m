//
//  PULUser.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULPull.h"

#import "PULCache.h"

@import UIKit;
@import CoreLocation;

NSString * const PULImageUpdatedNotification = @"PULImageUpdatedNotification";

@interface PULUser ()

@property (nonatomic, strong) NSMutableArray *observers;

@end

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
    if (!_friends)
    {
        BOOL isAcct = [self isMemberOfClass:[PULAccount class]];
        
        _friends = [[FireMutableArray alloc] initForClass:[PULUser class] relatedObject:self path:@"friends"];
        _pulls = [[FireMutableArray alloc] initForClass:[PULPull class] relatedObject:self path:@"pulls"];
        _blocked = [[FireMutableArray alloc] initForClass:[PULUser class] relatedObject:self path:@"blocked"];
        
        _friends.emptyObjects = !isAcct;
        _blocked.emptyObjects = !isAcct;
        
        _observers = [[NSMutableArray alloc] init];
    }
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
//                                  @"alt": @(_location.altitude),
                                  @"currPosType": @(_currentPositionType),
                                  @"currMoveType":@(_currentMotionType),
                                  @"accuracy":@(_locationAccuracy),
                                  @"hasMovedSinceLastUpdate": @(_hasMovedSinceLastLocationUpdate)
                                  },
                          @"friends": [_friends firebaseRepresentation],
                          @"pulls": [_pulls firebaseRepresentation],
                          @"blocked": [_blocked firebaseRepresentation],
                          @"inForeground": @(_inForeground),
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
    if (repr[@"inForeground"])
    {
        _inForeground = [repr[@"inForeground"] boolValue];
    }
    
    // update friends
    NSDictionary *friendsRepr = repr[@"friends"];
    if (![self.friends matchesRepresentation:friendsRepr])
    {
        [self willChangeValueForKey:@"friends"];
        [self.friends loadFromFirebaseRepresentation:friendsRepr];
        [self didChangeValueForKey:@"friends"];
    }
    
    // update pulls
    NSDictionary *pullsRepr = repr[@"pulls"];
    if (![self.pulls matchesRepresentation:pullsRepr])
    {
        [self willChangeValueForKey:@"pulls"];
        [self.pulls loadFromFirebaseRepresentation:pullsRepr];
        [self didChangeValueForKey:@"pulls"];
    }
    
    // update blocked
    NSDictionary *blockedRepr = repr[@"blocked"];
    if (![self.blocked matchesRepresentation:blockedRepr])
    {
        [self willChangeValueForKey:@"blocked"];
        [self.blocked loadFromFirebaseRepresentation:blockedRepr];
        [self didChangeValueForKey:@"blocked"];
    }

    if (repr[@"location"])
    {
        double lat = [repr[@"location"][@"lat"] doubleValue];
        double lon = [repr[@"location"][@"lon"] doubleValue];
        //    double alt = [repr[@"location"][@"alt"] doubleValue];
        
        if (_location.coordinate.latitude != lat || _location.coordinate.longitude != lon)
        {
            [self willChangeValueForKey:@"location"];
            _location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
            _locationAccuracy = [repr[@"location"][@"accuracy"] doubleValue];
            [self didChangeValueForKey:@"location"];
        }
        
        _hasMovedSinceLastLocationUpdate = [repr[@"location"][@"hasMovedSinceLastUpdate"] boolValue];
        _currentMotionType = [repr[@"location"][@"currMoveType"] integerValue];
        _currentPositionType = [repr[@"location"][@"currPosType"] integerValue];
    }
    
    if (repr[@"settings"])
    {
        PULUserSettings *settings = [[PULUserSettings alloc] init];
        [settings loadFromFirebaseRepresentation:repr[@"settings"]];
        self.settings = settings;
    }
    else
    {
        self.settings = [PULUserSettings defaultSettings];
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
                                 @"pullPendingFriends",
                                 @"inForeground"
                                 ]];
    
    return keys;
}

#pragma mark - Properties
- (void)setLocation:(CLLocation * __nonnull)location
{
    _location = location;
    _locationAccuracy = location.horizontalAccuracy;
}

- (NSString*)fullName
{
    return [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
}

- (NSArray*)unpulledFriends
{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.friends.count];
    NSArray *pulledFriends = self.pulledFriends;
    
    for (PULUser *user in self.friends)
    {
        if (![pulledFriends containsObject:user])
        {
            [arr addObject:user];
        }
    }
    
    return arr;
}

- (NSArray*)pulledFriends
{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.friends.count];
    
    for (PULPull *pull in self.pulls)
    {
        PULUser *user = [pull otherUser];
        if (![arr containsObject:user])
        {
            [arr addObject:user];
        }
    }
    
    return (NSArray*)arr;
}

- (NSString*)imageUrlString
{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", self.fbId];
}

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

#pragma mark - Public
- (double)distanceFromUser:(PULUser*)user;
{
    double distance = [user.location distanceFromLocation:self.location];
    return distance;
}

#pragma mark - Overrides
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PULUser class]])
    {
        return [[object fbId] isEqualToString:_fbId];
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return self.fbId.hash;
}

#pragma mark - Parse Subclassing
+ (NSString*)parseClassName
{
    return @"User";
}

+ (void)load
{
    [self registerSubclass];
}

@end
