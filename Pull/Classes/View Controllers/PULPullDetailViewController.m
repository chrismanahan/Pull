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

#import <CoreLocation/CoreLocation.h>

@interface PULPullDetailViewController ()

@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *directionArrowView;
@property (strong, nonatomic) IBOutlet UIImageView *userImageView;

@end

@implementation PULPullDetailViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:_user.location];
    
    [self updateDistanceLabel:distance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateHeading:)
                                                 name:kPULAccountDidUpdateHeadingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdateUser:)
                                                 name:kPULAccountFriendUpdatedNotifcation
                                               object:[PULAccount currentUser]];
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
    
    _directionArrowView.transform = CGAffineTransformMakeRotation((degrees - heading.trueHeading) * M_PI / 180);
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
