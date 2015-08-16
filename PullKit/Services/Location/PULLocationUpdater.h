//
//  PULLocationUpdater.h
//  Pull
//
//  Created by Chris Manahan on 6/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString* const PULLocationPermissionsGrantedNotification;
extern NSString* const PULLocationPermissionsDeniedNotification;

typedef void(^PULHeadingBlock)(CLHeading *heading);

/*!
 *  This singleton is responsible for keeping track of the user's location and posting it to the BE
 */
@interface PULLocationUpdater : NSObject <CLLocationManagerDelegate>

/****************************************************
 Properties
 ****************************************************/

@property (nonatomic, assign, getter=isTracking) BOOL tracking;

@property (nonatomic, copy) PULHeadingBlock headingChangeBlock;

/****************************************************
 Class Methods
 ****************************************************/

+(instancetype)sharedUpdater;

/****************************************************
 Instance Methods
 ****************************************************/

- (void)startUpdatingHeadingWithBlock:(PULHeadingBlock)block;
- (void)stopUpdatingHeading;

- (BOOL)hasPermission;

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;

@end
