//
//  PULPullListViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullListViewController.h"

#import "PULSectionHeader.h"
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
@property (nonatomic, strong) IBOutlet UITableView *friendRequestTableView;
@property (nonatomic, strong) IBOutlet UICollectionView *farFriendsCollectionView;

@property (nonatomic, strong) PULLoadingIndicator *loadingIndicator;

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
    _loadingIndicator = [PULLoadingIndicator indicatorOnView:self.view];
    _loadingIndicator.title = @"Loading";
    [_loadingIndicator show];
    
    // inset the table view to give it the slide under header effect
    _tableViewTopContraint.constant = -64;
    _friendTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    
//    __block id loginNotif = [[NSNotificationCenter defaultCenter] addObserverForName:kPULAccountOldLoginFailedNotification
//                                                                              object:[PULAccountOld currentUser]
//                                                                               queue:[NSOperationQueue currentQueue]
//                                                                          usingBlock:^(NSNotification *note) {
//                                                                              [_loadingIndicator hide];
//                                                                              
//                                                                              [[PULAccountOld currentUser] logout];
//                                                                              
//                                                                              UIViewController *login = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULLoginViewController class])];
//                                                                              
//                                                                              PULReverseModal *seg = [PULReverseModal segueWithIdentifier:@"LoginSeg"
//                                                                                                                                   source:self
//                                                                                                                              destination:login
//                                                                                                                           performHandler:^{
//                                                                                                                               ;
//                                                                                                                           }];
//                                                                              
//                                                                              [seg perform];
//                                                                              
//                                                                              [[NSNotificationCenter defaultCenter] removeObserver:loginNotif];
//                                                                          }];
    
    // subscribe to no friends button taps
    //    [[NSNotificationCenter defaultCenter] addObserverForName:PULNoFriendsOverlayButtonTappedSendInvite
    //                                                      object:nil
    //                                                       queue:[NSOperationQueue currentQueue]
    //                                                  usingBlock:^(NSNotification *note) {
    //                                                      PULLog(@"send invite tapped");
    //                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULNoFriendsOverlayButtonTappedCopyLink
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      PULLog(@"copy link tapped");
                                                      
                                                      [UIPasteboard generalPasteboard].string = kPULAppDownloadURL;
                                                  }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULConnectionLostNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [PULNoConnectionView overlayOnView:_friendTableView offset:_friendTableView.contentInset.top];
                                                      
                                                      _friendTableView.scrollEnabled = NO;
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULConnectionRestoredNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [PULNoConnectionView removeOverlayFromView:_friendTableView];
                                                      _friendTableView.scrollEnabled = YES;
                                                  }];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    
//    if ([PULAccountOld currentUser].didLoad)
//    {
//        [_loadingIndicator hide];
//    }
//    
//    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
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
    [_loadingIndicator hide];

    if ([PULLocationUpdater sharedUpdater].hasPermission)
    {
        PULLog(@"reloading friends tables");
        
        if ([PULAccount currentUser].nearbyFriends)
        {
            //            [PULNoFriendsOverlay removeOverlayFromView:_friendTableView];
            
            [_friendTableView reloadData];
        }
        else
        {
            PULLog(@"no friends to display, adding no friends overlay");
            
            //            [PULNoFriendsOverlay overlayOnView:_friendTableView offset:_friendTableView.contentInset.top];
        }
    }
    else
    {
        PULLog(@"not reloading friends table, still need location permission");
    }
}

//- (void)_refresh
//{
//    PULLog(@"is refreshing");
//
//    [_friendTableView setScrollEnabled:NO];
//    _friendTableView.userInteractionEnabled = NO;
//
//    CGFloat height = CGRectGetHeight(_pullRefreshImageView.frame);
//
//    _pullRefreshImageView.hidden = NO;
//    _pullRefreshImageView.alpha = 0.0;
//    [_pullRefreshImageView startAnimating];
//    [UIView animateWithDuration:0.2 animations:^{
//        _friendTableView.contentInset = UIEdgeInsetsMake(height, 0, 0, 0);
//        _pullRefreshImageView.alpha = 1.0;
//    }];
//
//    [[PULAccountOld currentUser] initializeAccount];
//
//    _refreshing = YES;
//}

#pragma mark - Actions
- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender {
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    PULSlideUnwindSegue *segue = [[PULSlideUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    
    if ([fromViewController isKindOfClass:[PULPullDetailViewController class]])
    {
        segue.slideRight = YES;
    }
    return segue;
}

- (IBAction)ibDebug:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"We're Goin' Down!"
                                message:@"Having a problem? Tapping Ok will crash Pull and send us a log of what's going on. None of your personal details will be sent. Thanks for helping us out :)"
                               delegate:self
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@"Ok", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [CrashlyticsKit crash];
    }
}

#pragma mark - Table View Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *friendsArray = [self p_friendArrayForSection:indexPath.section tableView:tableView];
    //    PULLog(@"using friends array for cell #%zd: %@", indexPath.row, friendsArray);
    
    PULUserOld *friend;
    if (indexPath.row < friendsArray.count)
    {
        friend = friendsArray[indexPath.row];
        CLSLog(@"using friend (%@) for cell", friend.uid);
    }
    else
    {
        CLSLog(@"cell row (%zd) out of bounds, friendsArray.count  = %zd", indexPath.row, friendsArray.count);
    }
    
    
    NSString *CellId;
    
    PULUserCell *cell = nil;
    
    if ([tableView isEqual:_friendTableView])
    {
        switch (indexPath.section) {
            case kPULPulledSection: CellId = @"PulledCellID"; break;
            case kPULPendingSection: CellId = @"PullPendingCellID"; break;
            case kPULWaitingSection: CellId = @"PullInvitedCellID"; break;
            case kPULNearbySection: CellId = @"UnPulledCellID"; break;
            default: break;
        }
        
    }
    //    else if ([tableView isEqual:_friendRequestTableView])
    //    {
    //        switch (indexPath.section) {
    //            case 0: CellId = @"FriendRequestCellID"; break;
    //            case 1: CellId = @"FriendInvitedCellID"; break;
    //            default: break;
    //        }
    //    }
    
    if (CellId)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellId];
        
        cell.userImageViewContainer.imageView.image = friend.image;
        cell.userDisplayNameLabel.text = friend.fullName;
        
        cell.user = friend;
    }
    
    NSAssert(cell != nil, @"We need to have a cell");
    
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // determine cell type
    PULUserCellType cellType;
    if ([tableView isEqual:_friendTableView])
    {
        switch (indexPath.section) {
            case kPULPulledSection: cellType = PULUserCellTypePulled; break;
            case kPULPendingSection: cellType = PULUserCellTypePending; break;
            case kPULWaitingSection: cellType = PULUserCellTypeWaiting; break;
            case kPULNearbySection: cellType = PULUserCellTypeNearby; break;
            default: break;
        }
    }
    
    cell.type = cellType;
    //    if (cellType == PULUserCellTypePending || cellType == PULUserCellTypeWaiting)
    //    {
    //        cell.bgView.backgroundColor = [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:0.750];
    //    }
    //    else if (cellType == PULUserCellTypeNearby)
    //    {
    //        cell.bgView.backgroundColor = [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.0];
    //    }
    if (cellType == PULUserCellTypePulled)
    {
        CGFloat alpha = (10 - indexPath.row * 2) / 10.0;
        if (indexPath.row >= 4)
        {
            alpha = (10 - 3 * 2) / 10.0;
        }
        cell.bgView.backgroundColor = [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:alpha];
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kPULPullListNumberOfTableViewSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *array = [self p_friendArrayForSection:section tableView:tableView];
    
    if (array)
    {
        return array.count;
    }
    
    return 0;
}

//- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *title = @"";
//
//    if (tableView == _friendTableView)
//    {
//        switch (section)
//        {
//            case 0: title = @"Pulled"; break;
//            case 1: title = @"Pending Pulls"; break;
//            case 2: title = @"Requested Pulls"; break;
//            case 3: title = @"Nearby"; break;
//            case 4: title = @"Far Away"; break;
//
//        }
//    }
//    else if (tableView == _friendRequestTableView)
//    {
//        switch (section)
//        {
//            case 0: title = @"Friend Requests"; break;
//            case 1: title = @"Waiting on Friends"; break;
//        }
//    }
//
//    if ([self p_friendArrayForSection:section tableView:tableView].count == 0)
//    {
//        // don't show a title if nothing in section
//        title = nil;
//    }
//
//    return title;
//}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    PULSectionHeader *header = nil;
    NSString *title;
    
    switch (section)
    {
        case kPULPulledSection: title = @"Pulled"; break;
        case kPULPendingSection: title = @"Pending Pulls"; break;
        case kPULWaitingSection: title = @"Requested Pulls"; break;
        case kPULNearbySection: title = @"Nearby"; break;
        case 4: title = @"Far Away"; break;
    }
    
    // we're doing the section title like this in case we need to add more later
    if ([self p_friendArrayForSection:section tableView:tableView].count != 0)
    {
        header = [[PULSectionHeader alloc] initWithTitle:title width:CGRectGetWidth(tableView.frame)];
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self p_friendArrayForSection:section tableView:tableView].count != 0)
    {
        return kPULSectionHeaderHeight;
    }
    else
    {
        return 0;
    }
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *friendsArray = [self p_friendArrayForSection:indexPath.section tableView:tableView];
    
    if (indexPath.row > friendsArray.count - 1)
    {
        return;
    }
    
    
    if ([tableView isEqual:_friendTableView])
    {
        switch (indexPath.section)
        {
            case kPULPulledSection: // pulled users
            {
                PULUserOld *friend = friendsArray[indexPath.row];
                PULPullDetailViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullDetailViewController class])];
                vc.user = friend;
                
                PULSlideSegue *segue = [PULSlideSegue segueWithIdentifier:@"SlideToRightSegue"
                                                                   source:self
                                                              destination:vc
                                                           performHandler:^{
                                                           }];
                segue.slideLeft = YES;
                [segue perform];
                
                
                break;
            }
            case kPULPendingSection: // pending users
            {
                break;
            }
            case kPULWaitingSection: // invited users
            {
                break;
            }
            case kPULNearbySection:     // unpulled users
            {
                
                
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

#pragma mark - User cell delegate
- (void)userCellDidAbortPulling:(PULUserCell *)cell
{
    _friendTableView.scrollEnabled = YES;
}

- (void)userCellDidBeginPulling:(PULUserCell *)cell
{
    _friendTableView.scrollEnabled = NO;
}

- (void)userCellDidCompletePulling:(PULUserCell *)cell
{
    _friendTableView.scrollEnabled = YES;
    
    PULUserOld *friend = cell.user;
    
    if (cell.type == PULUserCellTypeNearby)
    {
        _loadingIndicator.title = @"Pulling";
        
        // pull friend
        [[PULAccount currentUser].pullManager sendPullToUser:friend];
    }
    else
    {
        _loadingIndicator.title = @"Stopping Pull";
        
        [[PULAccount currentUser].pullManager unpullUser:friend];
        
        [[[UIAlertView alloc] initWithTitle:@"Pull Stopped"
                                    message:@"You are no longer sharing your location with this person"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
    }
    
    [_loadingIndicator show];
    
    [_friendTableView reloadData];
}

- (void)userCellDidDeclinePull:(PULUserCell *)cell
{
    _loadingIndicator.title = @"Declining Pull";
    [_loadingIndicator show];
    
    [[PULAccountOld currentUser].pullManager unpullUser:cell.user];
    
    [_friendTableView reloadData];
    
    [[[UIAlertView alloc] initWithTitle:@"Pull Request Declined"
                                message:@"You are not sharing your location with this person"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles: nil] show];
}

- (void)userCellDidAcceptPull:(PULUserCell *)cell
{
    _loadingIndicator.title = @"Accepting Pull";
    [_loadingIndicator show];
    
    [[PULAccountOld currentUser].pullManager acceptPullFromUser:cell.user];
    
    [_friendTableView reloadData];
}

- (void)userCellDidCancelPull:(PULUserCell *)cell
{
    _loadingIndicator.title = @"Canceling Pull";
    [_loadingIndicator show];
    
    [[PULAccountOld currentUser].pullManager unpullUser:cell.user];
    
    [_friendTableView reloadData];
    
    [[[UIAlertView alloc] initWithTitle:@"Pull Request Canceled"
                                message:@"You canceled your pull request with this person"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles: nil] show];
}

#pragma mark - Private
- (NSArray*)p_friendArrayForSection:(NSUInteger)index tableView:(UITableView*)tableView
{
    NSAssert(index < kPULPullListNumberOfTableViewSections, @"Index out of bounds");
    
    NSArray *retArray = nil;
    PULFriendManager *friendManager = [[PULAccountOld currentUser] friendManager];
    
    if ([tableView isEqual:_friendTableView])
    {
        switch (index) {
            case kPULPulledSection:
            {
                retArray = friendManager.pulledFriends;
                break;
            }
            case kPULPendingSection:
            {
                retArray = friendManager.pullPendingFriends;
                break;
            }
            case kPULWaitingSection:
            {
                retArray = friendManager.pullInvitedFriends;
                break;
            }
            case kPULNearbySection:
            {
                retArray = friendManager.nearbyFriends;
                break;
            }
            case 4:
            {
                retArray = friendManager.allFriends;
                break;
            }
            default:
                break;
        }
    }
    else if ([tableView isEqual:_friendRequestTableView])
    {
        switch (index) {
            case 0:
            {
                retArray = friendManager.pendingFriends;
                break;
            }
            case 1:
            {
                retArray = friendManager.invitedFriends;
                break;
            }
            default:
                break;
        }
        
    }
    
    return retArray;
}

@end
