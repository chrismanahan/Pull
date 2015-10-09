//
//  PULUser.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULPull.h"
#import "PULUserSettings.h"

@implementation PULUser

@dynamic fbId;
@dynamic email;
@dynamic firstName;
@dynamic lastName;
@dynamic gender;
@dynamic username;
@dynamic isInForeground;
@dynamic isDisabled;
@dynamic isOnline;
@dynamic location;
@dynamic userSettings;
@dynamic lowBattery;
@dynamic killed;
@dynamic noLocation;


+ (instancetype)currentUser
{
    PFUser *user = [PFUser currentUser];
    return (PULUser*)user;
}

#pragma mark - Properties
- (NSString*)fullName
{
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

- (NSString*)imageUrlString
{
    return [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", self.fbId];
}

#pragma mark - Public
- (double)distanceFromUser:(PULUser*)user;
{
    return [self.location distanceInMeters:user.location];
}

- (double)angleWithHeading:(CLHeading*)heading fromUser:(PULUser*)user;
{
    double degrees = [self _calculateAngleBetween:self.location.coordinate
                                              and:user.location.coordinate];
    
    double rads = (degrees - heading.trueHeading) * M_PI / 180;
    
    return rads;
}


#pragma mark - Overrides
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PULUser class]])
    {
        return [[object username] isEqualToString:self.username];
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return self.username.hash;
}

+ (void)load
{
    [self registerSubclass];
}

#pragma mark - Private
- (double)_calculateAngleBetween:(PFGeoPoint*)coords0 and:(PFGeoPoint*)coords1
{
    double myLat = coords0.latitude;
    double myLon = coords0.longitude;
    double yourLat = coords1.latitude;
    double yourLon = coords1.longitude;
    double dx = fabs(myLon - yourLon);
    double dy = fabs(myLat - yourLat);
    
    double ø;
    
    // determine which quadrant we're in relative to other user
    if (dy < 0.000001 && myLon > yourLon) // horizontal right
    {
        return 270;
    }
    else if (dy < 0.000001 && myLon < yourLon) // horizontal left
    {
        return 90;
    }
    else if (dx < 0.000001 && myLat > yourLat) // vertical top
    {
        return 180;
    }
    else if (dx < 0.000001 && myLat < yourLat) // vertical bottom
    {
        return 0;
    }
    else if (myLat > yourLat && myLon > yourLon) // quadrant 1
    {
        ø = atan2(dy, dx);
        return 270 - RADIANS_TO_DEGREES(ø);
    }
    else if (myLat < yourLat && myLon > yourLon) // quad 2
    {
        ø = atan2(dx, dy);
        return 360 - RADIANS_TO_DEGREES(ø);
    }
    else if (myLat < yourLat && myLon < yourLon) // quad 3
    {
        ø = atan2(dx, dy);
    }
    else if (myLat > yourLat && myLon < yourLon) // quad 4
    {
        ø = atan2(dy, dx);
        return 90 + RADIANS_TO_DEGREES(ø);
    }
    return RADIANS_TO_DEGREES( ø);
}


@end
