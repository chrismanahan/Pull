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
@property (nonatomic, strong) NSTimer* parkourPingTimer;

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic) PKMotionType currentMotionType;
@property (nonatomic) PKPositionType currentPositionType;
@property (nonatomic, strong) NSTimer *locationSaveTimer;

@property (nonatomic) CLLocationDistance currentDistanceFilter;
@property (nonatomic) CLLocationAccuracy currentDesiredAccuracy;
@property (nonatomic) BOOL isUsingAuxLocationManager;

@property (nonatomic, strong) NSMutableArray *locationBuffer;

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
        _locationBuffer = [[NSMutableArray alloc] init];
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager startUpdatingHeading];
        
        _currentDistanceFilter = 20;
        _currentDesiredAccuracy = kCLLocationAccuracyBest;
        
        _parse = [PULParseMiddleMan sharedInstance];
        //        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.pull"
        //                                                         optionalDirectory:@"wormhole"];
        
        
        _locationTrackingUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                target:self
                                                              selector:@selector(_updateTrackingInterval)
                                                              userInfo:nil
                                                               repeats:YES];
        
//        _parkourPingTimer = [NSTimer scheduledTimerWithTimeInterval:120
//                                         target:self
//                                       selector:@selector(pingParkour)
//                                       userInfo:nil
//                                        repeats:YES];
        
        _locationSaveTimer = [NSTimer scheduledTimerWithTimeInterval:6
                                                              target:self
                                                            selector:@selector(_saveCurrentLocation)
                                                            userInfo:nil
                                                             repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          [_locationManager stopUpdatingHeading];
                                                          [self _startAuxLocationManager];
                                                          
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          [_locationManager startUpdatingHeading];
                                                          [self _stopAuxLocationManager];
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
    [self startUpdatingLocationWithMode:1];
}

- (void)startUpdatingLocationWithMode:(NSInteger)mode
{
    PULLog(@"starting location updater");
    _tracking = YES;
    _currentTrackingMode = mode;
    
    [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {
        
        PULLog(@"received location: %@ of type %zd", position, motionType);
        
        [self _updateToLocation:position position:positionType motion:motionType];
        
    }];
    
    [parkour setInterval:(int)mode];
}

- (void)pingParkour
{
    NSInteger interval = _currentTrackingMode;
    [self restartUpdatingLocationWithMode:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self restartUpdatingLocationWithMode:interval];
    });
}

- (void)restartUpdatingLocationWithMode:(NSInteger)mode
{
    PULLog(@"changing tracking mode to %ld", (long)mode);
    _currentTrackingMode = mode;
    [parkour setInterval:(int)mode];
    
    if (mode == kPULLocationTuningIntervalVeryFar)
    {
        _currentDesiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _currentDistanceFilter = 50;
    }
    else if (mode == kPULLocationTuningIntervalFar)
    {
        _currentDesiredAccuracy = kCLLocationAccuracyKilometer;
        _currentDistanceFilter = 30;
    }
    else if (mode == kPULLocationTuningIntervalNearby)
    {
        _currentDesiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _currentDistanceFilter = 10;
    }
    else if (mode == kPULLocationTuningIntervalClose)
    {
        _currentDesiredAccuracy = 5;
        _currentDistanceFilter = 3;
    }
    
    
    if (_isUsingAuxLocationManager)
    {
        PULLog(@"updating aux loc manager");
        _locationManager.desiredAccuracy = _currentDesiredAccuracy;
        _locationManager.distanceFilter = _currentDistanceFilter;
    }
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

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    @try {
        if ([PULUser currentUser].killed)
        {
            [_locationManager stopUpdatingLocation];
            return;
        }
    }
    @catch (NSException *exception) {
        ;
    }
    
    CLLocation *loc = locations[locations.count-1];
    [self _updateToLocation:loc position:-1 motion:-1];
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
    
    // check if we have to kill the aux loc manager
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && _isUsingAuxLocationManager)
    {
        [self _stopAuxLocationManager];
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
        
        // if no one's in the foreground,
        // or this device is not moving with a good accuracy reading, don't use close interval
        if ((!foreground || (_currentMotionType == pkNotMoving && acct.location.accuracy <= 10)) &&
            updateInterval == kPULLocationTuningIntervalClose)
        {
            updateInterval = kPULLocationTuningIntervalNearby;
        }
    }
    
    // restart location tracking with new mode
    if (updateInterval != _currentTrackingMode)
    {
        [self restartUpdatingLocationWithMode:updateInterval];
    }
}

- (void)_updateToLocation:(CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType
{
    [self _runBlockInBackground:^{
        PULUser *acct = [PULUser currentUser];
        BOOL hasPosMotionData = positionType != -1 && motionType != -1;
        BOOL hasDifferentLoc = YES;
        BOOL worseAccuracy = location.horizontalAccuracy > _currentLocation.horizontalAccuracy;
        BOOL improvedAccuracy = !worseAccuracy && location.horizontalAccuracy != _currentLocation.horizontalAccuracy;
        BOOL acceptableAccuracy = location.horizontalAccuracy <= kPULDistanceAllowedAccuracy;
        BOOL isStill = motionType == pkNotMoving;
        BOOL wasStill = NO;
        BOOL tooLongSinceLastUpdate = [location.timestamp timeIntervalSinceDate:_currentLocation.timestamp] > 60;
        
        // determine if we have a different location
        @try {
            wasStill = acct.location.movementType == pkNotMoving;
            // round each lat lon for comparison
            CGFloat newLat = round(100000 * location.coordinate.latitude) / 100000;
            CGFloat newLon = round(100000 * location.coordinate.longitude) / 100000;
            CGFloat acctLat = round(100000 * acct.location.coordinate.latitude) / 100000;
            CGFloat acctLon = round(100000 * acct.location.coordinate.longitude) / 100000;
            
            hasDifferentLoc =   (newLat != acctLat || newLon != acctLon ||
                                 positionType != _currentPositionType ||
                                 motionType != _currentMotionType) ;
            
            if (hasDifferentLoc && worseAccuracy && isStill)
            {
                hasDifferentLoc = NO;
            }
            else if (hasDifferentLoc && worseAccuracy)
            {
                // check if the loss of accuracy
            }
        }
        @catch (NSException *exception) {
            ;
        }
        
        if (hasDifferentLoc ||
            ((wasStill != isStill) && hasPosMotionData) || // were still and now we're moving, or vice versa
            improvedAccuracy || // accuracy has improved
            !_currentLocation || // or we don't have a location yet
            (acceptableAccuracy && hasDifferentLoc) || // or accuracy is good enough
            tooLongSinceLastUpdate)
        {
            [self _pushToBuffer:location];
            _currentMotionType = motionType;
            _currentPositionType = positionType;
        }
    }];
   
}

- (void)_pushToBuffer:(CLLocation*)loc
{
    if (_locationBuffer.count == 0)
    {
        PULLog(@"\twill update to location %@", loc);
        [_locationBuffer addObject:loc];
        _currentLocation = loc;
    }
    else
    {
        CLLocation *lastLoc = [self _peakFromBuffer];
        if (loc.horizontalAccuracy <= lastLoc.horizontalAccuracy)
        {
            PULLog(@"\twill update to location %@", loc);
            [_locationBuffer addObject:loc];
            _currentLocation = loc;
        }
    }
}

- (nullable CLLocation*)_peakFromBuffer;
{
    if (_locationBuffer.count == 0)
    {
        return nil;
    }
    else
    {
        return _locationBuffer[_locationBuffer.count-1];
    }
}

- (void)_clearBuffer;
{
    [_locationBuffer removeAllObjects];
}

- (void)_saveCurrentLocation
{
    if (_locationBuffer.count > 0)
    {
        [self _saveNewLocation:[self _peakFromBuffer]
                      position:_currentPositionType
                        motion:_currentMotionType];
        [self _clearBuffer];
    }
}

- (void)_saveNewLocation:(CLLocation*)location position:(PKPositionType)positionType motion:(PKMotionType)motionType

{
    PULUser *acct = [PULUser currentUser];
    
    if (!acct) { return; } 

    // save new location if coords are different or if the accuracy has improved
    PULLog(@"\tsaving new location: %@", location);
    PULLog(@"\t\tmotion type: %zd", motionType);
    [_parse updateLocation:location
              movementType:motionType
              positionType:positionType];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationUpdatedNotification
                                                            object:location];
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


- (void)_startAuxLocationManager
{
    PULLog(@"starting aux loc manager");
    [parkour stopTrackPosition];
    
    _locationManager.distanceFilter = _currentDistanceFilter;
    _locationManager.desiredAccuracy = _currentDesiredAccuracy;
    [_locationManager startUpdatingLocation];
    _isUsingAuxLocationManager = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        PULLog(@"pausing aux loc manager");
        [_locationManager stopUpdatingLocation];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_currentTrackingMode * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_isUsingAuxLocationManager)
            {
                [self _startAuxLocationManager];
            }
        });
    });
}

- (void)_stopAuxLocationManager
{
    PULLog(@"stopping aux loc manager");
    [_locationManager stopUpdatingLocation];
    _isUsingAuxLocationManager = NO;
    
    [self startUpdatingLocationWithMode:_currentTrackingMode];
}

#pragma mark - Threading
- (void)_runBlockInBackground:(void(^)())block
{
    [self _runBlock:block onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)_runBlockOnMainQueue:(void(^)())block
{
    [self _runBlock:block onQueue:dispatch_get_main_queue()];
}

- (void)_runBlock:(void(^)())block onQueue:(dispatch_queue_t)queue
{
    dispatch_async(queue, ^{
        block();
    });
}


@end
