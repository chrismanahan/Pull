//
//  PULPull.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPull.h"

#import "PULUser.h"

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

#pragma mark - Public
- (NSInteger)durationHours
{
    return _duration / 60 / 60;
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
             @"duration": @(_duration)
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
    
    [super loadFromFirebaseRepresentation:repr];
}


@end
