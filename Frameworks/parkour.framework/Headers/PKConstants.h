//
//  PKConstants.h
//  parkour
//
//  Created by phillip emily yonis anthony and chenyang on 7/21/15b
//  Trademark and Copyright (c) 2015 parkour method. All rights reserved.
//  www.parkourmethod.com
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PKPositionType) {
    Unknown = 0,
    Indoors,
    Outdoors,
    VerifiedIndoors
};

typedef NS_ENUM(NSInteger, PKMotionType) {
    Undefined = 0,
    NotMoving,
    Walking,
    Running,
    Cycling,
    Driving
};

typedef NS_ENUM(NSInteger, PKPositionTrackingMode) {
    Default = 0,
    Geofencing,
    Pedestrian,
    Fitness,
    Automotive
};
