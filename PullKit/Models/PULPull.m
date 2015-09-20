//
//  PULPull.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPull.h"

#import "PULAccount.h"

#import "PULConstants.h"

#import "NSDate+Utilities.h"

#import "FireSync.h"

#import <UIKit/UIKit.h>

const NSTimeInterval kPullDurationHour    = 3600;
const NSTimeInterval kPullDurationHalfDay = 3600 * 12;
const NSTimeInterval kPullDurationDay     = 3600 * 24;
const NSTimeInterval kPullDurationAlways  = 0;

NSString * const PULPullNearbyNotification = @"UserNearbyNotification";

@interface PULPull ()

@property (nonatomic, strong, readwrite) NSDate *expiration;

@property (nonatomic, strong) NSMutableDictionary *locationObservers;

@property (nonatomic, strong) NSDate *lastNearbyNotification;

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
        
        [self _observeUsersLocation:_sendingUser];
        [self _observeUsersLocation:_receivingUser];
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

- (PULUser*)otherUserThatIsNot:(PULUser*)user
{
    PULUser *other = nil;
    if ([self containsUser:user])
    {
        if ([self initiatedBy:user])
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

- (PULUser*)otherUser;
{
    return [self otherUserThatIsNot:[PULAccount currentUser]];
}

- (BOOL)isAccurate;
{
    
    
    // if someone's accuracy is low
    BOOL accurate =  (_sendingUser.locationAccuracy < kPULDistanceAllowedAccuracy || _receivingUser.locationAccuracy < kPULDistanceAllowedAccuracy);
    
    // neither user has moved since their last update and they're relatively close
    BOOL closeEnough = self.here || self.almostHere;
    BOOL noMovement = ((!_receivingUser.hasMovedSinceLastLocationUpdate && !_sendingUser.hasMovedSinceLastLocationUpdate) && closeEnough);
    
    return accurate || noMovement;
}

#pragma mark - Properties
- (NSInteger)durationHours
{
    return _duration / 60 / 60;
}

- (NSString*)durationRemaingString
{
    if (_duration == kPullDurationAlways)
    {
        return @"Always";
    }
    
    NSInteger timeRemaining = [_expiration timeIntervalSinceNow];
    NSInteger minutes = (timeRemaining / 60) % 60;
    NSInteger hours = (timeRemaining / 3600);

    NSString *retString;
    
    if (hours >= 1)
    {
        retString = [NSString stringWithFormat:@"%zdh %zdm", hours, minutes];
    }
    else
    {
        retString = [NSString stringWithFormat:@"%zdm", minutes];
    }
    
    return retString;
}

- (BOOL)isAlmostHere
{
    return [[PULAccount currentUser] distanceFromUser:[self otherUser]] <= kPULDistanceAlmostHereMeter &&
            [[PULAccount currentUser] distanceFromUser:[self otherUser]] > kPULDistanceHereMeters;
}

- (BOOL)isHere
{
    CGFloat threshold = kPULDistanceHereMeters;
    if (self.together)
    {
        threshold = kPULDistanceHereTogetherMeters;
    }
    
    return [[PULAccount currentUser] distanceFromUser:[self otherUser]] <= threshold;
}

- (PULPullDistanceState)pullDistanceState
{
    NSAssert(_status == PULPullStatusPulled, @"pull must be active to check the distance state");

    PULPullDistanceState state;
    if (_nearby && ![self isAccurate])
    {
        state = PULPullDistanceStateInaccurate;
    }
    else if (self.here)
    {
        state = PULPullDistanceStateHere;
    }
    else if (self.almostHere)
    {
        state = PULPullDistanceStateAlmostHere;
    }
    else if (_nearby)
    {
        state = PULPullDistanceStateNearby;
    }
    else
    {
        state = PULPullDistanceStateFar;
    }
    
    return state;
}

#pragma mark - overrides
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PULPull class]])
    {
        return [[object sendingUser] isEqual:_sendingUser] && [[object receivingUser] isEqual:_receivingUser];
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return _sendingUser.hash + _receivingUser.hash;
}

#pragma mark - Private
- (void)_observeUsersLocation:(PULUser*)user
{
    if (!_locationObservers)
    {
        _locationObservers = [[NSMutableDictionary alloc] init];
    }
    
    if (_locationObservers[user.uid] == nil)
    {
        id obs = [THObserver observerForObject:user keyPath:@"location" oldAndNewBlock:^(id oldValue, id newValue) {
            PULUser *otherUser = [self otherUserThatIsNot:user];
            
            if ([user.location distanceFromLocation:otherUser.location] <= kPULDistanceNearbyMeters)
            {
                if (!_nearby)
                {
                    [self willChangeValueForKey:@"nearby"];
                    _nearby = YES;
                    [self didChangeValueForKey:@"nearby"];
                    
                    // decide to send out a notification
                    BOOL shouldNotify = NO;
                    if (_lastNearbyNotification)
                    {
                        // check if it's been long enough since the last notification
                        NSDate *now = [NSDate dateWithMinutesFromNow:0];
                        NSInteger minutesPassed = [now minutesAfterDate:_lastNearbyNotification];
                        shouldNotify = minutesPassed > kPULPullLocalNotificationDelayMinutes;
                    }
                    else
                    {
                        shouldNotify = YES;
                    }
                    
                    if (shouldNotify)
                    {
                        // check if the user wants to be notified
                        if ([PULAccount currentUser].settings.notifyNearby)
                        {
                            [[NSNotificationCenter defaultCenter] postNotificationName:PULPullNearbyNotification
                                                                                object:self];
                            
                            _lastNearbyNotification = [NSDate dateWithMinutesFromNow:0];
                        }
                    }
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
        
        _locationObservers[user.uid] = obs;
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
             @"caption": _caption ?: @"",
             @"together": @(_together)
             };
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    if (repr[@"sendingUser"])
    {
        self.sendingUser = [[PULUser alloc] initWithUid:repr[@"sendingUser"]];
        [self _observeUsersLocation:self.sendingUser];
    }
    
    if (repr[@"receivingUser"])
    {
        self.receivingUser = [[PULUser alloc] initWithUid:repr[@"receivingUser"]];
        [self _observeUsersLocation:self.receivingUser];
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
    
    if (repr[@"together"])
    {
        self.together = [repr[@"together"] boolValue];
    }
    
    [super loadFromFirebaseRepresentation:repr];
}


@end
