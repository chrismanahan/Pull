//
//  PULPullListViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullListViewController.h"

#import "PULLoadingIndicator.h"
#import "PULNoConnectionView.h"

#import "PULLocationOverlay.h"
#import "PULNoFriendsOverlay.h"

#import "UIVisualEffectView+PullBlur.h"

#import "PULPullDetailViewController.h"
#import "PULLoginViewController.h"

#import "PULAccount.h"
#import "PULLocationUpdater.h"

#import "PULConstants.h"

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"
#import "PULReverseModal.h"

#import <FacebookSDK/FacebookSDK.h>

const NSInteger kPULPullListNumberOfTableViewSections = 4;

const NSInteger kPULPulledSection = 1;
const NSInteger kPULPendingSection = 0;
const NSInteger kPULWaitingSection = 2;
const NSInteger kPULNearbySection = 3;

@interface PULPullListViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UITableView *friendTableView;

//@property (nonatomic, strong) PULLoadingIndicator *loadingIndicator;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopContraint;

@end

@implementation PULPullListViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    // inset the table view to give it the slide under header effect
    _tableViewTopContraint.constant = -64;
    _friendTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    

    
//    [[NSNotificationCenter defaultCenter] addObserverForName:PULConnectionLostNotification
//                                                      object:nil
//                                                       queue:[NSOperationQueue currentQueue]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      [PULNoConnectionView overlayOnView:_friendTableView offset:_friendTableView.contentInset.top];
//                                                      
//                                                      _friendTableView.scrollEnabled = NO;
//                                                  }];
    
//    [[NSNotificationCenter defaultCenter] addObserverForName:PULConnectionRestoredNotification
//                                                      object:nil
//                                                       queue:[NSOperationQueue currentQueue]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      
//                                                      [PULNoConnectionView removeOverlayFromView:_friendTableView];
//                                                      _friendTableView.scrollEnabled = YES;
//                                                  }];
    
    // subscribe to disabled location updates
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationPermissionsDeniedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [PULLocationOverlay overlayOnView:_friendTableView offset:_friendTableView.contentInset.top];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationPermissionsGrantedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [PULLocationOverlay removeOverlayFromView:_friendTableView];
                                                      
                                                  }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // add overlay requesting location if we are missing it
    if (![PULLocationUpdater sharedUpdater].hasPermission && ![PULLocationOverlay viewContainsOverlay:_friendTableView])
    {
        PULLog(@"adding location overlay");
        [PULLocationOverlay overlayOnView:_friendTableView offset:_friendTableView.contentInset.top];
        
        id locObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue currentQueue]
                                                                       usingBlock:^(NSNotification *note) {
                                                                           if ([PULLocationUpdater sharedUpdater].hasPermission)
                                                                           {
                                                                               [PULLocationOverlay removeOverlayFromView:_friendTableView];
                                                                               
                                                                               [[NSNotificationCenter defaultCenter] removeObserver:locObserver];
                                                                               
                                                                               [_friendTableView reloadData];
                                                                           }
                                                                       }];
    }
    
}

- (void)reload
{
    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        // reload friends
    }
    else
    {
        PULLog(@"not reloading friends table, still need location permission");
    }
}

#pragma mark - Actions
- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender {}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    PULSlideUnwindSegue *segue = [[PULSlideUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    
    if ([fromViewController isKindOfClass:[PULPullDetailViewController class]])
    {
        segue.slideRight = YES;
    }
    return segue;
}


#pragma mark - Table View Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kPULPullListNumberOfTableViewSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
