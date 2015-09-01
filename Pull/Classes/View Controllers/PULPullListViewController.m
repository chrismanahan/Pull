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
#import "PULLoginViewController.h"
#import "PULUserSelectViewController.h"

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"
#import "PULReverseModal.h"

#import "PULPulledUserCollectionViewCell.h"

#import "CALayer+Animations.h"
#import "NSArray+Sorting.h"

#import "PULPulledUserDataSource.h"

const NSInteger kPULPullListNumberOfTableViewSections = 4;

const NSInteger kPULPulledNearbySection = 1;
const NSInteger kPULPendingSection = 0;
const NSInteger kPULWaitingSection = 3;
const NSInteger kPULPulledFarSection = 2;

@interface PULPullListViewController () <UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet PULCompassView *compassView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIView *dialogContainer;
@property (strong, nonatomic) IBOutlet UIButton *dialogAcceptButton;
@property (strong, nonatomic) IBOutlet UIButton *dialogDeclineButton;
@property (strong, nonatomic) IBOutlet UILabel *dialogMessageLabel;
@property (strong, nonatomic) IBOutlet UIButton *dialogCancelButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *compassUserImageViewTopConstraint;
@property (strong, nonatomic) IBOutlet UIImageView *cutoutImageView;
@property (strong, nonatomic) IBOutlet UIImageView *moreNotificationImageViewRight;
@property (strong, nonatomic) IBOutlet UIView *moreNotificationContainerRight;
@property (strong, nonatomic) IBOutlet UIView *moreNotificationContainerLeft;

@property (nonatomic, strong) PULPull *displayedPull;
@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, strong) NSMutableArray *observers;

@end

@implementation PULPullListViewController

#pragma mark - View Lifecycle
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
    if (height < 500)
    {
        _compassUserImageViewTopConstraint.constant += 12;
    }
    if (height > 600)
    {
        _compassUserImageViewTopConstraint.constant -= 10;
    }
    if (height > 700)
    {
        _compassUserImageViewTopConstraint.constant -= 10;
    }
    
    _collectionView.layer.masksToBounds = NO;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateUI];
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

#pragma mark
- (void)reload
{
    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        [[PULPulledUserDataSource sharedDataSource] loadDatasourceCompletion:^(NSArray *ds) {
            [_collectionView reloadData];
            [self setSelectedIndex:_selectedIndex];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self updateUI];
            });
        }];
    }
    else
    {
        PULLog(@"not reloading friends table, still need location permission");
    }
    
}


#pragma mark - Actions
- (IBAction)ibMoreRight:(id)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self _highestVisibleIndex]+1 inSection:0];
    [_collectionView scrollToItemAtIndexPath:indexPath
                            atScrollPosition:UICollectionViewScrollPositionRight
                                    animated:YES];
}

- (IBAction)ibMoreLeft:(id)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self _lowestVisibleIndex]-1 inSection:0];
    [_collectionView scrollToItemAtIndexPath:indexPath
                            atScrollPosition:UICollectionViewScrollPositionNone
                                    animated:YES];
    
}

- (IBAction)ibAccept:(id)sender
{
    [[PULAccount currentUser] acceptPull:_displayedPull];
}

- (IBAction)ibDecline:(id)sender
{
    [[PULAccount currentUser] cancelPull:_displayedPull];
    [self reload];
}

- (IBAction)ibCancel:(id)sender
{
    [[PULAccount currentUser] cancelPull:_displayedPull];
    [self reload];
}

- (IBAction)ibSendPull:(id)sender
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULUserSelectViewController class])];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender {}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    PULSlideUnwindSegue *segue = [[PULSlideUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    
    return segue;
}
#pragma mark Gestures
- (void)_swipeLeft
{
    if ([PULPulledUserDataSource sharedDataSource].datasource.count > 1)
    {
        [self setSelectedIndex:_selectedIndex + 1];
        
        NSIndexPath *path = [NSIndexPath indexPathForItem:_selectedIndex inSection:0];
        [_collectionView scrollToItemAtIndexPath:path
                                atScrollPosition:UICollectionViewScrollPositionNone
                                        animated:YES];
    }
}

- (void)_swipeRight
{
    if ([PULPulledUserDataSource sharedDataSource].datasource.count > 1)
    {
        [self setSelectedIndex:_selectedIndex - 1];
        
        NSIndexPath *path = [NSIndexPath indexPathForItem:_selectedIndex inSection:0];
        [_collectionView scrollToItemAtIndexPath:path
                                atScrollPosition:UICollectionViewScrollPositionNone
                                        animated:YES];
    }
}
#pragma mark - Helpers
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


- (void)_unsetDisplayedPull
{
    [self setSelectedIndex:_selectedIndex - 1];
}

- (PULUser*)_userForIndex:(NSInteger)index;
{
    PULPull *pull = [PULPulledUserDataSource sharedDataSource].datasource[index];
    return [pull otherUser];
}

- (NSInteger)_indexForUser:(PULUser*)aUser;
{
    for (int i = 0; i < [PULPulledUserDataSource sharedDataSource].datasource.count; i++)
    {
        PULPull *pull = [PULPulledUserDataSource sharedDataSource].datasource[i];
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
    for (int i = 0; i < [PULPulledUserDataSource sharedDataSource].datasource.count; i++)
    {
        PULPull *pull = [PULPulledUserDataSource sharedDataSource].datasource[i];
        if ([pull isEqual:aPull])
        {
            return i;
        }
    }
    
    return -1;
}

- (NSInteger)_highestVisibleIndex
{
    return [[self _lowestHighestVisibleIndexes][1] integerValue];
}

- (NSInteger)_lowestVisibleIndex
{
    return [[self _lowestHighestVisibleIndexes][0] integerValue];
}

- (NSArray*)_lowestHighestVisibleIndexes
{
    NSArray *visibleIndexPaths = [_collectionView  indexPathsForVisibleItems];
    
    NSInteger highest = 0, lowest = NSIntegerMax;
    for (NSIndexPath *path in visibleIndexPaths)
    {
        if (path.row > highest)
        {
            highest = path.row;
        }
        if (path.row < lowest)
        {
            lowest = path.row;
        }
    }
    
    return @[@(lowest), @(highest)];
}


- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if ([PULPulledUserDataSource sharedDataSource].datasource && [PULPulledUserDataSource sharedDataSource].datasource.count > 0)
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
        else if (selectedIndex >= [PULPulledUserDataSource sharedDataSource].datasource.count)
        {
            selectedIndex = [PULPulledUserDataSource sharedDataSource].datasource.count - 1;
        }
        
        _selectedIndex = selectedIndex;
        if (_selectedIndex < [PULPulledUserDataSource sharedDataSource].datasource.count)
        {
            _displayedPull = [PULPulledUserDataSource sharedDataSource].datasource[_selectedIndex];
        }
        else
        {
            _displayedPull = nil;
        }
        
        // deselect all cells
        for (int i = 0; i < [PULPulledUserDataSource sharedDataSource].datasource.count; i++)
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
    else
    {
        _displayedPull = nil;
        [self updateUI];
    }
}


#pragma mark UI Helpers
- (void)_showNoActivePulls:(BOOL)show
{
    if (show)
    {
        [self _setNameLabel:nil];
        [_compassView setPull:nil];
        _dialogContainer.hidden = YES;
        _nameLabel.textColor = PUL_LightPurple;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPULCompassSmileyWinkDuration / 1.725 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!_displayedPull)
            {
                _nameLabel.text = @"tap + to get started";
            }
            else
            {
                [self _showNoActivePulls:NO];
            };
        });
    }
    else
    {
        _nameLabel.textColor = [UIColor whiteColor];
    }
    
    _cutoutImageView.hidden = !show;
}

- (void)_setNameLabel:(NSString*)name
{
    if (!name)
    {
        // show cutout
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.textColor = PUL_Purple;
        _nameLabel.text = @"no active pulls";
        _distanceLabel.hidden = YES;
    }
    else
    {
        _nameLabel.backgroundColor = PUL_Purple;
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.text = name;
        _distanceLabel.hidden = NO;
    }
}

- (void)_toggleMoreArrow
{
    _moreNotificationImageViewRight.hidden = YES;
    
    // do we have more elements than visible cells
    NSArray *visibleIndexPaths = [_collectionView  indexPathsForVisibleItems];
    if (visibleIndexPaths.count < [PULPulledUserDataSource sharedDataSource].datasource.count && visibleIndexPaths.count != 0)
    {
        // which side do we need to show it on
        
        NSInteger highest = [self _highestVisibleIndex];
        NSInteger lowest = [self _lowestVisibleIndex];
        
        if (lowest != 0)
        {
            _moreNotificationContainerLeft.hidden = NO;
        }
        else
        {
            _moreNotificationContainerLeft.hidden = YES;
        }
        
        if (highest < [PULPulledUserDataSource sharedDataSource].datasource.count-1)
        {
            _moreNotificationContainerRight.hidden = NO;
            
            // check if we should show the notification above the arrow
            for (int i = highest+1; i < [PULPulledUserDataSource sharedDataSource].datasource.count; i++)
            {
                PULPull *pull = [PULPulledUserDataSource sharedDataSource].datasource[i];
                if (pull.status == PULPullStatusPending && [pull.receivingUser isEqual:[PULAccount currentUser]])
                {
                    _moreNotificationImageViewRight.hidden = NO;
                    break;
                }
            }
        }
        else
        {
            _moreNotificationContainerRight.hidden = YES;
        }
    }
    else
    {
        _moreNotificationContainerRight.hidden = YES;
        _moreNotificationContainerLeft.hidden = YES;
    }
}

- (void)updateUI
{
    if (!_displayedPull)
    {
        [self _showNoActivePulls:YES];
        
        return;
    }
    // clean up from showing no active if needed
    [self _showNoActivePulls:NO];
    
    PULUser *user = [_displayedPull otherUser];
    
    if (![_nameLabel.text isEqualToString:user.fullName])
    {
        [self _setNameLabel:user.fullName];
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
            
            _dialogContainer.hidden = NO;
            _dialogAcceptButton.hidden = YES;
            _dialogDeclineButton.hidden = YES;
            _dialogCancelButton.hidden = YES;
            _dialogMessageLabel.text = [NSString stringWithFormat:@"%@ isn't within %zd ft yet. Don't worry, we'll notify you when they're near", [_displayedPull otherUser].firstName, kPULDistanceNearbyFeet];
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
                
                _dialogContainer.hidden = NO;
                _dialogAcceptButton.hidden = YES;
                _dialogDeclineButton.hidden = YES;
                _dialogCancelButton.hidden = NO;
                _dialogMessageLabel.text = [NSString stringWithFormat:@"We've sent %@ a request. We'll notify you when they accept", [_displayedPull otherUser].firstName];
            }
            else
            {
                // waiting on us
                _distanceLabel.text = @"Invite Requested";
                _dialogContainer.hidden = NO;
                _dialogAcceptButton.hidden = NO;
                _dialogDeclineButton.hidden = NO;
                _dialogCancelButton.hidden = YES;
                
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
    
    // determine if we need to show the more arrow
    [self _toggleMoreArrow];
    
    [_compassView setPull:_displayedPull];
}


#pragma mark - UICollectionView
#pragma mark UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self setSelectedIndex:indexPath.row];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL active = indexPath.row == _selectedIndex;
    [((PULPulledUserCollectionViewCell*)cell) setActive:active animated:NO];
}

#pragma mark UICollectionView DataSource
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PULPulledUserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PulledUserCell" forIndexPath:indexPath];
    
    PULPull *pull = [PULPulledUserDataSource sharedDataSource].datasource[indexPath.row];
    
    cell.pull = pull;
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [PULPulledUserDataSource sharedDataSource].datasource.count;
}

#pragma mark UIScrollView Delegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateUI];
}

@end
