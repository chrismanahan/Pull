//
//  parkour.h
//  parkour
//
//  Created by phillip emily yonis anthony and chenyang on 7/21/15b
//  Trademark and Copyright (c) 2015 parkour method. All rights reserved.
//  www.parkourmethod.com

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PKConstants.h"

@interface parkour : NSObject

//
// start the parkour location engine in uber low power consumption mode.
// usage: [parkour start];
+ (void)start;

//
// stop all parkour background and foreground operations. must use [start] to restart parkour. not required unless you wish
// to force parkour to force stop; parkour will naturally go into ultra low power mode while app is in background.
// usage: [parkour stop];
+ (void)stop;

//
// track and receive location updates from parkour
// the frequency and quality of location signals can be established using the setMode command.
// Activating this function will slightly increase battery consumption rate.
// usage:  [parkour trackPositionWithHandler:^(CLLocation *location, PKPositionType positionType, PKMotionType motionType) { ... }
+ (void)trackPositionWithHandler:(void (^)(CLLocation *position, PKPositionType positionType, PKMotionType motionType))handler;

//
// Tune the location output for specific activities. Higher activity modes will
// increase accuracy and slightly increase the battery consumption.
// Higher activity modes increase location accuracy at a nominal increase in battery consumption.
// locationMode settings: 0= default/lowest power; 1= geofencing; 2= pedestrian; 3= fitness/cycling; 4= automotive navigation
// note: trackPosition must be active prior to adjusting the operating mode
// see PKConstansts.h for available PKMode constants
// usage: [parkour setMode:Fitness];
+ (void)setTrackPositionMode:(PKPositionTrackingMode)locationMode;

//
// Set the maximum number of seconds between position updates for the trackPositionWithHandler
// function. A low minimum update rate may return the same position data until the
// the actual device position changes, and will increase the battery consumption rate.
// Zero (0) disables this function.
// usage: [parkour setMinPositionUpdateRate:1800];
+ (void)setMinPositionUpdateRate:(int)seconds;

//
// stop receiving location updates from parkour and return sdk to uber low battery consumption mode.
// usage: [parkour stopTrackPosition];
+ (void)stopTrackPosition;

@end
