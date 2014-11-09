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
extern NSString* const PULLocationPermissionsNeededNotification;

@class PULLocationUpdater;

@protocol PULLocationUpdaterDelegate <NSObject>

- (void)locationUpdater:(PULLocationUpdater*)updater didUpdateLocation:(CLLocation*)location;

@end

/*!
 *  This singleton is responsible for keeping track of the user's location and posting it to the BE
 */
@interface PULLocationUpdater : NSObject <CLLocationManagerDelegate>

+(PULLocationUpdater*)sharedUpdater;

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
/*!
 *  Begins updating the user's location and sending it to the BE when the app is in the background
 */
-(void)startBackgroundUpdatingLocation;
/*!
 *  Stops background update
 */
-(void)stopBackgroundUpdatingLocation;

@end
