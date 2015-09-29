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

@property (nonatomic, strong) NSTimer *updateTimer;

@property (nonatomic, strong) PULParseMiddleMan *parse;

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
        // TODO: since we no longer are observing a server for changes, we will have to poll
        //      while in the background to check if a pulled friend is in the foregound.
        
        // TODO: we will also need to update accuracy everytime a pull's status changes or is
        //      added or removed
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager startUpdatingHeading];
        
        _parse = [PULParseMiddleMan sharedInstance];
        //        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.pull"
        //                                                         optionalDirectory:@"wormhole"];
        
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

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
{
    static int tries = 0;
    static BOOL didStart = NO;
    // verify we should be starting location
    if ([self _shouldUpdateLocation])
    {
        PULLog(@"starting location updater");
        _tracking = YES;
        
        [parkour start];
        [parkour setMinPositionUpdateRate:0];
        [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {
            
            PULLog(@"received location: %@ of type %zd : $zd", position, motionType);
            
            [self _updateToLocation:position position:positionType motion:motionType];
            
        }];
        
        [parkour setTrackPositionMode:Fitness];
        
    }
    else
    {
        // try again soon
        if (tries++ < 10)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startUpdatingLocation];
            });
        }
        else
        {
            tries = 0;
        }
    }
}
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
{
    PULLog(@"stopping location updater");
    
    _tracking = NO;
    
    [parkour stopTrackPosition];
    [parkour stop];
    
    //    [_locationManager stopUpdatingLocation];
    
    //    BOOL useLK = [[NSUserDefaults standardUserDefaults] boolForKey:@"LK"];
    //    if (useLK)
    //    {
    //    [[LocationKit sharedInstance] pause];
    //    }
    //    else
    //    {
    //        [parkour stopTrackPosition];
    //        [parkour stop];
    //    }
}

#pragma mark - location kit delegate
//- (void)locationKit:(LocationKit *)locationKit didUpdateLocation:(CLLocation *)location;
//{
//    PULUser *acct = [PULUser currentUser];
//    if (acct.isLoaded)
//    {
//        [self _updateToLocation:location];
//    }
//}
//
//- (void)locationKit:(LocationKit *)locationKit willChangeActivityMode:(LKActivityMode)mode;
//{
//    if ([PULUser currentUser].location.movementType == LKActivityModeStationary && mode != LKActivityModeStationary)
//    {
//        [self _forceUpdateIfNeeded];
//    }
//    
//    [PULUser currentUser].currentMotionType = mode;
//    [[PULUser currentUser] saveKeys:@[@"location"]];
//    
//    [self _updateToLocation:nil];
//}

#pragma mark - Location Manager delegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways)
    {
        PULLog(@"location permission granted");
        
        if ([self _shouldUpdateLocation])
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
    static NSInteger count = 0;
    
    if (_headingChangeBlock)
    {
        _headingChangeBlock(newHeading);
    }
    
    if (count % 15 == 0)
    {
        // get nearest pull
        PULPull *pull = [_parse nearestPull];
        
        if (pull)
        {
            // calculate angle
            double angle = [[PULUser currentUser] angleWithHeading:newHeading
                                                          fromUser:[pull otherUser]];
            
            // check if we have a pull available
            //            [_wormhole passMessageObject:@{@"angle":@(angle),
            //                                           @"friendName":[pull otherUser].firstName}
            //                              identifier:@"com.pull-llc.watch-data"];
            
            if (count != 0)
            {
                count = 0;
            }
        }
    }
}

#pragma mark - Private
//- (void)_startLocationKit
//{
//    NSDictionary *options = @{LKOptionTimedUpdatesInterval: @3,
//                              LKOptionUseiOSMotionActivity: @YES};
//    [[LocationKit sharedInstance] startWithApiToken:@"a4a75fffb77e5f47" delegate:self options:options];
//    [self _updateToLocation:nil];
//
//}

- (NSTimeInterval)_secondsSinceLastUpdate
{
    return fabs([[PULUser currentUser].location.location.timestamp timeIntervalSinceNow]);
}

//- (void)_forceEmptyUpdate
//{
//    [[LocationKit sharedInstance] getCurrentLocationWithHandler:^(CLLocation *location, NSError *error) {
//        ;
//    }];
//}
//
//- (void)_forceUpdate
//{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[LocationKit sharedInstance] getCurrentLocationWithHandler:^(CLLocation *location, NSError *error) {
//            [self _saveNewLocation:location];
//        }];
//    });
//}
//
//- (void)_forceUpdateIfNeeded
//{
//    if ([self _secondsSinceLastUpdate] >= 5 && [PULUser currentUser].currentMotionType != LKActivityModeStationary)
//    {
//        [self _forceUpdate];
//    }
//}
- (void)_updateToLocation:(nullable CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType
{
    PULUser *acct = [PULUser currentUser];
    // determine which tracking mode to use based on current motion type
    // and state of pulls
    PKPositionTrackingMode trackingMode = Geofencing;
    BOOL keepTuning = YES;
    BOOL foreground = acct.isInForeground;
    BOOL hasActivePull = NO;
    BOOL getImmediateUpdate = NO;
    
    // check motion type
    if (acct.location.movementType == Driving)
    {
        trackingMode = Geofencing;
        keepTuning = NO;
    }
    
    // check if we're in the foreground or anyone we're pulled with is in the foreground
    if (keepTuning)
    {
        for (PULPull *pull in [_parse cachedPulls])
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
        
        if (!foreground)
        {
            trackingMode = Geofencing;
            keepTuning = NO;
        }
    }
    
    // if we have a pull, get setting type for the nearest one
    if (keepTuning && hasActivePull)
    {
        PULPull *nearestPull = [_parse nearestPull];
        trackingMode = [self _settingTypeForPull:nearestPull];
    }
    
    [parkour stopTrackPosition];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {
            
            PULLog(@"received location: %@ of type %zd : $zd", position, motionType);
            
//            PULUser *acct = [PULUser currentUser];
//            if (motionType != acct.location.movementType)
//            {
//                //                    [PULUser currentUser].hasMovedSinceLastLocationUpdate = motionType != NotMoving;
//            }
            
            [self _updateToLocation:position position:positionType motion:motionType];
        
        }];
        
        [parkour setTrackPositionMode:trackingMode];
    });
    
//    if (!getImmediateUpdate && foreground)
//    {
//        [self _forceUpdateIfNeeded];
//    }
    
    if (location && [location isKindOfClass:[CLLocation class]])
    {
        [self _saveNewLocation:location position:positionType motion:motionType];
    }
}

- (void)_saveNewLocation:(CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType

{
    PULUser *acct = [PULUser currentUser];
    
    // round each lat lon for comparison
    CGFloat newLat = round(100 * location.coordinate.latitude) / 100;
    CGFloat newLon = round(100 * location.coordinate.longitude) / 100;
    CGFloat acctLat = round(100 * acct.location.location.coordinate.latitude) / 100;
    CGFloat acctLon = round(100 * acct.location.location.coordinate.longitude) / 100;
    
    BOOL hasDifferentLoc = (newLat != acctLat || newLon != acctLon);
    
    if (YES || hasDifferentLoc || location.horizontalAccuracy < acct.location.location.horizontalAccuracy)
    {
        // save new location if coords are different or if the accuracy has improved
        dispatch_async(dispatch_get_main_queue(), ^{
            
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
        settingType = Geofencing;
    }
    else if (distance > kPULLocationTuningDistanceAutoMeters)
    {
        settingType = Pedestrian;
    }
    else if (distance > kPULLocationTuningDistanceMediumMeters)
    {
        settingType = Fitness;
    }
    else
    {
        settingType = Share;
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

- (NSInteger)_secondsBetween:(CLLocation*)location0 andLocation:(CLLocation*)location1;
{
    return fabs([location1.timestamp timeIntervalSinceDate:location0.timestamp]);
}

- (void)_requestPermission
{
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_locationManager requestAlwaysAuthorization];
    }
}

- (BOOL)_shouldUpdateLocation
{
    return YES;
    //    BOOL shouldUpdate = ([[PULUser currentUser] pullsPulledNearby].count > 0 || [[PULUser currentUser] pullsPulledFar].count > 0) && !_tracking;
    //
    //    //    BOOL useLK = [[NSUserDefaults standardUserDefaults] boolForKey:@"LK"];
    //    //    if (useLK)
    //    //    {
    //    //        shouldUpdate = shouldUpdate && [PULUser currentUser].currentMotionType != LKActivityModeAutomotive;
    //    //    }
    //    return shouldUpdate;
}


@end
