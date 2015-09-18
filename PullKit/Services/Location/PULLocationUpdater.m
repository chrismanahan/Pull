//
//  PULLocationUpdater.m
//  Pull
//
//  Created by Chris Manahan on 6/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULLocationUpdater.h"

#import "PULConstants.h"

#import "PULAccount.h"

//#import "MMWormHole.h"

#import "BackgroundTaskManager.h"

#import <CoreLocation/CoreLocation.h>
//#import <LocationKit/LocationKit.h>
//#import <parkour/parkour.h>
#import <UIKit/UIKit.h>

NSString* const PULLocationPermissionsGrantedNotification = @"PULLocationPermissionsGrantedNotification";
NSString* const PULLocationPermissionsDeniedNotification = @"PULLocationPermissionsNeededNotification";
NSString* const PULLocationUpdatedNotification = @"PULLocationUpdatedNotification";

@interface PULLocationUpdater () /*<LocationKitDelegate>*/

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic) NSTimer* locationUpdateTimer;

//@property (nonatomic, strong) MMWormhole *wormhole;

@property (nonatomic, strong) NSTimer *updateTimer;

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
        [[NSNotificationCenter defaultCenter] addObserverForName:FireArrayObjectAddedNotification
                                                          object:[PULAccount currentUser].pulls
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [self _updateToLocation:nil];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:FireArrayObjectRemovedNotification
                                                          object:[PULAccount currentUser].pulls
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [self _updateToLocation:nil];
                                                      }];
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager startUpdatingHeading];
        
        //        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.pull"
        //                                                         optionalDirectory:@"wormhole"];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [[BackgroundTaskManager sharedBackgroundTaskManager] beginNewBackgroundTask];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [[BackgroundTaskManager sharedBackgroundTaskManager] endAllBackgroundTasks];
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
        
        _locationManager.distanceFilter = 1.0;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [_locationManager startUpdatingLocation];
        
        //        BOOL useLK = [[NSUserDefaults standardUserDefaults] boolForKey:@"LK"];
        //        if (useLK)
        //        {
        //
        //            if (!didStart)
        //            {
        //                NSDictionary *options = @{LKOptionTimedUpdatesInterval: @3,
        //                                          LKOptionUseiOSMotionActivity: @YES};
        //                [[LocationKit sharedInstance] startWithApiToken:@"a4a75fffb77e5f47" delegate:self options:options];
        //                [self _updateToLocation:nil];
        //
        //                didStart = YES;
        //            }
        //            else
        //            {
        //                [[LocationKit sharedInstance] resume];
        //            }
        //        }
        //        else
        //        {
        //            [parkour start];
        //            [parkour setMinPositionUpdateRate:3];
        //            [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {
        //
        //                PULLog(@"received location: %@ of type %zd : $zd", position, motionType);
        //
        //                PULAccount *acct = [PULAccount currentUser];
        //                if (acct.isLoaded)
        //                {
        //                    acct.currentMotionType = motionType;
        //                    acct.location = position;
        //                    acct.currentPositionType = positionType;
        //                    [acct saveKeys:@[@"location"]];
        //
        //                    [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationUpdatedNotification
        //                                                                        object:position];
        //                }
        //
        //            }];
        //
        //            [parkour setTrackPositionMode:Fitness];
        //        }
        
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                         target:self
                                       selector:@selector(_updateToLocation:)
                                       userInfo:nil
                                        repeats:YES];
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
    
    [_locationManager stopUpdatingLocation];
    [_updateTimer invalidate];
    _updateTimer = nil;
    
    //    BOOL useLK = [[NSUserDefaults standardUserDefaults] boolForKey:@"LK"];
    //    if (useLK)
    //    {
    //        [[LocationKit sharedInstance] pause];
    //    }
    //    else
    //    {
    //        [parkour stopTrackPosition];
    //        [parkour stop];
    //    }
}

//#pragma mark - location kit delegate
//- (void)locationKit:(LocationKit *)locationKit didUpdateLocation:(CLLocation *)location;
//{
//    PULAccount *acct = [PULAccount currentUser];
//    if (acct.isLoaded)
//    {
//        [self _updateToLocation:location];
//    }
//}
//
//- (void)locationKit:(LocationKit *)locationKit willChangeActivityMode:(LKActivityMode)mode;
//{
//    [PULAccount currentUser].currentMotionType = mode;
//    
//    [self _updateToLocation:nil];
//}

#pragma mark - core location delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations
{
    CLLocation *loc = locations[locations.count-1];
    
    [self _updateToLocation:loc];
}

- (void)_updateToLocation:(nullable CLLocation*)location;
{
    //    BOOL useLK = [[NSUserDefaults standardUserDefaults] boolForKey:@"LK"];
    PULAccount *acct = [PULAccount currentUser];
    //    if (useLK)
    //    {
    // determine which tracking mode to use based on current motion type
    // and state of pulls
    //        LKSettingType settingType = LKSettingTypeLow;
    BOOL keepTuning = YES;
    BOOL foreground = acct.isInForeground;
    BOOL hasActivePull = NO;
    BOOL getImmediateUpdate = NO;
    CGFloat distanceFilter = 1.0;
    CLLocationAccuracy desiredAccuracy = kCLLocationAccuracyBest;
    
    
    // check motion type
//    if (acct.currentMotionType == LKActivityModeAutomotive)
//    {
//        settingType = LKSettingTypeLow;
//        keepTuning = NO;
//    }
    
    // check if we're in the foreground or anyone we're pulled with is in the foreground
    if (keepTuning)
    {
        for (PULPull *pull in acct.pulls)
        {
            if (pull.status == PULPullStatusPulled)
            {
                hasActivePull = YES;
                if ([pull otherUser].isInForeground)
                {
                    foreground = YES;
                    getImmediateUpdate = YES;
                }
            }
        }
        
        if (!foreground)
        {
            distanceFilter = 50;
            desiredAccuracy = kCLLocationAccuracyThreeKilometers;
            keepTuning = NO;
        }
    }
    
    // find nearest pull that's active
    if (keepTuning && hasActivePull)
    {
        PULPull *nearestPull = [acct nearestPull];
        // distance between us and user of nearest pull
        PULUser *otherUser = [nearestPull otherUser];
        
        CGFloat distance = [acct distanceFromUser:otherUser];
        
        if (distance > kPULLocationTuningDistanceLowMeters)
        {
//            settingType = LKSettingTypeLow;
            distanceFilter = 20;
            desiredAccuracy = kCLLocationAccuracyKilometer;
        }
        else if (distance > kPULLocationTuningDistanceAutoMeters)
        {
//            settingType = LKSettingTypeAuto;
            distanceFilter =
            desiredAccuracy = kCLLocationAccuracyHundredMeters;
        }
        else if (distance > kPULLocationTuningDistanceMediumMeters)
        {
            distanceFilter = 2;
            desiredAccuracy = kCLLocationAccuracyBest;
        }
        else
        {
            distanceFilter = 1;
            desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        }
    }
    
//    LKSetting *setting = [[LKSetting alloc] initWithType:settingType];
//    if (settingType == LKSettingTypeHigh)
//    {
//        setting.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
//        setting.distanceFilter = 1.0;
//    }
//    [[LocationKit sharedInstance] applyOperationMode:setting];
    //    }
    
    if (_locationManager.desiredAccuracy != desiredAccuracy)
    {
        _locationManager.desiredAccuracy = desiredAccuracy;
    }
    if (_locationManager.distanceFilter != distanceFilter)
    {
        distanceFilter = distanceFilter;
    }
    
    if (getImmediateUpdate)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_locationManager stopUpdatingLocation];
            [_locationManager startUpdatingLocation];
        });
    }
    
    if (location && [location isKindOfClass:[CLLocation class]])
    {
        // we gotta check if this is a good reading
        NSInteger secondsSinceLastUpdate = [self _secondsBetween:acct.location andLocation:location];
        CLLocationAccuracy newAccuracy = location.horizontalAccuracy;
        
        if (!(secondsSinceLastUpdate < 5 && newAccuracy > 15))
        {
        
    //        if (useLK)
    //        {
                acct.location = location;
            
                [acct saveKeys:@[@"location"]];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationUpdatedNotification
                                                                    object:location];
                
    //            tries = 0;
    //        }
        }
    }
    
}

- (NSInteger)_secondsBetween:(CLLocation*)location0 andLocation:(CLLocation*)location1;
{
    return fabs([location1.timestamp timeIntervalSinceDate:location0.timestamp]);
}

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
        PULPull *pull = [[PULAccount currentUser] nearestPull];
        
        if (pull)
        {
            // calculate angle
            double angle = [[PULAccount currentUser] angleWithHeading:newHeading
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

- (void)_requestPermission
{
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_locationManager requestAlwaysAuthorization];
    }
}

- (BOOL)_shouldUpdateLocation
{
    BOOL shouldUpdate = ([[PULAccount currentUser] pullsPulledNearby].count > 0 || [[PULAccount currentUser] pullsPulledFar].count > 0) && !_tracking;
    
//    BOOL useLK = [[NSUserDefaults standardUserDefaults] boolForKey:@"LK"];
//    if (useLK)
//    {
//        shouldUpdate = shouldUpdate && [PULAccount currentUser].currentMotionType != LKActivityModeAutomotive;
//    }
    return shouldUpdate;
}


@end
