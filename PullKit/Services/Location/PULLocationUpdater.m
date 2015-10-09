//
//  PULLocationUpdater.m
//  Pull
//
//  Created by Chris Manahan on 6/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULLocationUpdater.h"

#import "PULConstants.h"

#import "PULUser.h"
#import "PULParseMiddleMan.h"

//#import "MMWormHole.h"

#import <CoreLocation/CoreLocation.h>
//#import <LocationKit/LocationKit.h>
#import <parkour/parkour.h>
#import <UIKit/UIKit.h>

NSString* const PULLocationPermissionsGrantedNotification = @"PULLocationPermissionsGrantedNotification";
NSString* const PULLocationPermissionsDeniedNotification = @"PULLocationPermissionsNeededNotification";
NSString* const PULLocationUpdatedNotification = @"PULLocationUpdatedNotification";

@interface PULLocationUpdater ()

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic) NSTimer* locationUpdateTimer;

//@property (nonatomic, strong) MMWormhole *wormhole;

@property (nonatomic, strong) PULParseMiddleMan *parse;

@property (nonatomic, assign) PKPositionTrackingMode currentTrackingMode;

@end

@implementation PULLocationUpdater

#pragma mark - Initialization
+(PULLocationUpdater*)sharedUpdater
{
    static PULLocationUpdater* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared=[[PULLocationUpdater alloc] init];
    });
    return shared;
}

- (id)init
{
    if (self = [super init])
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager startUpdatingHeading];
        
        _parse = [PULParseMiddleMan sharedInstance];
        //        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.pull"
        //                                                         optionalDirectory:@"wormhole"];
        
        
        _locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                target:self
                                                              selector:@selector(_updateTrackingMode)
                                                              userInfo:nil
                                                               repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          [_locationManager stopUpdatingHeading];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          [_locationManager startUpdatingHeading];
                                                      }];
    }
    
    return self;
}

#pragma mark - Public
- (BOOL)hasPermission
{
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ||
    [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
}

- (void)setHeadingUpdateBlock:(PULHeadingBlock)block;
{
    _headingChangeBlock = [block copy];
}

- (void)removeHeadingUpdateBlock;
{
    _headingChangeBlock = nil;
}

- (BOOL)hasHeadingUpdateBlock;
{
    return _headingChangeBlock != nil;
}

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
{
    
    [self startUpdatingLocationWithMode:pkAutomotive];
}

- (void)startUpdatingLocationWithMode:(PKPositionTrackingMode)mode
{
    PULLog(@"starting location updater");
    _tracking = YES;
    _currentTrackingMode = mode;
    
    [parkour start];
//    [parkour setMinPositionUpdateRate:5];
    [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {
        
        PULLog(@"received location: %@ of type %zd", position, motionType);
        
        [self _updateToLocation:position position:positionType motion:motionType];
        
    }];
    
    [parkour setTrackPositionMode:mode];
}

- (void)restartUpdatingLocationWithMode:(PKPositionTrackingMode)mode
{
    [self stopUpdatingLocation];
    [self startUpdatingLocationWithMode:mode];
}

/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
{
    PULLog(@"stopping location updater");
    
    _tracking = NO;
    
    [parkour stopTrackPosition];
//    [parkour stop];
}

#pragma mark - Location Manager delegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways)
    {
        PULLog(@"location permission granted");
        
        if (!_tracking)
        {
            [self startUpdatingLocation];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsGrantedNotification object:self];
    }
    else
    {
        PULLog(@"location access denied");
        
        [self _requestPermission];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsDeniedNotification object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
//    static NSInteger count = 0;
    
    if (_headingChangeBlock)
    {
        _headingChangeBlock(newHeading);
    }
    
//    if (count % 15 == 0)
//    {
//        // get nearest pull
//        PULPull *pull = [_parse.cache nearestPull];
//        
//        if (pull)
//        {
//            // calculate angle
//            double angle = [[PULUser currentUser] angleWithHeading:newHeading
//                                                          fromUser:[pull otherUser]];
//            
//            // check if we have a pull available
//            //            [_wormhole passMessageObject:@{@"angle":@(angle),
//            //                                           @"friendName":[pull otherUser].firstName}
//            //                              identifier:@"com.pull-llc.watch-data"];
//            
//            if (count != 0)
//            {
//                count = 0;
//            }
//        }
//    }
}

#pragma mark - Private
- (void)_updateTrackingMode
{
    PULUser *acct = [PULUser currentUser];
    // determine which tracking mode to use based on current motion type
    // and state of pulls
    PKPositionTrackingMode trackingMode = pkLowEnergy;
    BOOL keepTuning = YES;
    BOOL foreground = acct.isInForeground;
    BOOL hasActivePull = NO;
    BOOL getImmediateUpdate = NO;
    
    // check if we're in the foreground or anyone we're pulled with is in the foreground
    if (keepTuning)
    {
        for (PULPull *pull in [_parse.cache cachedPulls])
        {
            if (pull.status == PULPullStatusPulled)
            {
                hasActivePull = YES;
                if ([pull otherUser].isInForeground)
                {
                    getImmediateUpdate = !acct.isInForeground;
                    foreground = YES;
                }
            }
        }
        
        // if no one's in the foreground, use low tracking
        if (!foreground)
        {
            trackingMode = hasActivePull ? pkGeofencing : pkLowEnergy;
            keepTuning = NO;
        }
    }
    
    // if we have a pull, get setting type for the nearest one
    if (keepTuning && hasActivePull)
    {
        PULPull *nearestPull = [_parse.cache nearestPull];
        trackingMode = [self _settingTypeForPull:nearestPull];
    }
    
    // restart location tracking with new mode
    if (trackingMode != _currentTrackingMode)
    {
        PULLog(@"changing tracking mode to %ld", (long)trackingMode);
        [self restartUpdatingLocationWithMode:trackingMode];
    }
}

- (void)_updateToLocation:(nullable CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType
{
    
    [self _updateTrackingMode];
    
    // save new location
    [self _saveNewLocation:location position:positionType motion:motionType];

}

- (void)_saveNewLocation:(CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType

{
    PULUser *acct = [PULUser currentUser];
    
    if (!acct) { return; } 
    
    BOOL hasDifferentLoc = YES;
    static NSInteger numUpdates = 0;
    
    if (acct.location.isDataAvailable)
    {
        // round each lat lon for comparison
        CGFloat newLat = round(100000 * location.coordinate.latitude) / 100000;
        CGFloat newLon = round(100000 * location.coordinate.longitude) / 100000;
        CGFloat acctLat = round(100000 * acct.location.coordinate.latitude) / 100000;
        CGFloat acctLon = round(100000 * acct.location.coordinate.longitude) / 100000;
        
        hasDifferentLoc = (newLat != acctLat || newLon != acctLon);
    }
    
    if (hasDifferentLoc || location.horizontalAccuracy < acct.location.accuracy || numUpdates++ < 3)
    {
        // save new location if coords are different or if the accuracy has improved
        dispatch_async(dispatch_get_main_queue(), ^{
        
            PULLog(@"\tsaving new location: (%.5f, %.5f)", location.coordinate.latitude, location.coordinate.longitude);
            PULLog(@"\t\tmotion type: %zd", motionType);
            [_parse updateLocation:location
                      movementType:motionType
                      positionType:positionType];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationUpdatedNotification
                                                                object:location];
        });
    }
}

- (PKPositionTrackingMode)_settingTypeForDistance:(CLLocationDistance)distance
{
    PKPositionTrackingMode settingType;
    
    if (distance > kPULLocationTuningDistanceLowMeters)
    {
        settingType = pkGeofencing;
    }
    else if (distance > kPULLocationTuningDistanceAutoMeters)
    {
        settingType = pkPedestrian;
    }
    else if (distance > kPULLocationTuningDistanceMediumMeters)
    {
        settingType = pkFitness;
    }
    else
    {
        settingType = pkAutomotive;
    }
    
    return settingType;
}

- (PKPositionTrackingMode)_settingTypeForPull:(PULPull*)pull
{
    // distance between us and user of nearest pull
    PULUser *otherUser = [pull otherUser];
    CGFloat distance = [[PULUser currentUser] distanceFromUser:otherUser];
    return [self _settingTypeForDistance:distance];
    
}

- (void)_requestPermission
{
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_locationManager requestAlwaysAuthorization];
    }
}

@end
