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

#import <parkour/parkour.h>
#import <UIKit/UIKit.h>

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

NSString* const PULLocationPermissionsGrantedNotification = @"PULLocationPermissionsGrantedNotification";
NSString* const PULLocationPermissionsDeniedNotification = @"PULLocationPermissionsNeededNotification";
NSString* const PULLocationHeadingUpdatedNotification = @"PULLocationHeadingUpdatedNotification";

@interface PULLocationUpdater ()

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic) NSTimer* locationUpdateTimer;

@end

@implementation PULLocationUpdater
{
    UIBackgroundTaskIdentifier _backgroundTask;
}

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

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *_locationManager;
    
    @synchronized(self) {
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
//            _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        }
    }
    return _locationManager;
}

- (instancetype)init {
    if (self==[super init]) {
        //Get the share model and also initialize myLocationArray
//        self.shareModel = [LocationShareModel sharedModel];
//        self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

-(void)_initializeLocationTracking
{
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
//    _locationManager.distanceFilter = kLocationForegroundDistanceFilter;
//    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager startUpdatingHeading];
    
    [self _requestPermission];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //  Reachability *reach = [Reachability reachabilityWithHostName:]
}


#pragma mark - Public
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
    BOOL disableParkour = [[NSUserDefaults standardUserDefaults] boolForKey:@"Debug-DisableParkour"];
    
    if (!disableParkour)
    {
        // wanna make sure we update the server at least once for the case of initial update
        __block BOOL hasUpdated = NO;
        
        [parkour start];
        [parkour setMinPositionUpdateRate:3];
        [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {

            if (motionType != NotMoving || !hasUpdated)
            {
                CLS_LOG(@"received location: %@ of type %zd : $zd", position, motionType);
                
                PULAccount *acct = [PULAccount currentUser];
                if (acct.isLoaded)
                {
                    acct.location = position;
                    [acct saveKeys:@[@"location"]];
                    
                    if (!hasUpdated)
                    {
                        hasUpdated = YES;
                    }
                }
                
               
            }

        }];
        [parkour setTrackPositionMode:Pedestrian];
    }
    else
    {
        PULLog(@"startLocationTracking");
        
        if (self.locationUpdateTimer)
        {
            [self.locationUpdateTimer invalidate];
            self.locationUpdateTimer = nil;
        }
        self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                    target:self
                                                                  selector:@selector(updateLocationToServer)
                                                                  userInfo:nil
                                                                   repeats:YES];
        
        if ([CLLocationManager locationServicesEnabled] == NO) {
            PULLog(@"locationServicesEnabled false");
            UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You need to enable your location services for Pull to work" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [servicesDisabledAlert show];
        } else {
            CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
            
            if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
                PULLog(@"authorizationStatus failed");
                
                UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Need Location Services Permission" message:@"You need to enable your location services for Pull to work" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [servicesDisabledAlert show];
            } else {
                PULLog(@"authorizationStatus authorized");
                CLLocationManager *locationManager = [PULLocationUpdater sharedLocationManager];
                locationManager.delegate = self;
                locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                locationManager.distanceFilter = kLocationForegroundDistanceFilter;
                
                if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                    [locationManager requestAlwaysAuthorization];
                }
                [locationManager startUpdatingLocation];
            }
        }
    }
    
//    if (!_locationManager)
//    {
//        [self _initializeLocationTracking];   
//    }
//    
//    _locationManager.distanceFilter = kLocationForegroundDistanceFilter;
//    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    
//    PULLog(@"Starting foreground location update");
//    [_locationManager startUpdatingLocation];
}
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
{
    BOOL disableParkour = [[NSUserDefaults standardUserDefaults] boolForKey:@"Debug-DisableParkour"];
    
    if (!disableParkour)
    {
        [parkour stopTrackPosition];
    }
    else
    {
        [_locationManager stopUpdatingLocation];

        PULLog(@"stopLocationTracking");
        
        if (self.shareModel.timer) {
            [self.shareModel.timer invalidate];
            self.shareModel.timer = nil;
        }
        
        CLLocationManager *locationManager = [PULLocationUpdater sharedLocationManager];
        [locationManager stopUpdatingLocation];
    }
}
///*!
// *  Begins updating the user's location and sending it to the BE when the app is in the background
// */
//-(void)startBackgroundUpdatingLocation;
//{
//    if (!_locationManager)
//    {
//        [self _initializeLocationTracking];
//    }
//    
//    PULLog(@"Starting background location update");
//    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;// kCLLocationAccuracyHundredMeters;
//    _locationManager.distanceFilter = kLocationBackgroundDistanceFilter;
//    
//    __block UIApplication* app = [UIApplication sharedApplication];
//    _backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
//        [app endBackgroundTask:_backgroundTask];
//        _backgroundTask = UIBackgroundTaskInvalid;
//    }];
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [_locationManager startUpdatingLocation];
//        
////        Firebase *fire = [[Firebase alloc] initWithUrl:@"https://pull.firebaseio.com/users/facebook:10152578194302952/debug"];
//        __block int count = 0;
//        while (YES && _backgroundTask != UIBackgroundTaskInvalid) {
//            if (count % 5 == 0)
//            {
//                 PULLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
//                
////                NSString *test = [NSString stringWithFormat:@"%i", count];
////                [fire setValue:test];
//            }
//            count++;
//            [NSThread sleepForTimeInterval:1];
//        }
//        
//        [app endBackgroundTask:_backgroundTask];
//        _backgroundTask = UIBackgroundTaskInvalid;
//    });
//}
///*!
// *  Stops background update
// */
//-(void)stopBackgroundUpdatingLocation;
//{
//    [self stopUpdatingLocation];
//}

#pragma mark - Location Manager delegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorized)
    {
        PULLog(@"location permission granted");
        if (!_locationManager)
        {
            [self _initializeLocationTracking];
        }
        [self startUpdatingLocation];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsGrantedNotification object:self];
    }
    else
    {
        PULLog(@"location access denied");
        
        if (!_locationManager)
        {
            [self _initializeLocationTracking];
        }
        else
        {
            [self _requestPermission];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationPermissionsDeniedNotification object:self];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    PULLog(@"locationManager didUpdateLocations");
    
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        self.currentLocation = newLocation;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0)
        {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil&&theAccuracy>0
           &&theAccuracy<2000
           &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0))){
            
            self.myLastLocation = theLocation;
            self.myLastLocationAccuracy= theAccuracy;
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:@"latitude"];
            [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:@"longitude"];
            [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:@"theAccuracy"];
            
            //Add the vallid location with good accuracy into an array
            //Every 1 minute, I will select the best location based on accuracy and send to server
            [self.shareModel.myLocationArray addObject:dict];
        }
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel.timer) {
        return;
    }
    
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after 1 minute
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.shareModel.delay10Seconds) {
        [self.shareModel.delay10Seconds invalidate];
        self.shareModel.delay10Seconds = nil;
    }
    
    self.shareModel.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                                    selector:@selector(stopLocationDelayBy10Seconds)
                                                                    userInfo:nil
                                                                     repeats:NO];
    


}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    [[NSNotificationCenter defaultCenter] postNotificationName:PULLocationHeadingUpdatedNotification
                                                        object:newHeading];
    
//    if ([_delegate respondsToSelector:@selector(locationUpdater:didUpdateHeading:)])
//    {
//        [_delegate locationUpdater:self didUpdateHeading:newHeading];
//    }
}

#pragma mark - Private
-(void)stopLocationDelayBy10Seconds{
    CLLocationManager *locationManager = [PULLocationUpdater sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    PULLog(@"locationManager stop Updating after 10 seconds");
}

- (void)updateLocationToServer {
    
    PULLog(@"updateLocationToServer");
    
    // Find the best location from the array based on accuracy
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
    for(int i=0;i<self.shareModel.myLocationArray.count;i++){
        NSMutableDictionary * currentLocation = [self.shareModel.myLocationArray objectAtIndex:i];
        
        if(i==0)
            myBestLocation = currentLocation;
        else{
            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
                myBestLocation = currentLocation;
            }
        }
    }
    PULLog(@"My Best location:%@",myBestLocation);
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if(self.shareModel.myLocationArray.count==0)
    {
        PULLog(@"Unable to get location, use the last known location");
        
        self.myLocation=self.myLastLocation;
        self.myLocationAccuracy=self.myLastLocationAccuracy;
        
    }else{
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude =[[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude =[[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation=theBestLocation;
        self.myLocationAccuracy =[[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    
    PULLog(@"Send to Server: Latitude(%f) Longitude(%f) Accuracy(%f)",self.myLocation.latitude, self.myLocation.longitude,self.myLocationAccuracy);
    
    
    PULAccount *acct = [PULAccount currentUser];
    if (acct.isLoaded)
    {
        acct.location = [[CLLocation alloc] initWithCoordinate:self.myLocation
                                                      altitude:self.currentLocation.altitude
                                            horizontalAccuracy:self.myLocationAccuracy
                                              verticalAccuracy:self.myLocationAccuracy
                                                     timestamp:[NSDate dateWithTimeIntervalSinceNow:0]];
        [acct saveKeys:@[@"location"]];
    }
    //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
    [self.shareModel.myLocationArray removeAllObjects];
    self.shareModel.myLocationArray = nil;
    self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
}

- (void)_requestPermission
{
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_locationManager requestAlwaysAuthorization];
    }
}


- (void) restartLocationUpdates
{
    PULLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [PULLocationUpdater sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kLocationForegroundDistanceFilter;
    
    if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}

#pragma mark Application notifications
-(void)_applicationDidEnterBackground
{
    PULLog(@"entered background");
    
    CLLocationManager *locationManager = [PULLocationUpdater sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kLocationBackgroundDistanceFilter;
    
    if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
//    [self stopUpdatingLocation];
//    [self startBackgroundUpdatingLocation];
}

//-(void)_applicationDidEnterForeground
//{
//    PULLog(@"entered foreground");
//    [self stopBackgroundUpdatingLocation];
//    [self startUpdatingLocation];
//    
//    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
//    _backgroundTask = UIBackgroundTaskInvalid;
//}

@end
