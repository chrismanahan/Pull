//
//  PKConstants.h
//  parkour
//
//  Created by phillip emily yonis anthony and jeremy on 8/21/15
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
    Automotive,
    Share
};
