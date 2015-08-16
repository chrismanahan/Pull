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
//NSString* const PULLocationHeadingUpdatedNotification = @"PULLocationHeadingUpdatedNotification";

@interface PULLocationUpdater ()

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic) NSTimer* locationUpdateTimer;

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
                                                          // start location up if we have any pulled friends
                                                          if ([self _shouldUpdateLocation])
                                                          {
                                                              [self startUpdatingLocation];
                                                          }
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:FireArrayObjectRemovedNotification
                                                          object:[PULAccount currentUser].pulls
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          // start location up if we have any pulled friends
                                                          if (![self _shouldUpdateLocation])
                                                          {
                                                              [self stopUpdatingLocation];
                                                          }
                                                      }];
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager startUpdatingHeading];
    }
    
    return self;
}

#pragma mark - Public
- (BOOL)hasPermission
{
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ||
    [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
}

- (void)startUpdatingHeadingWithBlock:(PULHeadingBlock)block;
{
    [_locationManager startUpdatingHeading];
    
    _headingChangeBlock = [block copy];
}

- (void)stopUpdatingHeading;
{
    [_locationManager stopUpdatingHeading];
    _headingChangeBlock = nil;
}

/*!
 *  Begins updating the user's location and sending it to the BE when it does
 */
-(void)startUpdatingLocation;
{
    // verify we should be starting location
    if ([self _shouldUpdateLocation])
    {
        PULLog(@"starting location updater");
        _tracking = YES;

        [parkour start];
        [parkour setMinPositionUpdateRate:3];
        [parkour trackPositionWithHandler:^(CLLocation *position, PKPositionType positionType, PKMotionType motionType) {

            CLS_LOG(@"received location: %@ of type %zd : $zd", position, motionType);
            
            PULAccount *acct = [PULAccount currentUser];
            if (acct.isLoaded)
            {
                acct.currentMotionType = motionType;
                acct.location = position;
                acct.currentPositionType = positionType;
                
                [acct saveKeys:@[@"location"]];
            }

        }];
    }
}
/*!
 *  Stops updating and posting location
 */
-(void)stopUpdatingLocation;
{
    PULLog(@"starting location updater");
    
    _tracking = NO;
    
    [parkour stopTrackPosition];
    [parkour stop];
}

#pragma mark - Location Manager delegate
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorized)
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
    if (_headingChangeBlock)
    {
        _headingChangeBlock(newHeading);
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
    return ([[PULAccount currentUser] pullsPulledNearby].count > 0 || [[PULAccount currentUser] pullsPulledFar].count > 0) && !_tracking;
}


@end
