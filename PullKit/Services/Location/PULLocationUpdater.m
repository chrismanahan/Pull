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

@property (nonatomic, strong) NSTimer* locationTrackingUpdateTimer;

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic) PKMotionType currentMotionType;
@property (nonatomic) PKPositionType currentPositionType;
@property (nonatomic) BOOL locationDirty;
@property (nonatomic, strong) NSTimer *locationSaveTimer;

//@property (nonatomic, strong) MMWormhole *wormhole;

@property (nonatomic, strong) PULParseMiddleMan *parse;

@property (nonatomic, assign) NSInteger currentTrackingMode;

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
        
        
        _locationTrackingUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                target:self
                                                              selector:@selector(_updateTrackingInterval)
                                                              userInfo:nil
                                                               repeats:YES];
        
        _locationSaveTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                              target:self
                                                            selector:@selector(_saveCurrentLocation)
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
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
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
    [parkour start];
    [self startUpdatingLocationWithMode:3];
}

- (void)startUpdatingLocationWithMode:(int)mode
{
    PULLog(@"starting location updater");
    _tracking = YES;
    _currentTrackingMode = mode;
    
    [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {
        
        PULLog(@"received location: %@ of type %zd", position, motionType);
        
        [self _updateToLocation:position position:positionType motion:motionType];
        
    }];
    
    [parkour setInterval:mode];
}

- (void)restartUpdatingLocationWithMode:(NSInteger)mode
{
    _currentTrackingMode = mode;
    [parkour setInterval:(int)mode];
//    [self stopUpdatingLocation];
//    [self startUpdatingLocationWithMode:mode];
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
- (void)_updateTrackingInterval
{
    PULUser *acct = [PULUser currentUser];
    // determine which tracking mode to use based on current motion type
    // and state of pulls
    NSInteger updateInterval = kPULLocationTuningIntervalVeryFar;
    BOOL keepTuning = YES;
    BOOL foreground = acct.isInForeground;
    BOOL hasActivePull = NO;
    
    // check if the user has killed the app
    if (acct.killed)
    {
        // return with lowest update
        if (_currentTrackingMode != updateInterval)
        {
            [self restartUpdatingLocationWithMode:updateInterval];
            return;
        }
    }
    
    // check if we're in the foreground or anyone we're pulled with is in the foreground
    for (PULPull *pull in [_parse.cache cachedPulls])
    {
        if (pull.status == PULPullStatusPulled)
        {
            hasActivePull = YES;
            if ([pull otherUser].isInForeground)
            {
                foreground = YES;
            }
        }
    }
    
    // if no one's in the foreground, use low tracking
    if (!hasActivePull)
    {
        updateInterval = kPULLocationTuningIntervalVeryFar;
        keepTuning = NO;
    }
    
    
    // if we have a pull, get setting type for the nearest one
    if (keepTuning)
    {
        PULPull *nearestPull = [_parse.cache nearestPull];
        updateInterval = [self _intervalForPull:nearestPull];
        
        // if no one's in the foreground, don't use close interval
        if (!foreground && updateInterval == kPULLocationTuningIntervalClose)
        {
            updateInterval = kPULLocationTuningIntervalNearby;
        }
    }
    
    // restart location tracking with new mode
    if (updateInterval != _currentTrackingMode)
    {
        PULLog(@"changing tracking mode to %ld", (long)updateInterval);
        [self restartUpdatingLocationWithMode:updateInterval];
    }
}

- (void)_updateToLocation:(CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType
{
    if (location.coordinate.latitude != _currentLocation.coordinate.latitude ||
        location.coordinate.longitude != _currentLocation.coordinate.longitude ||
        positionType != _currentPositionType || motionType != _currentMotionType)
    {
        _locationDirty = YES;
        _currentLocation = location;
        _currentMotionType = motionType;
        _currentPositionType = positionType;
    }
}

- (void)_saveCurrentLocation
{
    if (_locationDirty)
    {
        [self _saveNewLocation:_currentLocation position:_currentPositionType motion:_currentMotionType];
         _locationDirty = NO;
    }
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
        
        if (hasDifferentLoc)
        {
            // check if this really is different
            // if new accuracy is worse than previous accuracy and motion type is still,
            // set that we don't have a differen location
            if (location.horizontalAccuracy > acct.location.accuracy &&
                motionType == pkNotMoving)
            {
                hasDifferentLoc = NO;
            }
        }
    }
    
    if (hasDifferentLoc || location.horizontalAccuracy < acct.location.accuracy || numUpdates++ < 1)
    {
        // save new location if coords are different or if the accuracy has improved
            PULLog(@"\tsaving new location: (%.5f, %.5f)", location.coordinate.latitude, location.coordinate.longitude);
            PULLog(@"\t\tmotion type: %zd", motionType);
            [_parse updateLocation:location
                      movementType:motionType
                      positionType:positionType];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationUpdatedNotification
                                                                object:location];
    }
}

- (NSInteger)_intervalForDistance:(CLLocationDistance)distance
{
    NSInteger interval;
    
    if (distance > kPULLocationTuningDistanceVeryFarMeters)
    {
        interval = kPULLocationTuningIntervalVeryFar;
    }
    else if (distance > kPULLocationTuningDistanceFarMeters)
    {
        interval = kPULLocationTuningIntervalFar;
    }
    else if (distance > kPULLocationTuningDistanceNearbyMeters)
    {
        interval = kPULLocationTuningIntervalNearby;
    }
    else
    {
        interval = kPULLocationTuningIntervalClose;
    }
    
    return interval;
}

- (NSInteger)_intervalForPull:(PULPull*)pull
{
    // distance between us and user of nearest pull
    PULUser *otherUser = [pull otherUser];
    CGFloat distance = [[PULUser currentUser] distanceFromUser:otherUser];
    return [self _intervalForDistance:distance];
    
}

- (void)_requestPermission
{
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_locationManager requestAlwaysAuthorization];
    }
}

@end
