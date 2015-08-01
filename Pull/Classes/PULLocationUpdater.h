//
//  PULLocationUpdater.h
//  Pull
//
//  Created by Chris Manahan on 6/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "LocationShareModel.h"

extern NSString* const PULLocationPermissionsGrantedNotification;
extern NSString* const PULLocationPermissionsDeniedNotification;
extern NSString* const PULLocationHeadingUpdatedNotification;

@class PULLocationUpdater;

/*!
 *  This singleton is responsible for keeping track of the user's location and posting it to the BE
 */
@interface PULLocationUpdater : NSObject <CLLocationManagerDelegate>

/****************************************************
 Properties
 ****************************************************/

@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;

/****************************************************
 Class Methods
 ****************************************************/

+(instancetype)sharedUpdater;
+ (CLLocationManager*)sharedLocationManager;

/****************************************************
 Instance Methods
 ****************************************************/

- (BOOL)hasPermission;

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
///*!
// *  Begins updating the user's location and sending it to the BE when the app is in the background
// */
//-(void)startBackgroundUpdatingLocation;
///*!
// *  Stops background update
// */
//-(void)stopBackgroundUpdatingLocation;

@end
