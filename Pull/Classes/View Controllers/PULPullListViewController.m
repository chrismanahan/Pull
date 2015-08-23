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

#import "PULCompassView.h"
#import "PULPullDetailViewController.h"
#import "PULLoginViewController.h"
#import "PULUserSelectViewController.h"

#import "PULPulledUserSelectView.h"

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"
#import "PULReverseModal.h"

#import "PULPullNotNearbyOverlay.h"

const NSInteger kPULPullListNumberOfTableViewSections = 4;

const NSInteger kPULPulledNearbySection = 1;
const NSInteger kPULPendingSection = 0;
const NSInteger kPULWaitingSection = 3;
const NSInteger kPULPulledFarSection = 2;

@interface PULPullListViewController () <UIAlertViewDelegate, PULPulledUserSelectViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIView *noActivityOverlay;
@property (strong, nonatomic) IBOutlet PULPulledUserSelectView *userSelectView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet PULCompassView *compassView;

@property (nonatomic, strong) PULPull *displayedPull;

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

    _userSelectView.delegate = self;
    
//    
    id loginObs = [[NSNotificationCenter defaultCenter] addObserverForName:PULAccountDidLoginNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [_userSelectView initialize];
                                                      
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
                                                      [PULLocationOverlay overlayOnView:self.view];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationPermissionsGrantedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [PULLocationOverlay removeOverlayFromView:self.view];
                                                      
                                                  }];
    
    
    [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // add overlay requesting location if we are missing it
    if (![PULLocationUpdater sharedUpdater].hasPermission && ![PULLocationOverlay viewContainsOverlay:self.view])
    {
        PULLog(@"adding location overlay");
        [PULLocationOverlay overlayOnView:self.view];
        
        id locObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue currentQueue]
                                                                       usingBlock:^(NSNotification *note) {
                                                                           if ([PULLocationUpdater sharedUpdater].hasPermission)
                                                                           {
                                                                               [PULLocationOverlay removeOverlayFromView:self.view];
                                                                               
                                                                               [[NSNotificationCenter defaultCenter] removeObserver:locObserver];
                                                                               
                                                                           }
                                                                       }];
    }
    
    // show no activity overlay if needed
    if ([PULAccount currentUser].pulls.count > 0)
    {
        _noActivityOverlay.hidden = YES;
    }
    else
    {
        _noActivityOverlay.hidden = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    [[PULAccount currentUser] stopObservingKeyPath:@"location"];
//    [_userSelectView.selectedUser stopObservingKeyPath:@"location"];
    
//    [[PULAccount currentUser].pulls unregisterLoadedBlock];
//    [[PULAccount currentUser].pulls unregisterForAllKeyChanges];
}

#pragma mark - Private
//- (void)_startAccountObservers
//{
//    PULAccount *acct = [PULAccount currentUser];
//    if (!acct || !acct.isLoaded)
//    {
//        [acct observeKeyPath:@"loaded" block:^{
//            [self _startAccountObservers];
//        }];
//        
//        return;
//    }
//    
//    // observe when the status of any pull has changed
//    if (![acct.pulls isRegisteredForKeyChange:@"status"])
//    {
//        [acct.pulls registerForKeyChange:@"status" onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
//            // start tracking location if we haven't been
//            if (((PULPull*)object).status == PULPullStatusPulled && ![PULLocationUpdater sharedUpdater].isTracking)
//            {
//                [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
//            }
//        }];
//    }
//    
//    // observe when account moves
//    [acct observeKeyPath:@"location" block:^{
//        [self updateUI];
//    }];
//    
//}

#pragma mark - Pulled user select view delegate
- (void)didSelectPull:(PULPull * __nonnull)pull atIndex:(NSUInteger)index
{
    // check if new
    if (![_displayedPull isEqual:pull])
    {
        // stop observing previous user
        PULUser *user = [_displayedPull otherUser];
        [user stopObservingKeyPath:@"location"];
        
        _displayedPull = pull;
        user = [_displayedPull otherUser];
        [user observeKeyPath:@"location"
                       block:^{
                           [self updateUI];
                       }];
        
        [self updateUI];
    }
}

- (void)userSelectViewDidUpdateToDistance:(CGFloat)distance forSelectedPull:(PULPull * __nonnull)pull
{
    
}

- (void)updateUI
{
    PULUser *user = [_displayedPull otherUser];
    
    if (![_nameLabel.text isEqualToString:user.fullName])
    {
        _nameLabel.text = user.fullName;
    }
    
    if (_displayedPull.status == PULPullStatusPulled || /* DISABLES CODE */ (YES))
    {
        if (_displayedPull.isNearby)
        {
            _distanceLabel.text = PUL_FORMATTED_DISTANCE_FEET([user distanceFromUser:[PULAccount currentUser]]);
        }
        else
        {
            _distanceLabel.text = @"Not Nearby";
        }
    }
    else
    {
        _distanceLabel.text = @"NA";
    }
    
    [_compassView setPull:_displayedPull];
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


@end
