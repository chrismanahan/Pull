//
//  PULLocationUpdater.m
//  Pull
//
//  Created by Chris Manahan on 6/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULLocationUpdater.h"

#import <UIKit/UIKit.h>


// constants
const NSInteger kLocationForegroundDistanceFilter = 2;//20;    // meters
const NSInteger kLocationBackgroundDistanceFilter = 30;

NSString* const PULLocationPermissionsGrantedNotification = @"PULLocationPermissionsGrantedNotification";
NSString* const PULLocationPermissionsNeededNotification = @"PULLocationPermissionsNeededNotification";


// class continuation
@interface PULLocationUpdater ()

@property (nonatomic, strong) CLLocationManager* locationManager;

@end

// implementation
@implementation PULLocationUpdater
{
    UIBackgroundTaskIdentifier _backgroundTask;
}

+(PULLocationUpdater*)sharedUpdater
{
    static PULLocationUpdater* shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared=[[PULLocationUpdater alloc] init];
        
    });
    return shared;
}

-(instancetype)init
{
    if (self = [super init])
    {
//        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized ||
//            ![CLLocationManager locationServicesEnabled])
//        {
//            [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsNeededNotification object:self];
//            
//            // we're doing this so we can give the user a preemptive friendly message before the system message
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_initializeLocationTracking) name:PULLocationPermissionsGrantedNotification object:nil];
//        }
//        else
//        {
//            [self p_initializeLocationTracking];
//        }

    }
    
    return self;
}

- (void)p_requestPermission
{
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_locationManager requestAlwaysAuthorization];
    }
}

-(void)p_initializeLocationTracking
{
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kLocationForegroundDistanceFilter;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingHeading];
    
    [self p_requestPermission];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_applicationDidEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
{
    if (!_locationManager)
    {
        [self p_initializeLocationTracking];   
    }
    PULLog(@"Starting foreground location update");
    [_locationManager startUpdatingLocation];
}
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
{
    [_locationManager stopUpdatingLocation];
}
/*!
 *  Begins updating the user's location and sending it to the BE when the app is in the background
 */
-(void)startBackgroundUpdatingLocation;
{
    if (!_locationManager)
    {
        [self p_initializeLocationTracking];
    }
    
    PULLog(@"Starting background location update");
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _locationManager.distanceFilter = kLocationBackgroundDistanceFilter;
    
    __block UIApplication* app = [UIApplication sharedApplication];
    _backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_locationManager startUpdatingLocation];
        
        while (YES && _backgroundTask != UIBackgroundTaskInvalid) {
            PULLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
            [NSThread sleepForTimeInterval:1];
        }
        
        [app endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    });
}
/*!
 *  Stops background update
 */
-(void)stopBackgroundUpdatingLocation;
{
    [self stopUpdatingLocation];
}

#pragma mark - Location Manager delegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorized)
    {
        PULLog(@"location permission granted");
        if (!_locationManager)
        {
            [self p_initializeLocationTracking];
        }
        [self startUpdatingLocation];
    }
    else
    {
        PULLog(@"access denied");
        
        if (!_locationManager)
        {
            [self p_initializeLocationTracking];
        }
        else
        {
            [self p_requestPermission];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* loc = locations[locations.count-1];
    PULLog(@"Updated locations: %@", locations);

    if ([_delegate respondsToSelector:@selector(locationUpdater:didUpdateLocation:)])
    {
        [_delegate locationUpdater:self didUpdateLocation:loc];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if ([_delegate respondsToSelector:@selector(locationUpdater:didUpdateHeading:)])
    {
        [_delegate locationUpdater:self didUpdateHeading:newHeading];
    }
}

#pragma mark - Application notifications
-(void)p_applicationDidEnterBackground
{
    PULLog(@"entered background");
    [self stopUpdatingLocation];
    [self startBackgroundUpdatingLocation];
}

-(void)p_applicationDidEnterForeground
{
    PULLog(@"entered foreground");
    [self stopBackgroundUpdatingLocation];
    [self startUpdatingLocation];
    
    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
    _backgroundTask = UIBackgroundTaskInvalid;
}

@end
