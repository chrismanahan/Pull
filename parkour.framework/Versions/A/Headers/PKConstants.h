//
//  PKConstants.h
//  parkour
//
//  Created by phillip on 10/2/15.
//  Copyright © 2015 phillip. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AdSupport/ASIdentifierManager.h>

#define aSDKVersion 2042



typedef NS_ENUM(NSInteger, PKPositionType) {
    pkIndoors = 0,
    pkOutdoors,
    pkVerifiedIndoors
};

typedef NS_ENUM(NSInteger, PKMotionType) {
    pkNotMoving = 0,
    pkWalking,
    pkRunning,
    pkCycling,
    pkDriving,
    pkFlying
};

typedef NS_ENUM(NSInteger, PKPositionTrackingMode) {
    pkLowEnergy = 0,
    pkGeofencing,
    pkPedestrian,
    pkFitness,
    pkAutomotive,
    pkShare
};

