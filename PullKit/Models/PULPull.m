//
//  PULPull.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPull.h"

#import "PULAccount.h"

#import "PULPush.h"
#import "PULConstants.h"

#import "Amplitude.h"
#import "NSDate+Utilities.h"

#import <UIKit/UIKit.h>

const NSTimeInterval kPullDurationHour    = 3600;
const NSTimeInterval kPullDurationHalfDay = 3600 * 12;
const NSTimeInterval kPullDurationDay     = 3600 * 24;
const NSTimeInterval kPullDurationAlways  = 0;

NSString * const PULPullNearbyNotification = @"PULPullNearbyNotification";
NSString * const PULPullNoLongerNearbyNotification = @"PULPullNoLongerNearbyNotification";

@interface PULPull ()

@property (nonatomic, strong) PULUser *otherUser;

@end

@implementation PULPull

@dynamic sendingUser;
@dynamic receivingUser;
@dynamic duration;
@dynamic expiration;
@dynamic status;
@dynamic together;
@dynamic nearby;

@synthesize otherUser = _otherUser;


#pragma mark - Public
- (void)setDistanceFlags;
{
    BOOL wasNearby = self.nearby;
    BOOL wasTogether = self.together;
    
    self.nearby = [[PULUser currentUser] distanceFromUser:[self otherUser]] <= kPULDistanceNearbyMeters;
    self.together = [[PULUser currentUser] distanceFromUser:[self otherUser]] <= kPULDistanceTogetherMeters;
    
    if (!wasNearby && self.nearby)
    {
        // if we weren't nearby and now we are, notify
        [PULPush sendPushType:PULPushTypeLocalFriendNearby
                           to:[PULUser currentUser]
                         from:[self otherUser]];
    }
    else if (wasNearby && !self.nearby)
    {
        // if we were nearby and no longer are, tell the user
        [PULPush sendPushType:PULPushTypeLocalFriendGone
                           to:[PULUser currentUser]
                         from:[self otherUser]];
    }
    
    if (!wasTogether && self.together)
    {
        [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventPullStateTogether];
    }
}

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
    return [user isEqual:self.sendingUser];
}

- (void)resetExpiration;
{
    if (self.status == PULPullStatusPulled && self.duration == kPullDurationAlways)
    {
        self.expiration = [NSDate dateWithTimeIntervalSince1970:0];
    }
    else if (self.status == PULPullStatusPending && self.duration == kPullDurationAlways)
    {
        self.expiration = [NSDate dateWithTimeIntervalSinceNow:kPullDurationDay];
    }
    else
    {
        self.expiration = [NSDate dateWithTimeIntervalSinceNow:self.duration];
    }
}

- (PULUser*)otherUserThatIsNot:(PULUser*)user
{
    PULUser *other = nil;
    if ([self containsUser:user])
    {
        if ([self initiatedBy:user])
        {
            other = self.receivingUser;
        }
        else
        {
            other = self.sendingUser;
        }
    }
    
    return other;
}

- (PULUser*)otherUser;
{
    if (!_otherUser)
    {
        _otherUser = [self otherUserThatIsNot:[PULUser currentUser]];
    }
    return _otherUser;
}

- (BOOL)isAccurate;
{
    PULUser *otherUser = [self otherUser];
    // if someone's accuracy is low
    BOOL accurate =  (self.sendingUser.location.accuracy < kPULDistanceAllowedAccuracy || self.receivingUser.location.accuracy < kPULDistanceAllowedAccuracy);
    
    // neither user has moved since their last update and they're relatively close
    BOOL closeEnough = self.together || [self _isAlmostHere];
    // TODO: add back in an implemenation of determine if the user hasn't moved since the last update
//    BOOL noMovement = ((!_receivingUser.hasMovedSinceLastLocationUpdate && !_sendingUser.hasMovedSinceLastLocationUpdate) && closeEnough);
    
    
    
    return (accurate || closeEnough) && ![otherUser[@"killed"] boolValue] && ![otherUser[@"noLocation"] boolValue];// || noMovement;
}

#pragma mark - Properties
- (NSInteger)durationHours
{
    return self.duration / 60 / 60;
}

- (NSString*)durationRemaingString
{
    if (self.duration == kPullDurationAlways)
    {
        return @"Always";
    }
    
    NSInteger timeRemaining = [self.expiration timeIntervalSinceNow];
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


// TODO: refeactor these methods to coincide only with pullDistanceState
- (BOOL)_isNearby
{
    PULUser *thisUser = [PULUser currentUser];
    PULUser *otherUser = [self otherUser];
    
    return [thisUser distanceFromUser:otherUser] <= kPULDistanceNearbyMeters &&
    [thisUser distanceFromUser:otherUser] > kPULDistanceAlmostHereMeter;
}

- (BOOL)_isAlmostHere
{
    PULUser *thisUser = [PULUser currentUser];
    PULUser *otherUser = [self otherUser];
    return [thisUser distanceFromUser:otherUser] <= kPULDistanceAlmostHereMeter &&
            [thisUser distanceFromUser:otherUser] > kPULDistanceHereMeters;
}

- (BOOL)_isHere
{
    CGFloat threshold = kPULDistanceHereMeters;
    if (self.together)
    {
        threshold = kPULDistanceHereTogetherMeters;
    }
    
    return [[PULUser currentUser] distanceFromUser:[self otherUser]] <= threshold;
}

- (PULPullDistanceState)pullDistanceState
{
    NSAssert(self.status == PULPullStatusPulled, @"pull must be active to check the distance state");
//    NSAssert(self.receivingUser.location.isDataAvailable, @"receiver location not available");
//    NSAssert(self.sendingUser.location.isDataAvailable, @"sender location not available");

    PULPullDistanceState state;
    if (![self isAccurate])
    {
        state = PULPullDistanceStateInaccurate;
    }
    else if ([self _isHere])
    {
        state = PULPullDistanceStateHere;
    }
    else if ([self _isAlmostHere])
    {
        state = PULPullDistanceStateAlmostHere;
    }
    else if ([self _isNearby])
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
        return [[object sendingUser] isEqual:self.sendingUser] && [[object receivingUser] isEqual:self.receivingUser];
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return self.sendingUser.hash + self.receivingUser.hash;
}


#pragma mark - Parse subclass
+ (NSString*)parseClassName;
{
    return @"Pull";
}

+ (void)load
{
    [self registerSubclass];
}

@end
