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

#import "LocationTracker.h"

@implementation PULRequestLocationViewController

#pragma mark - actions
- (IBAction)ibNext:(id)sender
{
    [[LocationTracker sharedLocationTracker] startLocationTracking];
    
    [self next];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
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
