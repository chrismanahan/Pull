//
//  PULUser.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import <objc/runtime.h>

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
             @"phoneNumber": _phoneNumber,
             @"email": _email,
             @"firstName": _firstName,
             @"lastName": _lastName,
             @"location": @{
                        @"lat": _location.coordinate.latitude,
                        @"lon": _location.coordinate.longitude,
                        @"alt": _location.altitude
                     }
             };
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{    
    if (repr[@"fbId"])
    {
        self.fbId = repr[@"fbId"];
    }
    if (repr[@"deviceToken"])
    {
        self.deviceToken = repr[@"deviceToken"];
    }
    if (repr[@"phoneNumber"])
    {
        self.phoneNumber = repr[@"phoneNumber"];
    }
    if (repr[@"email"])
    {
        self.email = repr[@"email"];
    }
    if (repr[@"firstName"])
    {
        self.firstName = repr[@"firstName"];
    }   
    if (repr[@"lastName"])
    {
        self.lastName = repr[@"lastName"];
    }
    
    if (repr[@"location"])
    {
        double lat = [repr[@"location"][@"lat"] doubleValue];
        double lon = [repr[@"location"][@"lon"] doubleValue];
    //    double alt = [repr[@"location"][@"alt"] doubleValue];
        self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    }
    
}

@end
