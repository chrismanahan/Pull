//
//  LocationTracker.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationShareModel.h"

extern NSString* const PULLocationPermissionsGrantedNotification;
extern NSString* const PULLocationPermissionsDeniedNotification;

typedef void(^LocationHeadingBlock)(CLHeading *heading);

@interface LocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;

+ (instancetype)sharedLocationTracker;
+ (CLLocationManager *)sharedLocationManager;

- (BOOL)hasPermission;

- (void)startLocationTracking;
- (void)stopLocationTracking;
- (void)updateLocationToServer;

- (void)registerHeadingChangeBlock:(LocationHeadingBlock)block;
- (void)unregisterHeadingChangeBlock;

@end
