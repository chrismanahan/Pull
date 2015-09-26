//
//  PULLocation.m
//  Pull
//
//  Created by Chris Manahan on 9/23/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULLocation.h"

@implementation PULLocation

@dynamic lat;
@dynamic lon;
@dynamic alt;
@dynamic accuracy;
@dynamic course;
@dynamic speed;
@dynamic movementType;
@dynamic positionType;

- (CLLocation*)location
{
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(self.lat, self.lon)
                                         altitude:self.alt
                               horizontalAccuracy:self.accuracy
                                 verticalAccuracy:0
                                           course:self.course
                                            speed:self.speed
                                        timestamp:self.updatedAt];
}

- (BOOL)isLowAccuracy
{
    return self.accuracy >= kPULDistanceAllowedAccuracy;
}

@end
