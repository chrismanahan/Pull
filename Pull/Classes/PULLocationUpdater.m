//
//  PULLocationUpdater.m
//  Pull
//
//  Created by Chris Manahan on 6/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULLocationUpdater.h"

#import "Reachability.h"

#import "PULConstants.h"

#import "PULAccount.h"

#import <UIKit/UIKit.h>

// constants
NSString* const PULLocationPermissionsGrantedNotification = @"PULLocationPermissionsGrantedNotification";
NSString* const PULLocationPermissionsDeniedNotification = @"PULLocationPermissionsNeededNotification";


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
    
  //  Reachability *reach = [Reachability reachabilityWithHostName:]
}

- (BOOL)hasPermission
{
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ||
    [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
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
    
    _locationManager.distanceFilter = kLocationForegroundDistanceFilter;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
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
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;// kCLLocationAccuracyHundredMeters;
    _locationManager.distanceFilter = kLocationBackgroundDistanceFilter;
    
    __block UIApplication* app = [UIApplication sharedApplication];
    _backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_locationManager startUpdatingLocation];
        
//        Firebase *fire = [[Firebase alloc] initWithUrl:@"https://pull.firebaseio.com/users/facebook:10152578194302952/debug"];
        __block int count = 0;
        while (YES && _backgroundTask != UIBackgroundTaskInvalid) {
            if (count % 5 == 0)
            {
                 PULLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
                
//                NSString *test = [NSString stringWithFormat:@"%i", count];
//                [fire setValue:test];
            }
            count++;
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsGrantedNotification object:self];
    }
    else
    {
        PULLog(@"location access denied");
        
        if (!_locationManager)
        {
            [self p_initializeLocationTracking];
        }
        else
        {
            [self p_requestPermission];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsDeniedNotification object:self];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* loc = locations[locations.count-1];
    CLSLog(@"got new location");

    [PULAccount currentUser].location = loc;
    [[PULAccount currentUser] saveKeys:@[@"location"]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
//    if ([_delegate respondsToSelector:@selector(locationUpdater:didUpdateHeading:)])
//    {
//        [_delegate locationUpdater:self didUpdateHeading:newHeading];
//    }
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
