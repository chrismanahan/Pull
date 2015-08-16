//
//  PULPullDetailViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullDetailViewController.h"

#import "CGGeometry+Pull.h"

#import "PULUserImageView.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <sys/utsname.h>

const CGFloat kPULCompassFlashTime = 1.5;

@interface PULPullDetailViewController ()

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) UIView *mapOverlayView;

@property (strong, nonatomic) IBOutlet UIButton *mapViewButton;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *directionArrowView;
@property (strong, nonatomic) IBOutlet UIImageView *userImageView;
@property (strong, nonatomic) IBOutlet PULUserImageView *userImageViewContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *userImageViewTopConstraint;

@property (strong, nonatomic) id locationNotification;
@property (strong, nonatomic) id presenceNotification;

@property (nonatomic) BOOL didSetUp;
@property (nonatomic) BOOL didSetUp2;

@property (nonatomic, strong) NSTimer *nearbyRadarTimer;
@property (nonatomic, getter=isNearby) BOOL nearby;
@property (nonatomic) BOOL shouldRotate;

@end

@implementation PULPullDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _shouldRotate = YES;
    
    // set ui based on loaded user
    CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:_user.location];
    [self distanceUpdated:distance];
    
    _userImageView.image = _user.image;
    _userImageViewContainer.hasBorder = YES;
    _nameLabel.text = _user.fullName;
    
    if (!_didSetUp2 && _didSetUp)
    {
        _directionArrowView.translatesAutoresizingMaskIntoConstraints = YES;
        
        _directionArrowView.autoresizingMask = UIViewAutoresizingNone;
        
        _didSetUp = YES;
        
        
    }
    
    _didSetUp = YES;
    
    [self.view insertSubview:_userImageViewContainer aboveSubview:_directionArrowView];
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.05;
    span.longitudeDelta = 0.05;
    
    CLLocationCoordinate2D location = [PULAccount currentUser].location.coordinate;
    region.span = span;
    region.center = location;
    
    [_mapView setRegion:region];
    [self.view insertSubview:_mapView atIndex:0];
    
    //    if (_mapOverlayView)
    //    {
    //        [_mapOverlayView removeFromSuperview];
    //    }
    //    _mapOverlayView = [UIView pullVisualEffectViewWithFrame:_mapView.frame];
    //    [self.view insertSubview:_mapOverlayView aboveSubview:_mapView];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [[PULLocationUpdater sharedUpdater] stopUpdatingHeading];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[PULLocationUpdater sharedUpdater] startUpdatingHeadingWithBlock:^(CLHeading *heading) {
        if (_shouldRotate)
        {
            // update direction of arrow
            CGFloat degrees = [self p_calculateAngleBetween:[PULAccount currentUser].location.coordinate
                                                        and:_user.location.coordinate];
            
            CGFloat rads = (degrees - heading.trueHeading) * M_PI / 180;
            
            [self _rotateCompassToRadians:rads];
        }
    }];
}

- (void)viewDidLoad
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_spinCompass:)];
    tap.numberOfTapsRequired = 2;
    [_userImageViewContainer addGestureRecognizer:tap];
    
    CGFloat offset = 0;
    if ([deviceName() hasSuffix:@"7,1"])
    {
        // iphone 6 plus
        offset = 7;
    }
    else if ([deviceName() hasSuffix:@"7,2"])
    {
        // iphone 6
        offset = 6;
    }
    _userImageViewTopConstraint.constant += offset;
}

NSString* deviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}


- (void)distanceUpdated:(CGFloat)distance
{
    [self updateDistanceLabel:distance];
    
    // TODO: remove NO to enable nearby compass again
    if (distance <= kPULNearbyDistance && !_nearby && NO)
    {
        NSString *imageName = @"nearby_compass";
        
        _directionArrowView.image = [UIImage imageNamed:imageName];
        _nearby = YES;
        //        _nearbyInfoButton.hidden = NO;
        _directionArrowView.alpha = 0.0;
        
        _nearbyRadarTimer = [NSTimer scheduledTimerWithTimeInterval:kPULCompassFlashTime
                                                             target:self
                                                           selector:@selector(_flashCompass)
                                                           userInfo:nil
                                                            repeats:YES];
    }
    else if (_nearby && distance > kPULNearbyDistance)
    {
        _directionArrowView.image = [UIImage imageNamed:@"cascade_compass"];
        _nearby = NO;
        //        _nearbyInfoButton.hidden = YES;
        _shouldRotate = YES;
        _directionArrowView.alpha = 1.0;
        
        if (_nearbyRadarTimer)
        {
            [_nearbyRadarTimer invalidate];
            _nearbyRadarTimer = nil;
        }
    }
}

- (void)_flashCompass
{
    if (_nearby)
    {
        _shouldRotate = NO;
        _directionArrowView.alpha = 1.0;
        [UIView animateWithDuration:0.3
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _directionArrowView.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             if (!_nearby)
                             {
                                 _directionArrowView.alpha = 1.0;
                             }
                             
                             _shouldRotate = YES;
                         }];
    }
}

#pragma mark - UI Setters
- (void)updateDistanceLabel:(CGFloat)distance
{
    CGFloat convertedDistance;
    NSString *unit, *formatString;
    BOOL showNearbyString = NO;
    // TODO: localize distance
    if (distance < kPULDistanceUnitCutoff)
    {
        // distance as ft
        convertedDistance = METERS_TO_FEET(distance);
        unit = @"Feet";
        formatString = @"%i %@";
        
        if (convertedDistance <= kPULNearbyDistance)
        {
            showNearbyString = YES;
        }
    }
    else
    {
        // distance as miles
        convertedDistance = METERS_TO_MILES(distance);
        unit = @"Miles";
        formatString = @"%.2f %@";
    }
    
    NSString *string;
    if (showNearbyString)
    {
        string = @"Is Nearby";
    }
    else
    {
        string = [NSString stringWithFormat:@"%.2f %@", convertedDistance, unit];
    }
    
    _distanceLabel.text = string;
}

#pragma mark - Notifcation Selectors
- (void)didUpdateUser:(NSNotification*)notif
{
    PULUser *user = [notif object];
    
    // find distance and update label
    CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:user.location];
    
    [self distanceUpdated:distance];
}

#pragma mark - Private
- (void)_rotateCompassToRadians:(CGFloat)rads
{
    [self _rotateCompassToRadians:rads animated:NO];
}

- (void)_rotateCompassToRadians:(CGFloat)rads animated:(BOOL)animated
{
    CGSize offset = CGSizeMake(_userImageViewContainer.center.x - _directionArrowView.center.x, _userImageViewContainer.center.y - _directionArrowView.center.y);
    
    CGAffineTransform tr = CGAffineTransformIdentity;
    tr = CGAffineTransformConcat(tr,CGAffineTransformMakeTranslation(-offset.width, -offset.height));
    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeRotation(rads));
    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeTranslation(offset.width, offset.height) );
    
    if (animated)
    {
        [UIView animateWithDuration:1.0 animations:^{
            [_directionArrowView setTransform:tr];
        }];
    }
    else
    {
        [_directionArrowView setTransform:tr];
    }
}

-(CGFloat) p_calculateAngleBetween:(CLLocationCoordinate2D)coords0 and:(CLLocationCoordinate2D)coords1 {
    double myLat = coords0.latitude;
    double myLon = coords0.longitude;
    double yourLat = coords1.latitude;
    double yourLon = coords1.longitude;
    double dx = fabs(myLon - yourLon);
    double dy = fabs(myLat - yourLat);
    
    double ø;
    
    // determine which quadrant we're in relative to other user
    if (dy < 0.0001 && myLon > yourLon) // horizontal right
    {
        return 270;
    }
    else if (dy < 0.0001 && myLon < yourLon) // horizontal left
    {
        return 90;
    }
    else if (dx < 0.0001 && myLat > yourLat) // vertical top
    {
        return 180;
    }
    else if (dx < 0.0001 && myLat < yourLat) // vertical bottom
    {
        return 0;
    }
    else if (myLat > yourLat && myLon > yourLon) // quadrant 1
    {
        ø = atan2(dy, dx);
        return 270 - RADIANS_TO_DEGREES(ø);
    }
    else if (myLat < yourLat && myLon > yourLon) // quad 2
    {
        ø = atan2(dx, dy);
        return 360 - RADIANS_TO_DEGREES(ø);
    }
    else if (myLat < yourLat && myLon < yourLon) // quad 3
    {
        ø = atan2(dx, dy);
    }
    else if (myLat > yourLat && myLon < yourLon) // quad 4
    {
        ø = atan2(dy, dx);
        return 90 + RADIANS_TO_DEGREES(ø);
    }
    return RADIANS_TO_DEGREES( ø);
}

- (void)_spinCompass:(UITapGestureRecognizer*)gesture
{
    //    [self _rotateCompassToRadians:M_PI animated:YES];
    //    [self _rotateCompassToRadians:2 * M_PI animated:YES];
    //
    //    static int sequenceNumber = 4;
    //
    //    gesture.numberOfTapsRequired = fib(sequenceNumber);
    //    PULLog(@"%i", gesture.numberOfTapsRequired);
    //
    //    sequenceNumber++;
}

int fib(int sequenceNumber)
{
    if (sequenceNumber == 1 || sequenceNumber == 2)
    {
        return 1;
    }
    
    return fib(sequenceNumber - 1) + fib(sequenceNumber - 2);
}

@end
