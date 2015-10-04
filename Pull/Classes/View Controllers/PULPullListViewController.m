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

#import "PULLoginViewController.h"
#import "PULUserSelectViewController.h"

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"
#import "PULReverseModal.h"

#import "PULPulledUserCollectionViewCell.h"

#import "PULSoundPlayer.h"

#import "CALayer+Animations.h"
#import "NSArray+Sorting.h"

#import "PULParseMiddleMan.h"
#import "PULLocationUpdater.h"

const NSInteger kPULAlertEndPullTag = 1001;

NSString * const kPULDialogButtonTextAccept = @"Accept";
NSString * const kPULDialogButtonTextCancel = @"Cancel";
NSString * const kPULDialogButtonTextDecline = @"Decline";
NSString * const kPULDialogButtonTextEnableLocation = @"Enable Location";

@interface PULPullListViewController ()

@property (nonatomic, strong) id pullsLoadedNotification;

@property (nonatomic, strong) PULSoundPlayer *soundPlayer;

@property (nonatomic, assign) BOOL isReloading;

@property (nonatomic, strong) NSArray *pullsDatasource;

@property (nonatomic, assign) BOOL finishedSetup;

@end

@implementation PULPullListViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
    
    _observers = [[NSMutableArray alloc] init];
    
    // initialize sound player
    _soundPlayer = [[PULSoundPlayer alloc] init];
    
    // set initial text for dialog buttons
    [_dialogAcceptButton setTitle:kPULDialogButtonTextAccept forState:UIControlStateNormal];
    [_dialogCancelButton setTitle:kPULDialogButtonTextCancel forState:UIControlStateNormal];
    [_dialogDeclineButton setTitle:kPULDialogButtonTextDecline forState:UIControlStateNormal];
    
    
    
//    id loginObs = [[NSNotificationCenter defaultCenter] addObserverForName:PULAccountDidLoginNotification
//                                                                    object:nil
//                                                                     queue:[NSOperationQueue mainQueue]
//                                                                usingBlock:^(NSNotification *note) {
//                                                                    [self _observePulls];
//                                                                    
//                                                                    [[NSNotificationCenter defaultCenter] removeObserver:loginObs];
//                                                                }];
    
    // subscribe to disabled location updates
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationPermissionsDeniedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      //                                                      [PULLocationOverlay overlayOnView:self.view];
                                                      [self showNoLocation:YES];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationPermissionsGrantedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      //                                                      [PULLocationOverlay removeOverlayFromView:self.view];
                                                      if (_finishedSetup)
                                                      {
                                                          [self reload];
                                                      }
                                                      
                                                  }];
    
//    [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification
//                                                      object:nil
//                                                       queue:[NSOperationQueue currentQueue]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      PULLog(@"received access token change notif, reloading table");
//                                                      [self reload];
//                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULLocationUpdatedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      if (!_finishedSetup)
                                                      {
                                                          _finishedSetup = YES;
                                                          
                                                          [self finishSetup];
                                                          [self reload];
                                                      }
                                                      
                                                      [self updateUI];
                                                  }];
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_pullsLoadedNotification)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_pullsLoadedNotification];
        _pullsLoadedNotification = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_finishedSetup)
    {
        [self reload];
    }
}

- (void)finishSetup
{
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self reload];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULParseObjectsUpdatedPullsNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      // TODO: check if foreground
                                                      [self reload];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULParseObjectsUpdatedLocationsNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      // TODO: check if foreground
                                                      [self reload];
                                                  }];

    PULUser *user = [PULUser currentUser];
    if (user && [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        user.isInForeground = YES;
        [user saveInBackground];
    }

}

#pragma mark
- (void)reload
{
    if (!_isReloading)
    {
        self.isReloading = YES;
        [self showNoLocation:![PULLocationUpdater sharedUpdater].hasPermission];
      
        [[PULParseMiddleMan sharedInstance] getPullsInBackground:^(NSArray<PULPull *> * _Nullable pulls, NSError * _Nullable error) {
            _pullsDatasource = pulls;
            
            [_collectionView reloadData];
            [self updateUI];
            [self setSelectedIndex:_selectedIndex];
            self.isReloading = NO;
        }];
    }
}

- (void)setIsReloading:(BOOL)isReloading
{
    _isReloading = isReloading;
    
    // TODO: display activity indicator
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

- (IBAction)ibDialogButton:(UIButton*)sender
{
    if ([sender.titleLabel.text isEqual:kPULDialogButtonTextAccept])
    {
        [[PULParseMiddleMan sharedInstance] acceptPull:_displayedPull];
        [self reload];
    }
    else if ([sender.titleLabel.text isEqual:kPULDialogButtonTextCancel] ||
             [sender.titleLabel.text isEqual:kPULDialogButtonTextDecline])
    {
        [[PULParseMiddleMan sharedInstance] deletePull:_displayedPull];
        [self reload];
    }
    else if ([sender.titleLabel.text isEqual:kPULDialogButtonTextEnableLocation])
    {
        BOOL canGoToSettings = (UIApplicationOpenSettingsURLString != NULL);
        if (canGoToSettings)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
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
    if (_pullsDatasource.count > 1)
    {
        [self setSelectedIndex:_selectedIndex + 1];
        
        NSIndexPath *path = [NSIndexPath indexPathForItem:_selectedIndex inSection:0];
        [_collectionView scrollToItemAtIndexPath:path
                                atScrollPosition:UICollectionViewScrollPositionNone
                                        animated:YES];
        
        [_soundPlayer playBoop];
    }
}

- (void)_swipeRight
{
    if (_pullsDatasource.count > 1)
    {
        [self setSelectedIndex:_selectedIndex - 1];
        
        NSIndexPath *path = [NSIndexPath indexPathForItem:_selectedIndex inSection:0];
        [_collectionView scrollToItemAtIndexPath:path
                                atScrollPosition:UICollectionViewScrollPositionNone
                                        animated:YES];
        
        [_soundPlayer playBoop];
    }
}
#pragma mark - Helpers
//- (void)_observePulls
//{
//    if (!_pullsLoadedNotification)
//    {
//        _pullsLoadedNotification = [[NSNotificationCenter defaultCenter] addObserverForName:FireArrayLoadedNotification
//                                                                                     object:[PULUser currentUser].pulls
//                                                                                      queue:[NSOperationQueue currentQueue]
//                                                                                 usingBlock:^(NSNotification *note) {
//                                                                                     [self reload];
//                                                                                 }];
//    }
//    
//    if (![[PULUser currentUser].pulls isRegisteredForKeyChange:@"status"])
//    {
//        [[PULUser currentUser].pulls registerForKeyChange:@"status" onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
//            [self reload];
//            
//            if (((PULPull*)object).status == PULPullStatusPulled && ![PULLocationUpdater sharedUpdater].isTracking)
//            {
//                [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
//            }
//        }];
//    }
//    
//    if (![[PULUser currentUser].pulls isRegisteredForKeyChange:@"nearby"])
//    {
//        [[PULUser currentUser].pulls registerForKeyChange:@"nearby" onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
//            [self reload];
//        }];
//    }
//    
//    if (![[PULUser currentUser] isObservingKeyPath:@"location"])
//    {
//        [[PULUser currentUser] observeKeyPath:@"location" block:^{
//            [self updateUI];
//        }];
//    }
//    
//    if (![[PULUser currentUser] isObservingKeyPath:@"hasMovedSinceLastLocationUpdate"])
//    {
//        [[PULUser currentUser] observeKeyPath:@"hasMovedSinceLastLocationUpdate" block:^{
//            [self updateUI];
//        }];
//    }
//}


- (void)_unsetDisplayedPull
{
    [self setSelectedIndex:_selectedIndex - 1];
}

- (PULUser*)_userForIndex:(NSInteger)index;
{
    PULPull *pull = _pullsDatasource[index];
    return [pull otherUser];
}

- (NSInteger)_indexForUser:(PULUser*)aUser;
{
    for (int i = 0; i < _pullsDatasource.count; i++)
    {
        PULPull *pull = _pullsDatasource[i];
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
    for (int i = 0; i < _pullsDatasource.count; i++)
    {
        PULPull *pull = _pullsDatasource[i];
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
    // stop observing location for last pull
    if (_displayedPull)
    {
        // TODO: STOP OBSERVING LOCATION
        [[PULParseMiddleMan sharedInstance] stopObservingChangesInLocationForUser:[_displayedPull otherUser]];
    }
    
    NSArray *pulls = _pullsDatasource;
    if (pulls && pulls.count > 0)
    {
        if (selectedIndex < 0)
        {
            selectedIndex = 0;
        }
        else if (selectedIndex >= pulls.count)
        {
            selectedIndex = pulls.count - 1;
        }
        
        _selectedIndex = selectedIndex;
        if (_selectedIndex < _pullsDatasource.count)
        {
            _displayedPull = pulls[_selectedIndex];
        }
        else
        {
            _displayedPull = nil;
        }
        
        // deselect all cells
        for (int i = 0; i < pulls.count; i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            PULPulledUserCollectionViewCell *cell = (PULPulledUserCollectionViewCell*)[_collectionView cellForItemAtIndexPath:indexPath];
            [cell setActive:_selectedIndex == i animated:_selectedIndex == i];
        }
        
        // start observing the location for this pull
        if (_displayedPull.status == PULPullStatusPulled)
        {
            [[PULParseMiddleMan sharedInstance]
             observeChangesInLocationForUser:[_displayedPull otherUser]
             interval:kPULPollTimeActive
             target:self
             selecter:@selector(updateUI)];
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
- (void)showNoLocation:(BOOL)show
{
    _addPullButton.enabled = !show;
    _pullTimeButton.hidden = show;
    
    if (show)
    {
        BOOL canGoToSettings = (UIApplicationOpenSettingsURLString != NULL);
        
        // TODO: CANCEL ALL PULLS
//        [[PULUser currentUser] cancelAllPulls];
        [self _setNameLabel:@"Location Disabled" active:NO];
        [_compassView showNoLocation];
        
        [self updateDialogWithText:@"Please give pull access to your location in settings" hide:NO showAcceptDecline:NO showCancel:NO location:canGoToSettings];
    }
    else
    {
        [self updateDialogWithText:nil hide:YES showAcceptDecline:NO showCancel:NO location:NO];
    }
}

- (void)_showNoActivePulls:(BOOL)show
{
    if (show && [PULLocationUpdater sharedUpdater].hasPermission)
    {
        [self _setNameLabel:@"No Active Pulls" active:NO];
        [_compassView setPull:nil];
        _pullTimeButton.hidden = YES;
        _dialogContainer.hidden = YES;
        
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
    
    _cutoutImageView.hidden = !show;
}

- (void)_setNameLabel:(NSString*)name active:(BOOL)active
{
    if (!active)
    {
        // show cutout
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.textColor = PUL_LightPurple;
        _distanceLabel.hidden = YES;
    }
    else
    {
        _nameLabel.backgroundColor = PUL_Purple;
        _nameLabel.textColor = [UIColor whiteColor];
        _distanceLabel.hidden = NO;
    }
    
    _nameLabel.text = name;
}

- (void)_toggleMoreArrow
{
    _moreNotificationImageViewRight.hidden = YES;
    _moreNotificationImageViewLeft.hidden = YES;
    
    // do we have more elements than visible cells
    NSArray *visibleIndexPaths = [_collectionView  indexPathsForVisibleItems];
    if (visibleIndexPaths.count < _pullsDatasource.count && visibleIndexPaths.count != 0)
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
                PULPull *pull = _pullsDatasource[i];
                if (pull.status == PULPullStatusPending && [pull.receivingUser isEqual:[PULUser currentUser]])
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
        
        if (highest < _pullsDatasource.count-1)
        {
            _moreNotificationContainerRight.hidden = NO;
            
            // check if we should show the notification above the arrow
            for (int i = highest+1; i < _pullsDatasource.count; i++)
            {
                PULPull *pull = _pullsDatasource[i];
                if (pull.status == PULPullStatusPending && [pull.receivingUser isEqual:[PULUser currentUser]])
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

// FIXME: dialog box needs some serious refactoring
- (void)updateDialogWithText:(NSString*)message hide:(BOOL)hideDialog showAcceptDecline:(BOOL)acceptDecline showCancel:(BOOL)cancel location:(BOOL)location
{
    NSAssert(!(acceptDecline && cancel), @"cannot show all three buttons at once");
    NSAssert(!(cancel && location), @"can't have cancel and location button in use at the same time");
    
    _dialogContainer.hidden = hideDialog;
    _dialogMessageLabel.hidden = hideDialog;
    
    // show/hide buttons
    _dialogAcceptButton.hidden = !acceptDecline;
    _dialogDeclineButton.hidden = !acceptDecline;
    _dialogCancelButton.hidden = !cancel && !location;
    
    if (cancel)
    {
        [_dialogCancelButton setTitle:kPULDialogButtonTextCancel forState:UIControlStateNormal];
    }
    else if (location)
    {
        [_dialogCancelButton setTitle:kPULDialogButtonTextEnableLocation forState:UIControlStateNormal];
    }
    
    
    if (acceptDecline || cancel || location)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSLayoutConstraint activateConstraints:@[_dialogLabelBottomConstraint]];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSLayoutConstraint deactivateConstraints:@[_dialogLabelBottomConstraint]];
        });
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
        [self _setNameLabel:user.fullName active:YES];
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
                if ([PULUser currentUser].location.isLowAccuracy)
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
            case PULPullDistanceStateAlmostHere:
            {
                _distanceLabel.text = @"Nearby";
                dialogText = [NSString stringWithFormat:@"%@ should be within %zd feet", [_displayedPull otherUser].firstName, kPULDistanceAlmostHereFeet];
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
                _distanceLabel.text = PUL_FORMATTED_DISTANCE_FEET([user distanceFromUser:[PULUser currentUser]]);
                break;
            }
            default:
                break;
        }
        
//        _debug_accuracyLabel.text = [NSString stringWithFormat:@"%.2f", [_displayedPull otherUser].locationAccuracy];
//        _debug_acctAccuracyLabel.text = [NSString stringWithFormat:@"%.2f", [PULUser currentUser].locationAccuracy];;
        
        [self updateDialogWithText:dialogText
                              hide:(dialogText == nil)
                 showAcceptDecline:NO
                        showCancel:NO
                          location:NO];
        
        // TODO: DEBUG
        //        _dialogContainer.hidden = NO;
        //        _dialogMessageLabel.text = [NSString stringWithFormat:@"%@\n%@", [PULUser currentUser].location, user.location];
        _distanceLabel.text = PUL_FORMATTED_DISTANCE_FEET([user distanceFromUser:[PULUser currentUser]]);
    }
    else
    {
        _pullTimeButton.hidden = YES;
        
        // display either waiting on acceptance or waiting for approval
        if (_displayedPull.status == PULPullStatusPending)
        {
            if ([_displayedPull initiatedBy:[PULUser currentUser]])
            {
                // waiting on response
                _distanceLabel.text = @"Request Sent";
                
                dialogText = [NSString stringWithFormat:@"We've sent %@ a request. We'll notify you when they accept", [_displayedPull otherUser].firstName];
                
                [self updateDialogWithText:dialogText
                                      hide:NO
                         showAcceptDecline:NO
                                showCancel:YES
                                  location:NO];
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
                                showCancel:NO
                                  location:NO];
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
            [[PULParseMiddleMan sharedInstance] deletePull:_displayedPull];
            [self reload];
        }
    }
}

#pragma mark - UICollectionView
#pragma mark UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_soundPlayer playBoop];
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
    
    PULPull *pull = _pullsDatasource[indexPath.row];
    
    cell.pull = pull;
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _pullsDatasource.count;
}

#pragma mark UIScrollView Delegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateUI];
}

@end
