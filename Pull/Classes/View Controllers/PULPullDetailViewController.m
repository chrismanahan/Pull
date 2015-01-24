//
//  PULPullDetailViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullDetailViewController.h"

#import "PULAccount.h"

#import "PULConstants.h"
#import "CGGeometry+Pull.h"

#import <CoreLocation/CoreLocation.h>

@interface PULPullDetailViewController ()

@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *directionArrowView;
@property (strong, nonatomic) IBOutlet UIImageView *userImageView;
@property (strong, nonatomic) IBOutlet UIView *userImageViewContainer;

@end

@implementation PULPullDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:_user.location];
    
    [self updateDistanceLabel:distance];
    
    _userImageView.image = _user.image;
    [self.view insertSubview:_userImageViewContainer aboveSubview:_directionArrowView];
    
    // TODO: remove observers when leaving detail view
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateHeading:)
                                                 name:kPULAccountDidUpdateHeadingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateUser:)
                                                 name:kPULFriendUpdatedNotifcation
                                               object:_user];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPULAccountDidUpdateLocationNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      // update distance label
                                                      
                                                      CLLocation *loc = [note object];
                                                      
                                                      CGFloat distance = [loc distanceFromLocation:_user.location];
                                                      
                                                      [self updateDistanceLabel:distance];
                                                      
                                                  }];

    CGFloat yOffset = CGRectGetMinY(_directionArrowView.frame) - CGRectGetMaxY(_distanceLabel.frame) - 8;
    
    CGPoint userCenter = _userImageViewContainer.center;
    userCenter.x = self.view.center.x;
    userCenter.y -= yOffset;
    _userImageViewContainer.center = userCenter;
    
    CGPoint arrowCenter = _directionArrowView.center;
    arrowCenter.x = self.view.center.x;
    arrowCenter.y -= yOffset;
    _directionArrowView.center = arrowCenter;
    
    _userImageViewContainer.translatesAutoresizingMaskIntoConstraints = YES;
    _directionArrowView.translatesAutoresizingMaskIntoConstraints = YES;
    
    _userImageViewContainer.autoresizingMask = UIViewAutoresizingNone;
    _directionArrowView.autoresizingMask = UIViewAutoresizingNone;
    
//    
//    NSLog(@"arrow frame: %@", NSStringFromCGRect(_directionArrowView.frame));
//    NSLog(@"arrow bounds: %@", NSStringFromCGRect(_directionArrowView.bounds));
//    
//    NSLog(@"user frame: %@", NSStringFromCGRect(_userImageViewContainer.frame));
//    NSLog(@"user bounds: %@", NSStringFromCGRect(_userImageViewContainer.bounds));
//
//    CGFloat y = _userImageViewContainer.center.y - CGRectGetMinY(_directionArrowView.frame);
//    CGFloat x = _userImageViewContainer.center.x - CGRectGetMinX(_directionArrowView.frame);
//    CGFloat yOff = y / CGRectGetHeight(_directionArrowView.frame);
//    CGFloat xOff = x / CGRectGetWidth(_directionArrowView.frame);
//    
//    _directionArrowView.center = _userImageViewContainer.center;
//
//    CGPoint anchor = CGPointMake(xOff, yOff);
//    NSLog(@"anchor: %@", NSStringFromCGPoint(anchor));
//    
//    _directionArrowView.layer.anchorPoint = anchor;
}

#pragma mark - UI Setters
- (void)updateDistanceLabel:(CGFloat)distance
{
    CGFloat convertedDistance;
    NSString *unit, *formatString;
    // TODO: localize distance
    if (distance < kPULDistanceUnitCutoff)
    {
        // distance as ft
        convertedDistance = METERS_TO_FEET(distance);
        unit = @"ft";
        formatString = @"%i %@";
    }
    else
    {
        // distance as miles
        convertedDistance = METERS_TO_MILES(distance);
        unit = @"miles";
        formatString = @"%.2f %@";
    }
    
    NSString *string = [NSString stringWithFormat:@"%.2f %@", convertedDistance, unit];
    
    _distanceLabel.text = string;
}

#pragma mark - Actions
- (IBAction)ibBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Notifcation Selectors
- (void)didUpdateHeading:(NSNotification*)notif
{
    CLHeading *heading = [notif object];
    
    // update direction of arrow
    CGFloat degrees = [self p_calculateAngleBetween:[PULAccount currentUser].location.coordinate
                                                and:_user.location.coordinate];
    CGFloat rads = (degrees - heading.trueHeading) * M_PI / 180;
    
    CGPoint convertedCenter = [_directionArrowView convertPoint:_userImageViewContainer.center fromView:_userImageViewContainer ];

    CGSize offset = CGSizeMake(_userImageViewContainer.center.x - _directionArrowView.center.x, _userImageViewContainer.center.y - _directionArrowView.center.y);
//    CGSize offset = CGSizeMake(_directionArrowView.center.x - convertedCenter.x, _directionArrowView.center.y - convertedCenter.y);
    // I may have that backwards, try the one below if it offsets the rotation in the wrong direction..
//    CGSize offset = CGSizeMake(convertedCenter.x -_directionArrowView.center.x , convertedCenter.y - _directionArrowView.center.y);
    CGFloat rotation = rads;
  
    NSLog(@"offset: %@", NSStringFromCGSize(offset));
    
    CGAffineTransform tr = CGAffineTransformIdentity;
    tr = CGAffineTransformConcat(tr,CGAffineTransformMakeTranslation(-offset.width, -offset.height));
    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeRotation(rotation) );
    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeTranslation(offset.width, offset.height) );
    
    
    [_directionArrowView setTransform:tr];
    
//    _directionArrowView.transform = CGAffineTransformMakeRotation(rads);
    
    [self.view insertSubview:_userImageViewContainer aboveSubview:_directionArrowView];
}

- (void)didUpdateUser:(NSNotification*)notif
{
    PULUser *user = [notif object];
    
    // find distance and update label
    CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:user.location];
    
    [self updateDistanceLabel:distance];
}

#pragma mark - Private
-(CGFloat) p_calculateAngleBetween:(CLLocationCoordinate2D)coords0 and:(CLLocationCoordinate2D)coords1 {
    double x = 0, y = 0 , deg = 0,deltaLon = 0;
    
    deltaLon = coords1.longitude - coords0.longitude;
    y = sin(deltaLon) * cos(coords1.latitude);
    x = cos(coords0.latitude) * sin(coords1.latitude) - sin(coords0.latitude) * cos(coords1.latitude) * cos(deltaLon);
    deg = RADIANS_TO_DEGREES(atan2(y, x));
    
    if(deg < 0)
    {
        deg = -deg;
    } else
    {
        deg = 360 - deg;
    }
    
    return deg;
}

@end
