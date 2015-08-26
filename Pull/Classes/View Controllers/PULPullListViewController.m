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

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"
#import "PULReverseModal.h"

#import "PULPulledUserCollectionViewCell.h"

#import "CALayer+Animations.h"
#import "NSArray+Sorting.h"

#import "PULPullNotNearbyOverlay.h"

const NSInteger kPULPullListNumberOfTableViewSections = 4;

const NSInteger kPULPulledNearbySection = 1;
const NSInteger kPULPendingSection = 0;
const NSInteger kPULWaitingSection = 3;
const NSInteger kPULPulledFarSection = 2;

@interface PULPullListViewController () <UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIView *noActivityOverlay;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet PULCompassView *compassView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIView *dialogContainer;
@property (strong, nonatomic) IBOutlet UIButton *dialogAcceptButton;
@property (strong, nonatomic) IBOutlet UIButton *dialogDeclineButton;
@property (strong, nonatomic) IBOutlet UILabel *dialogMessageLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *compassUserImageViewTopConstraint;

@property (nonatomic, strong) NSArray *datasource;
@property (nonatomic, strong) PULPull *displayedPull;
@property (nonatomic, assign) NSInteger selectedIndex;

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
                                                      [PULLocationOverlay overlayOnView:self.view];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationPermissionsGrantedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [PULLocationOverlay removeOverlayFromView:self.view];
                                                      
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      PULLog(@"received access token change notif, reloading table");
                                                      [self reload];
                                                  }];

    [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
 
    
    // add swipe gesture recognizers
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.view addGestureRecognizer:swipeLeft];
    [self.view addGestureRecognizer:swipeRight];
    
    // change top constraint based on screen size
    CGFloat height = CGRectGetHeight([UIScreen mainScreen].bounds);
    if (height > 600)
    {
        _compassUserImageViewTopConstraint.constant -= 10;
    }
    if (height > 700)
    {
        _compassUserImageViewTopConstraint.constant -= 10;
    }
    
    [self.view setNeedsUpdateConstraints];
}

- (void)_swipeLeft
{
    [self setSelectedIndex:_selectedIndex + 1];
}

- (void)_swipeRight
{
    [self setSelectedIndex:_selectedIndex - 1];
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
            
            if (((PULPull*)object).status == PULPullStatusPulled && ![PULLocationUpdater sharedUpdater].isTracking)
            {
                [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
            }
        }];
    }
    
    if (![[PULAccount currentUser].pulls isRegisteredForKeyChange:@"nearby"])
    {
        [[PULAccount currentUser].pulls registerForKeyChange:@"nearby" onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
            [self reload];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_collectionView reloadData];
    [self setSelectedIndex:_selectedIndex];
    
    if ([PULAccount currentUser])
    {
        [self _observePulls];
    }
    
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
                                                                               
                                                                               [_collectionView reloadData];
                                                                               [self setSelectedIndex:_selectedIndex];
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

#pragma mark - Private
- (void)reload
{
    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        [self _loadDatasourceCompletion:^(NSArray *ds) {
            [_collectionView reloadData];
            [self setSelectedIndex:_selectedIndex];
        }];
        
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

- (void)updateUI
{
    PULUser *user = [_displayedPull otherUser];
    
    if (![_nameLabel.text isEqualToString:user.fullName])
    {
        _nameLabel.text = user.fullName;
    }
    
    _dialogContainer.hidden = YES;
    if (_displayedPull.status == PULPullStatusPulled)
    {
        if (_displayedPull.isNearby)
        {
            _distanceLabel.text = PUL_FORMATTED_DISTANCE_FEET([user distanceFromUser:[PULAccount currentUser]]);
        }
        else
        {
            // display not nearby stuff
            _distanceLabel.text = @"Isn't Nearby";
        }
    }
    else
    {
        // display either waiting on acceptance or waiting for approval
        if (_displayedPull.status == PULPullStatusPending)
        {
            if ([_displayedPull.sendingUser isEqual:[PULAccount currentUser]])
            {
                // waiting on response
                _distanceLabel.text = @"Request Sent";
            }
            else
            {
                // waiting on us
                _distanceLabel.text = @"Invite Requested";
                _dialogContainer.hidden = NO;
                _dialogAcceptButton.hidden = NO;
                _dialogDeclineButton.hidden = NO;
                
                if (_displayedPull.duration == kPullDurationAlways)
                {
                    _dialogMessageLabel.text = [NSString stringWithFormat:@"%@ has requested to always be pulled with you", [_displayedPull otherUser].firstName];
                }
                else
                {
                    _dialogMessageLabel.text = [NSString stringWithFormat:@"%@ has requested a %zd hour pull with you", [_displayedPull otherUser].firstName, _displayedPull.durationHours];
                }
                
            }
        }
        else
        {
            // invalid
            NSAssert(YES, @"probably shouldn't have gotten down here");
            _distanceLabel.text = @"";
        }
    }
    
    [_compassView setPull:_displayedPull];
    
}

#pragma mark - Actions
- (IBAction)ibAccept:(id)sender
{
    [[PULAccount currentUser] acceptPull:_displayedPull];
}

- (IBAction)ibDecline:(id)sender
{
    [[PULAccount currentUser] cancelPull:_displayedPull];
}

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

#pragma mark - Datasource
- (void)_loadDatasourceCompletion:(void(^)(NSArray *ds))completion
{
    PULAccount *acct = [PULAccount currentUser];
    // check if pulls are loaded
    if (acct.pulls.isLoaded)
    {
        // unregister from pulls loaded block if needed
        [acct.pulls unregisterLoadedBlock];
        
        // check if we need to rebuild the datasource
        if ([self _validateDatasource] && _datasource.count == acct.pulls.count && _datasource != nil)
        {
            completion(_datasource);
        }
        else
        {
            // create data source
            [self _buildDatasource];
            
            if (completion)
            {
                completion(_datasource);
            }
        }
    }
    else
    {
        if (acct.pulls)
        {
            [acct.pulls registerLoadedBlock:^(FireMutableArray *objects) {
                [self _loadDatasourceCompletion:completion];
            }];
        }
        else
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self _loadDatasourceCompletion:completion];
            });
        }
    }
}

- (BOOL)_validateDatasource
{
    double lastDistance = 0;
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        double thisDistance = [[pull otherUser] distanceFromUser:[PULAccount currentUser]];
        
        if (thisDistance < lastDistance)
        {
            return NO;
        }
        else
        {
            lastDistance = thisDistance;
        }
    }
    
    return YES;
}

- (void)_buildDatasource
{
    NSMutableArray *ds;
    
    PULAccount *acct = [PULAccount currentUser];
    // get active pulls
    NSMutableArray *activePulls = [[NSMutableArray alloc] initWithArray:acct.pullsPulledNearby];
    [activePulls addObjectsFromArray:acct.pullsPulledFar];
    
    // sort by distance and store
    ds = [[NSMutableArray alloc] initWithArray:[activePulls sortedPullsByDistance]];
    
    // add the rest of pulls
    [ds addObjectsFromArray:acct.pullsPending];
    [ds addObjectsFromArray:acct.pullsWaiting];
    
    // set data source
    _datasource = [[NSArray alloc] initWithArray:ds];
}

#pragma mark Helpers
- (PULUser*)_userForIndex:(NSInteger)index;
{
    PULPull *pull = _datasource[index];
    return [pull otherUser];
}

- (NSInteger)_indexForUser:(PULUser*)aUser;
{
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        PULUser *user = [pull otherUser];
        if ([user isEqual:aUser])
        {
            return i;
        }
    }
    
    return -1;
}

- (NSInteger)_indexForPull:(PULPull*)aPull;
{
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        if ([pull isEqual:aPull])
        {
            return i;
        }
    }
    
    return -1;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (_datasource && _datasource.count > 0)
    {
        // stop observing location for last pull
        if (_displayedPull)
        {
            [[_displayedPull otherUser] stopObservingKeyPath:@"location"];
        }
        
        if (selectedIndex < 0)
        {
            selectedIndex = 0;
        }
        else if (selectedIndex >= _datasource.count)
        {
            selectedIndex = _datasource.count - 1;
        }
        
        _selectedIndex = selectedIndex;
        _displayedPull = _datasource[_selectedIndex];
        
        // deselect all cells
        for (int i = 0; i < _datasource.count; i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            PULPulledUserCollectionViewCell *cell = (PULPulledUserCollectionViewCell*)[_collectionView cellForItemAtIndexPath:indexPath];
            [cell setActive:_selectedIndex == i animated:_selectedIndex == i];
        }
        
        if (_displayedPull.status == PULPullStatusPulled)
        {
            [[_displayedPull otherUser] observeKeyPath:@"location"
                                                 block:^{
                                                     [self updateUI];
                                                 }];
        }
        
        [self updateUI];
    }
}

#pragma mark - UICollectionview
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self setSelectedIndex:indexPath.row];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PULPulledUserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PulledUserCell" forIndexPath:indexPath];
    
    PULPull *pull = _datasource[indexPath.row];
    
    cell.pull = pull;
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _datasource.count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL active = indexPath.row == _selectedIndex;
    [((PULPulledUserCollectionViewCell*)cell) setActive:active animated:NO];

}

@end
