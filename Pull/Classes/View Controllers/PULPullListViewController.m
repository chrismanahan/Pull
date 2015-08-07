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
#import "PULUserSelectViewController.h"

#import "PULAccount.h"
#import "PULLocationUpdater.h"

#import "PULConstants.h"

#import "PULUserCardCell.h"

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"
#import "PULReverseModal.h"

#import "PULPullNotNearbyOverlay.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

const NSInteger kPULPullListNumberOfTableViewSections = 4;

const NSInteger kPULPulledNearbySection = 1;
const NSInteger kPULPendingSection = 0;
const NSInteger kPULWaitingSection = 3;
const NSInteger kPULPulledFarSection = 2;

@interface PULPullListViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UITableView *friendTableView;
@property (strong, nonatomic) IBOutlet UIView *noActivityOverlay;

//@property (nonatomic, strong) PULLoadingIndicator *loadingIndicator;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopContraint;

@property (nonatomic, strong) NSMutableArray *observers;

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
    _observers = [[NSMutableArray alloc] init];
    // inset the table view to give it the slide under header effect
    _tableViewTopContraint.constant = -64;
    _friendTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    
    id loginObs = [[NSNotificationCenter defaultCenter] addObserverForName:PULAccountDidLoginNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self _observePulls];
                                                      
                                                      [[NSNotificationCenter defaultCenter] removeObserver:loginObs];
                                                  }];
    
    
    
    
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      PULLog(@"received access token change notif, reloading table");
                                                      [self reload];
                                                  }];
    
    [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
    
}

- (void)_observePulls
{
    if (![[PULAccount currentUser].pulls hasLoadBlock])
    {
        [[PULAccount currentUser].pulls registerLoadedBlock:^(FireMutableArray *objects) {
            [self reload];
        }];
    }
    
    if (![[PULAccount currentUser].pulls isRegisteredForKeyChange:@"status"])
    {
        [[PULAccount currentUser].pulls registerForKeyChange:@"status" onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
            [self reload];
        }];
    }
    
    if (![[PULAccount currentUser].pulls isRegisteredForKeyChange:@"nearby"])
    {
        [[PULAccount currentUser].pulls registerForKeyChange:@"nearby" onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
            UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
            if (appState == UIApplicationStateActive)
            {
                [self reload];
            }
            else
            {
                UILocalNotification *notif = [[UILocalNotification alloc] init];
                notif.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                notif.soundName = UILocalNotificationDefaultSoundName;
                notif.alertBody = @"A friend is nearby!";
                [[UIApplication sharedApplication] scheduleLocalNotification:notif];
            }
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_friendTableView reloadData];
    
    if ([PULAccount currentUser])
    {
        [self _observePulls];
    }
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[PULAccount currentUser].pulls unregisterLoadedBlock];
    [[PULAccount currentUser].pulls unregisterForAllKeyChanges];
}

- (void)reload
{
    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        [_friendTableView reloadData];

        if ([PULAccount currentUser].pulls.count > 0)
        {
            _noActivityOverlay.hidden = YES;
        }
        else
        {
            _noActivityOverlay.hidden = NO;
        }
    }
    else
    {
        PULLog(@"not reloading friends table, still need location permission");
    }
}

#pragma mark - Actions
- (IBAction)ibSendPull:(id)sender
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULUserSelectViewController class])];
    
    [self presentViewController:vc animated:YES completion:nil];
}

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
    NSArray *datasource = [self _pullsForSection:indexPath.section];
    
    NSString *cellId = @"PullCardCell";
    /*
    switch (indexPath.section) {
        case kPULPulledNearbySection:
        {
            cellId = @"PulledNearbyCell";
            break;
        }
        case kPULPulledFarSection:
        {
            cellId = @"PulledFarCell";
            break;
        }
        case kPULPendingSection:
        {
            cellId = @"PullPendingCell";
            break;
        }
        case kPULWaitingSection:
        {
            cellId = @"PullWaitingCell";
        }
    }*/
    
    PULUserCardCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    PULPull *pull = datasource[indexPath.row];
    
    cell.pull = pull;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell loadUI];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kPULPullListNumberOfTableViewSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self _pullsForSection:section].count;
}

- (NSArray*)_pullsForSection:(NSInteger)section
{
    switch (section) {
        case kPULPulledNearbySection:
        {
            return [[PULAccount currentUser] pullsPulledNearby];
        }
        case kPULPulledFarSection:
        {
            return [[PULAccount currentUser] pullsPulledFar];
        }
        case kPULPendingSection:
        {
            return [[PULAccount currentUser] pullsPending];
        }
        case kPULWaitingSection:
        {
            return [[PULAccount currentUser] pullsWaiting];
        }
    }
    
    return nil;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger section = indexPath.section;
    
    PULPull *pull = [self _pullsForSection:section][indexPath.row];
    if (section == kPULPulledNearbySection)
    {
        PULPullDetailViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullDetailViewController class])];
        vc.user = [pull otherUser:[PULAccount currentUser]];
        
        PULSlideSegue *seg = [PULSlideSegue segueWithIdentifier:@"DetailSeg"
                                                         source:self
                                                    destination:vc
                                                 performHandler:^{
                                                     ;
                                                 }];
        
        seg.slideLeft = YES;
        
        [seg perform];
    }
    else if (section == kPULPulledFarSection)
    {
        [PULPullNotNearbyOverlay overlayOnView:self.view withPull:pull];
    }
    
}

@end
