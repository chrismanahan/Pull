//
//  PULPull.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPull.h"

#import "PULUser.h"

#import "PULConstants.h"

const NSTimeInterval kPullDurationHour    = 3600;
const NSTimeInterval kPullDurationHalfDay = 3600 * 12;
const NSTimeInterval kPullDurationDay     = 3600 * 24;
const NSTimeInterval kPullDurationAlways  = 0;

@interface PULPull ()

@property (nonatomic, strong, readwrite) NSDate *expiration;

@end

@implementation PULPull

#pragma mark - Initialization
- (instancetype)initNewBetween:(PULUser*)sender and:(PULUser*)receiver duration:(NSTimeInterval)duration;
{
    if (self = [super initNew])
    {
        _sendingUser = sender;
        _receivingUser = receiver;
        _duration = duration;
        _status = PULPullStatusPending;
        [self resetExpiration];
    }
    
    return self;
}

#pragma mark - Public
- (BOOL)containsUser:(PULUser*)user;
{
    if ([self.sendingUser isEqual:user] || [self.receivingUser isEqual:user])
    {
        return YES;
    }
    return NO;
}

- (BOOL)initiatedBy:(PULUser*)user;
{
    return [user isEqual:_sendingUser];
}

- (void)resetExpiration;
{
    if (_status == PULPullStatusPulled && _duration == kPullDurationAlways)
    {
        _expiration = [NSDate dateWithTimeIntervalSince1970:0];
    }
    else if (_status == PULPullStatusPending && _duration == kPullDurationAlways)
    {
        _expiration = [NSDate dateWithTimeIntervalSinceNow:kPullDurationDay];
    }
    else
    {
        _expiration = [NSDate dateWithTimeIntervalSinceNow:_duration];
    }
}

- (PULUser*)otherUser:(PULUser*)thisUser;
{
    PULUser *other = nil;
    if ([self containsUser:thisUser])
    {
        if ([self initiatedBy:thisUser])
        {
            other = _receivingUser;
        }
        else
        {
            other = _sendingUser;
        }
    }
    
    return other;
}

#pragma mark - Properties
- (NSInteger)durationHours
{
    return _duration / 60 / 60;
}

#pragma mark - Private
- (void)_observeUsersLocation:(PULUser*)user
{
    static NSMutableDictionary *observers = nil;
    if (!observers)
    {
        observers = [[NSMutableDictionary alloc] init];
    }
    
    if (observers[user.uid] == nil)
    {
        id obs = [THObserver observerForObject:user keyPath:@"location" oldAndNewBlock:^(id oldValue, id newValue) {
            PULUser *otherUser = [self otherUser:user];
            
            if ([user.location distanceFromLocation:otherUser.location] <= kPULNearbyDistance)
            {
                if (!_nearby)
                {
                    [self willChangeValueForKey:@"nearby"];
                    _nearby = YES;
                    [self didChangeValueForKey:@"nearby"];
                }
            }
            else
            {
                if (_nearby)
                {
                    [self willChangeValueForKey:@"nearby"];
                    _nearby = NO;
                    [self didChangeValueForKey:@"nearby"];
                }
            }
        }];
        
        observers[user.uid] = obs;
    }
}

#pragma mark - Fireable Protocol
- (NSString*)rootName
{
    return @"pulls";
}

- (NSDictionary*)firebaseRepresentation
{
    return @{
             @"sendingUser": _sendingUser.uid,
             @"receivingUser": _receivingUser.uid,
             @"expiration": @([_expiration timeIntervalSince1970]),
             @"status": @(_status),
             @"duration": @(_duration),
             @"caption": _caption ?: @""
             };
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    if (repr[@"sendingUser"])
    {
        self.sendingUser = [[PULUser alloc] initWithUid:repr[@"sendingUser"]];
    }
    
    if (repr[@"receivingUser"])
    {
        self.receivingUser = [[PULUser alloc] initWithUid:repr[@"receivingUser"]];
    }
    
    if (repr[@"status"] && [repr[@"status"] integerValue] != self.status)
    {
        self.status = [repr[@"status"] integerValue];
    }
    
    if (repr[@"expiration"] && [repr[@"expiration"] integerValue] != _expiration.timeIntervalSince1970)
    {
        self.expiration = [NSDate dateWithTimeIntervalSince1970:[repr[@"expiration"] integerValue]];
    }
    
    if (repr[@"duration"])
    {
        self.duration = [repr[@"duration"] integerValue];
    }
    
    if (repr[@"caption"])
    {
        self.caption = repr[@"caption"];
    }
    
    [super loadFromFirebaseRepresentation:repr];
}


@end
