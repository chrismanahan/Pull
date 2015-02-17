//
//  PULPullDetailViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullDetailViewController.h"
#import "PULMapViewController.h"

#import "PULAccount.h"

#import "PULConstants.h"
#import "CGGeometry+Pull.h"

#import "PULUserImageView.h"

#import <CoreLocation/CoreLocation.h>

@interface PULPullDetailViewController ()

@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *directionArrowView;
@property (strong, nonatomic) IBOutlet UIImageView *userImageView;
@property (strong, nonatomic) IBOutlet PULUserImageView *userImageViewContainer;

@property (strong, nonatomic) id locationNotification;

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
    _nameLabel.text = _user.fullName;
    
    _userImageViewContainer.hasBorder = YES;
    
//    [self.view insertSubview:_userImageViewContainer aboveSubview:_directionArrowView];
    
    if (!_didSetUp2 && _didSetUp)
    {
        // subscribe to notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didUpdateHeading:)
                                                     name:kPULAccountDidUpdateHeadingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didUpdateUser:)
                                                     name:kPULFriendUpdatedNotifcation
                                                   object:_user];
        
        _locationNotification = [[NSNotificationCenter defaultCenter] addObserverForName:kPULAccountDidUpdateLocationNotification
                                                                                  object:nil
                                                                                   queue:[NSOperationQueue currentQueue]
                                                                              usingBlock:^(NSNotification *note) {
                                                                                  // update distance label
                                                                                  
                                                                                  CLLocation *loc = [note object];
                                                                                  
                                                                                  CGFloat distance = [loc distanceFromLocation:_user.location];
                                                                                  
                                                                                  [self distanceUpdated:distance];
                                                                                  
                                                                              }];
//
//    NSArray *stack = [NSThread callStackSymbols];
//    // don't set up if stack contains segue
//    for (NSString* call in stack)
//    {
//        if ([call containsString:@"PULSlideSegue"])
//        {
//            return;
//        }
//    }

//        CGFloat yOffset = CGRectGetMinY(_directionArrowView.frame) - CGRectGetMaxY(_distanceLabel.frame) - 8;
//
//        CGPoint userCenter = _userImageViewContainer.center;
//        userCenter.x = self.view.center.x;
//        userCenter.y -= yOffset;
//        _userImageViewContainer.center = userCenter;
//        
//        CGPoint arrowCenter = _directionArrowView.center;
//        arrowCenter.x = self.view.center.x;
//        arrowCenter.y -= yOffset;
//        _directionArrowView.center = arrowCenter;
        
//        _userImageViewContainer.translatesAutoresizingMaskIntoConstraints = YES;
        _directionArrowView.translatesAutoresizingMaskIntoConstraints = YES;
        
//        _userImageViewContainer.autoresizingMask = UIViewAutoresizingNone;
        _directionArrowView.autoresizingMask = UIViewAutoresizingNone;

        _didSetUp = YES;
    }
    
    _didSetUp = YES;
}

- (void)viewDidLoad
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_spinCompass:)];
    tap.numberOfTapsRequired = 2;
    [_userImageViewContainer addGestureRecognizer:tap];
}

- (void)_spinCompass:(UIGestureRecognizer*)gesture
{
//    static int mult = 1;
//    CGSize offset = CGSizeMake(_userImageViewContainer.center.x - _directionArrowView.center.x, _userImageViewContainer.center.y - _directionArrowView.center.y);
//    __block CGFloat rotation = M_PI_2 * mult;
//    
//    __block CGAffineTransform tr = CGAffineTransformIdentity;
//    tr = CGAffineTransformConcat(tr,CGAffineTransformMakeTranslation(-offset.width, -offset.height));
//    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeRotation(rotation) );
//    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeTranslation(offset.width, offset.height) );
//    
//    
//    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
//        [_directionArrowView setTransform:tr];
//    } completion:^(BOOL finished) {
//        if (finished && !CGAffineTransformEqualToTransform(_directionArrowView.transform, CGAffineTransformIdentity)) {
//            [self _spinCompass:nil];
//        }
//    }];
    
    
//    [UIView animateWithDuration:0.2 animations:^{
//        [_directionArrowView setTransform:tr];
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:0.2 animations:^{
//            rotation = M_PI * mult++;
//            tr = CGAffineTransformIdentity;
//            tr = CGAffineTransformConcat(tr,CGAffineTransformMakeTranslation(-offset.width, -offset.height));
//            tr = CGAffineTransformConcat(tr, CGAffineTransformMakeRotation(rotation) );
//            tr = CGAffineTransformConcat(tr, CGAffineTransformMakeTranslation(offset.width, offset.height) );
//
//            [_directionArrowView setTransform:tr];
//        }];
//    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kPULAccountDidUpdateHeadingNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kPULFriendUpdatedNotifcation
                                                  object:_user];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_locationNotification];
}

- (void)distanceUpdated:(CGFloat)distance
{
    [self updateDistanceLabel:distance];
    
    if (distance <= kPULNearbyDistance && !_nearby)
    {
        _directionArrowView.image = [UIImage imageNamed:@"nearby_compass_full"];
        _nearby = YES;
        _directionArrowView.alpha = 0.0;
        
        _nearbyRadarTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                             target:self
                                                           selector:@selector(_flashCompass)
                                                           userInfo:nil
                                                            repeats:YES];
    }
    else if (_nearby && distance > kPULNearbyDistance)
    {
        _directionArrowView.image = [UIImage imageNamed:@"round_compass"];
        _nearby = NO;
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
        string = @"Is Nearby\n(within 50 feet)";
        _distanceLabel.numberOfLines = 2;
    }
    else
    {
        string = [NSString stringWithFormat:@"%.2f %@", convertedDistance, unit];
        _distanceLabel.numberOfLines = 1;
    }
    
    _distanceLabel.text = string;
}

#pragma mark - Actions
- (IBAction)ibBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)ibMap:(id)sender
{
    PULMapViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier: NSStringFromClass([PULMapViewController class])];
    
    vc.user = _user;
    
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Notifcation Selectors
- (void)didUpdateHeading:(NSNotification*)notif
{
    CLHeading *heading = [notif object];
    
    if (_shouldRotate)
    {
        // update direction of arrow
        CGFloat degrees = [self p_calculateAngleBetween:[PULAccount currentUser].location.coordinate
                                                    and:_user.location.coordinate];
    //    CGFloat head = normalizeHead(heading.trueHeading);
        CGFloat rads = (degrees - heading.trueHeading) * M_PI / 180;
        
        CGSize offset = CGSizeMake(_userImageViewContainer.center.x - _directionArrowView.center.x, _userImageViewContainer.center.y - _directionArrowView.center.y);
        CGFloat rotation = rads;
          
        CGAffineTransform tr = CGAffineTransformIdentity;
        tr = CGAffineTransformConcat(tr,CGAffineTransformMakeTranslation(-offset.width, -offset.height));
        tr = CGAffineTransformConcat(tr, CGAffineTransformMakeRotation(rotation) );
        tr = CGAffineTransformConcat(tr, CGAffineTransformMakeTranslation(offset.width, offset.height) );
        
    //    PULLog(@"rotation: %.2f", rotation);
    //    PULLog(@"\thead: %.2f", heading.trueHeading);
    //    PULLog(@"\tdegs: %.2f", degrees);
    //    PULLog(@"\thead: %.2f", head);
        
        [_directionArrowView setTransform:tr];
        
    //    _directionArrowView.transform = CGAffineTransformMakeRotation(rads);
        
    //    [self.view insertSubview:_userImageViewContainer aboveSubview:_directionArrowView];
    }
}
//
//double normalizeHead(double head)
//{
//    float mult = 360.0 / 32;
//    float x = head / mult;
//    
//    return (int)x * mult;
//}

- (void)didUpdateUser:(NSNotification*)notif
{
    PULUser *user = [notif object];
    
    // find distance and update label
    CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:user.location];
    
    [self distanceUpdated:distance];
}

#pragma mark - Private
-(CGFloat) p_calculateAngleBetween:(CLLocationCoordinate2D)coords0 and:(CLLocationCoordinate2D)coords1 {
   /* double x = 0, y = 0 , deg = 0,deltaLon = 0;
    
    // latitude is x
    // longitude is y
    // don't forget
    deltaLon = coords1.longitude - coords0.longitude;
    y = sin(deltaLon) * cos(coords1.latitude);
    x = cos(coords0.latitude) * sin(coords1.latitude) - sin(coords0.latitude) * cos(coords1.latitude) * cos(deltaLon);
    deg = RADIANS_TO_DEGREES(atan2(y, x));
    
    if(deg < 0)
    {
        deg = -deg;
    }
    else
    {
        deg = 360 - deg;
    }
    
    return deg;
    */
    
    
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

@end
