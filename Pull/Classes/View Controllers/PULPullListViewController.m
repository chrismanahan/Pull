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

const NSInteger kPULAlertEndPullTag = 1001;

@interface PULPullListViewController ()

@property (nonatomic, strong) id pullsLoadedNotification;

@end

@implementation PULPullListViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    _observers = [[NSMutableArray alloc] init];
    
    _pulledUserDatasource = [[PULPulledUserDataSource alloc] init];
    
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
    
    // make sure dialog box colors are correct
    _dialogAcceptButton.backgroundColor = PUL_DarkPurple;
    _dialogDeclineButton.backgroundColor = PUL_DarkPurple;
    _dialogCancelButton.backgroundColor = PUL_DarkPurple;
    _dialogContainer.backgroundColor = PUL_Purple;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self updateUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self reload];
//    [_collectionView reloadData];
//    [self setSelectedIndex:_selectedIndex];
    
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

    if (_pullsLoadedNotification)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_pullsLoadedNotification];
        _pullsLoadedNotification = nil;
    }

    [[PULAccount currentUser].pulls unregisterForAllKeyChanges];
}

#pragma mark
- (void)reload
{
    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        [_pulledUserDatasource loadDatasourceCompletion:^(NSArray *ds) {
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
    @try {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self _highestVisibleIndex]+1 inSection:0];
        [_collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionLeft
                                        animated:YES];

    }
    @catch (NSException *exception) {
        PULLog(@"EXCEPTION WITH SLIDING RIGHT: %@", exception);
    }
}

- (IBAction)ibMoreLeft:(id)sender
{
    @try {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self _lowestVisibleIndex]-1 inSection:0];
        [_collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionRight
                                        animated:YES];
    }
    @catch (NSException *exception) {
        PULLog(@"EXCEPTION WITH SLIDING RIGHT: %@", exception);
    }
    
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

- (IBAction)ibEndPull:(id)sender
{
    NSString *message;
    
    if (_displayedPull.duration == kPullDurationAlways)
    {
        message = [NSString stringWithFormat:@"You currently share your location with %@ whenever they are within %zd ft", [_displayedPull otherUser].firstName, kPULDistanceNearbyFeet];
    }
    else
    {
        message = [NSString stringWithFormat:@"Location sharing will end with %@ in %@", [_displayedPull otherUser].firstName, _displayedPull.durationRemaingString];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"End Now", @"Keep Active", nil];
    
    alert.tag = kPULAlertEndPullTag;
    
    [alert show];
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
    if (_pulledUserDatasource.datasource.count > 1)
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
    if (_pulledUserDatasource.datasource.count > 1)
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
    if (!_pullsLoadedNotification)
    {
        _pullsLoadedNotification = [[NSNotificationCenter defaultCenter] addObserverForName:FireArrayLoadedNotification
                                                                                         object:[PULAccount currentUser].pulls
                                                                                          queue:[NSOperationQueue currentQueue]
                                                                                     usingBlock:^(NSNotification * _Nonnull note) {
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
    PULPull *pull = _pulledUserDatasource.datasource[index];
    return [pull otherUser];
}

- (NSInteger)_indexForUser:(PULUser*)aUser;
{
    for (int i = 0; i < _pulledUserDatasource.datasource.count; i++)
    {
        PULPull *pull = _pulledUserDatasource.datasource[i];
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
    for (int i = 0; i < _pulledUserDatasource.datasource.count; i++)
    {
        PULPull *pull = _pulledUserDatasource.datasource[i];
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
    if (_pulledUserDatasource.datasource && _pulledUserDatasource.datasource.count > 0)
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
        else if (selectedIndex >= _pulledUserDatasource.datasource.count)
        {
            selectedIndex = _pulledUserDatasource.datasource.count - 1;
        }
        
        _selectedIndex = selectedIndex;
        if (_selectedIndex < _pulledUserDatasource.datasource.count)
        {
            _displayedPull = _pulledUserDatasource.datasource[_selectedIndex];
        }
        else
        {
            _displayedPull = nil;
        }
        
        // deselect all cells
        for (int i = 0; i < _pulledUserDatasource.datasource.count; i++)
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
        _pullTimeButton.hidden = YES;
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
    _moreNotificationImageViewLeft.hidden = YES;
    
    // do we have more elements than visible cells
    NSArray *visibleIndexPaths = [_collectionView  indexPathsForVisibleItems];
    if (visibleIndexPaths.count < _pulledUserDatasource.datasource.count && visibleIndexPaths.count != 0)
    {
        // which side do we need to show it on
        
        NSInteger highest = [self _highestVisibleIndex];
        NSInteger lowest = [self _lowestVisibleIndex];
        
        if (lowest != 0)
        {
            _moreNotificationContainerLeft.hidden = NO;
            
            // check if we should show the notification above the arrow
            for (int i = lowest-1; i >= 0; i--)
            {
                PULPull *pull = _pulledUserDatasource.datasource[i];
                if (pull.status == PULPullStatusPending && [pull.receivingUser isEqual:[PULAccount currentUser]])
                {
                    _moreNotificationImageViewLeft.hidden = NO;
                    break;
                }
            }
        }
        else
        {
            _moreNotificationContainerLeft.hidden = YES;
        }
        
        if (highest < _pulledUserDatasource.datasource.count-1)
        {
            _moreNotificationContainerRight.hidden = NO;
            
            // check if we should show the notification above the arrow
            for (int i = highest+1; i < _pulledUserDatasource.datasource.count; i++)
            {
                PULPull *pull = _pulledUserDatasource.datasource[i];
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

- (void)updateDialogWithText:(NSString*)message hide:(BOOL)hideDialog showAcceptDecline:(BOOL)acceptDecline showCancel:(BOOL)cancel
{
    NSAssert(!(acceptDecline && cancel), @"cannot show all three buttons at once");
    
    _dialogContainer.hidden = hideDialog;
    _dialogMessageLabel.hidden = hideDialog;
    
    // show/hide buttons
    _dialogAcceptButton.hidden = !acceptDecline;
    _dialogDeclineButton.hidden = !acceptDecline;
    _dialogCancelButton.hidden = !cancel;
    
    if (acceptDecline || cancel)
    {
        [NSLayoutConstraint activateConstraints:@[_dialogLabelBottomConstraint]];
    }
    else
    {
        [NSLayoutConstraint deactivateConstraints:@[_dialogLabelBottomConstraint]];
    }
    
    // set display label
    _dialogMessageLabel.text = message;
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
    
//    _dialogContainer.hidden = YES;
    NSString *dialogText;
    
    if (_displayedPull.status == PULPullStatusPulled)
    {
        // show pull time button
        _pullTimeButton.hidden = NO;
        [_pullTimeButton setTitle:_displayedPull.durationRemaingString forState:UIControlStateNormal];
        
        switch (_displayedPull.pullDistanceState) {
            case PULPullDistanceStateInaccurate:
            {
                _distanceLabel.text = @"Low Accuracy";
                
                // figure out which dialog text to show
                if ([PULAccount currentUser].hasLowAccuracy)
                {
                    dialogText = @"Because of poor reception, we're having trouble locating you. Enabling WiFi, if it is off, may help.";
                }
                else
                {
                    dialogText = [NSString stringWithFormat:@"We're having trouble locating %@ right now because of poor reception on their phone. Try again in a little bit.", user.firstName];
                }
                break;
            }
            case PULPullDistanceStateFar:
            {
                _distanceLabel.text = @"Isn't Nearby";
                dialogText = [NSString stringWithFormat:@"%@ isn't within %zd ft yet. Don't worry, we'll notify you when they're near", [_displayedPull otherUser].firstName, kPULDistanceNearbyFeet];
                break;
            }
            case PULPullDistanceStateHere:
            {
                _distanceLabel.text = @"Here";
                dialogText = [NSString stringWithFormat:@"%@ should be within %zd feet", [_displayedPull otherUser].firstName, kPULDistanceHereFeet];
                break;
            }
            case PULPullDistanceStateNearby:
            {
                 _distanceLabel.text = PUL_FORMATTED_DISTANCE_FEET([user distanceFromUser:[PULAccount currentUser]]);
                break;
            }
            default:
                break;
        }
        
        [self updateDialogWithText:dialogText
                              hide:(dialogText == nil)
                 showAcceptDecline:NO
                        showCancel:NO];
    }
    else
    {
        _pullTimeButton.hidden = YES;
        
        // display either waiting on acceptance or waiting for approval
        if (_displayedPull.status == PULPullStatusPending)
        {
            if ([_displayedPull initiatedBy:[PULAccount currentUser]])
            {
                // waiting on response
                _distanceLabel.text = @"Request Sent";

                dialogText = [NSString stringWithFormat:@"We've sent %@ a request. We'll notify you when they accept", [_displayedPull otherUser].firstName];
                
                [self updateDialogWithText:dialogText
                                      hide:NO
                         showAcceptDecline:NO
                                showCancel:YES];
            }
            else
            {
                // waiting on us
                _distanceLabel.text = @"Invite Requested";

                if (_displayedPull.duration == kPullDurationAlways)
                {
                    dialogText = [NSString stringWithFormat:@"%@ has requested to always be pulled with you", [_displayedPull otherUser].firstName];
                }
                else
                {
                    dialogText = [NSString stringWithFormat:@"%@ has requested a %zd hour pull with you", [_displayedPull otherUser].firstName, _displayedPull.durationHours];
                }
                
                [self updateDialogWithText:dialogText
                                      hide:NO
                         showAcceptDecline:YES
                                showCancel:NO];
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


#pragma mark -
#pragma mark PROTOCOLS
#pragma mark -

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kPULAlertEndPullTag)
    {
        if (buttonIndex == 0)
        {
            // end active pull
            [[PULAccount currentUser] cancelPull:_displayedPull];
            [self reload];
        }
    }
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
    
    PULPull *pull = _pulledUserDatasource.datasource[indexPath.row];
    
    cell.pull = pull;
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _pulledUserDatasource.datasource.count;
}

#pragma mark UIScrollView Delegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateUI];
}

@end
