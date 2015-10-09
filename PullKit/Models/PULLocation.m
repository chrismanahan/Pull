//
//  PULLocation.m
//  Pull
//
//  Created by Chris Manahan on 9/23/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULLocation.h"

@implementation PULLocation

@dynamic coordinate;
@dynamic alt;
@dynamic accuracy;
@dynamic course;
@dynamic speed;
@dynamic movementType;
@dynamic positionType;

- (CLLocation*)location
{
    static CLLocation *loc;
    
    if (self.isDataAvailable)
    {
        // if no location yet or the location is stale, initialize again
        if (!loc || ![loc.timestamp isEqualToDate:self.updatedAt])
        {
            loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(self.coordinate.latitude, self.coordinate.longitude)
                                                 altitude:self.alt
                                       horizontalAccuracy:self.accuracy
                                         verticalAccuracy:0
                                                   course:self.course
                                                    speed:self.speed
                                                timestamp:self.updatedAt];
        }
    }
    return loc;
}

- (BOOL)isLowAccuracy
{
    return self.accuracy >= kPULDistanceAllowedAccuracy;
}

- (CGFloat)distanceInMeters:(PULLocation*)location;
{
    CGFloat km = [self.coordinate distanceInKilometersTo:location.coordinate];
    return km * 1000;
}

#pragma mark - Parse subclass
+ (NSString*)parseClassName;
{
    return @"Location";
}

+ (void)load
{
    [self registerSubclass];
    
    [super load];
}

@end
