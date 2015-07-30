//
//  PULRequestLocationViewController.m
//  Pull
//
//  Created by admin on 2/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULRequestLocationViewController.h"
#import "PULRequestNotificationsViewController.h"

#import "PULSlideLeftSegue.h"

#import "PULLocationUpdater.h"

@implementation PULRequestLocationViewController

#pragma mark - actions
- (IBAction)ibNext:(id)sender
{
    [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(next)
                                                 name:PULLocationPermissionsGrantedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(next)
                                                 name:PULLocationPermissionsDeniedNotification
                                               object:nil];
    
    // just in case some how we already have permission
    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        [self next];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)next
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULRequestNotificationsViewController class])];
    
    PULSlideLeftSegue *seg = [[PULSlideLeftSegue alloc] initWithIdentifier:@"RequestNotifsSeg"
                                                                    source:self
                                                               destination:vc];
    [seg perform];
}

@end
