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

#import "PULPullDetailViewController.h"

#import "PULAccount.h"

#import "PULSlideUnwindSegue.h"
#import "PULSlideSegue.h"


const NSInteger kPULPullListNumberOfTableViewSections = 4;

@interface PULPullListViewController ()

@property (nonatomic, strong) IBOutlet UITableView *friendTableView;
@property (nonatomic, strong) IBOutlet UITableView *friendRequestTableView;
@property (nonatomic, strong) IBOutlet UICollectionView *farFriendsCollectionView;
@property (strong, nonatomic) IBOutlet UIImageView *pullRefreshImageView;

@property (nonatomic, strong) PULLoadingIndicator *loadingIndicator;

@property (nonatomic, assign) BOOL refreshing;
@property (nonatomic, assign) BOOL shouldRefresh;

@end

@implementation PULPullListViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reload)
                                                     name:kPULAccountFriendListUpdatedNotification
                                                   object:[PULAccount currentUser]];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(reload)
//                                                     name:kPULAccountFriendUpdatedNotifcation
//                                                   object:[PULAccount currentUser]];
        
    }
    return self;
}

- (void)viewDidLoad
{
    _loadingIndicator = [PULLoadingIndicator indicatorOnView:self.view];
    [_loadingIndicator show];
    
    _pullRefreshImageView.hidden = YES;
    _pullRefreshImageView.animationImages = @[[UIImage imageNamed:@"compass_rotate_1"],
                                              [UIImage imageNamed:@"compass_rotate_2"],
                                              [UIImage imageNamed:@"compass_rotate_3"],
                                              [UIImage imageNamed:@"compass_rotate_4"],
                                              [UIImage imageNamed:@"compass_rotate_5"],
                                              [UIImage imageNamed:@"compass_rotate_6"],
                                              [UIImage imageNamed:@"compass_rotate_7"],
                                              [UIImage imageNamed:@"compass_rotate_8"]];
    _pullRefreshImageView.animationDuration = 0.8f;
    _pullRefreshImageView.animationRepeatCount = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRestoreConnection)
                                                 name:kPULConnectionRestoredNotification
                                               object:nil];
}

- (void)didRestoreConnection
{
//    if (_refreshing)
//    {
//        PULLog(@"was refreshing, trying again");
//        [self _refresh];
//    }
}

- (void)reload
{
    [_loadingIndicator hide];
    
    if (_refreshing)
    {
        [_friendTableView setScrollEnabled:YES];
        _friendTableView.userInteractionEnabled = YES;
        [UIView animateWithDuration:0.2 animations:^{
            _friendTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            _pullRefreshImageView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [_pullRefreshImageView stopAnimating];
            _pullRefreshImageView.hidden = YES;
        }];
        
        _refreshing = NO;
    }
    
    
    PULLog(@"reloading friends tables");
    [_friendTableView reloadData];
//    [_friendRequestTableView reloadData];
}

- (void)_refresh
{
    PULLog(@"is refreshing");
    
    [_friendTableView setScrollEnabled:NO];
    _friendTableView.userInteractionEnabled = NO;
   
    CGFloat height = CGRectGetHeight(_pullRefreshImageView.frame);

    _pullRefreshImageView.hidden = NO;
    _pullRefreshImageView.alpha = 0.0;
    [_pullRefreshImageView startAnimating];
    [UIView animateWithDuration:0.2 animations:^{
        _friendTableView.contentInset = UIEdgeInsetsMake(height, 0, 0, 0);
        _pullRefreshImageView.alpha = 1.0;
    }];
    
    [[PULAccount currentUser] initializeAccount];
    
    _refreshing = YES;
}

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

#pragma mark - Table View Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *friendsArray = [self p_friendArrayForSection:indexPath.section tableView:tableView];
//    PULLog(@"using friends array for cell #%zd: %@", indexPath.row, friendsArray);
    
    PULUser *friend;
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
            case 0: CellId = @"PulledCellID"; break;
            case 1: CellId = @"PullPendingCellID"; break;
            case 2: CellId = @"PullInvitedCellID"; break;
            case 3: CellId = @"UnPulledCellID"; break;
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
            case 0: cellType = PULUserCellTypePulled; break;
            case 1: cellType = PULUserCellTypePending; break;
            case 2: cellType = PULUserCellTypeWaiting; break;
            case 3: cellType = PULUserCellTypeNearby; break;
            default: break;
        }
    }
    cell.type = cellType;
    if (cellType == PULUserCellTypePending || cellType == PULUserCellTypeWaiting)
    {
        cell.bgView.bgColor = [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000];
        
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

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"";
    
    if (tableView == _friendTableView)
    {
        switch (section)
        {
            case 0: title = @"Pulled"; break;
            case 1: title = @"Pending Pulls"; break;
            case 2: title = @"Waiting on Pulls"; break;
            case 3: title = @"Nearby"; break;
            case 4: title = @"Far Away"; break;
                
        }
    }
    else if (tableView == _friendRequestTableView)
    {
        switch (section)
        {
            case 0: title = @"Friend Requests"; break;
            case 1: title = @"Waiting on Friends"; break;
        }
    }
    
    if ([self p_friendArrayForSection:section tableView:tableView].count == 0)
    {
        // don't show a title if nothing in section
        title = nil;
    }
    
    return title;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    PULSectionHeader *header = nil;
    NSString *title;
    
    switch (section)
    {
        case 0: title = @"Pulled"; break;
        case 1: title = @"Pending Pulls"; break;
        case 2: title = @"Waiting on Pulls"; break;
        case 3: title = @"Nearby"; break;
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
            case 0: // pulled users
            {
                PULUser *friend = friendsArray[indexPath.row];
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
            case 1: // pending users
            {
//                [[PULAccount currentUser].pullManager acceptPullFromUser:friend];
                break;
            }
            case 2: // invited users
            {
            //    [[PULAccount currentUser].pullManager unpullUser:friend];
                break;
            }
            case 3:     // unpulled users
            {
//                [[PULAccount currentUser].pullManager sendPullToUser:friend];
                break;
            }
                default:
            {
                break;
            }
        }
    }
//    else if ([tableView isEqual:_friendRequestTableView])
//    {
//        switch (indexPath.section) {
//            case 0: // friend is pending
//            {
//                [[PULAccount currentUser].friendManager acceptFriendRequestFromUser:friend];
//                break;
//            }
//            case 1:  // friend is invited
//            {
//                [[PULAccount currentUser].friendManager unfriendUser:friend];
//                break;
//            }
//            default:
//                break;
//        }
//    }
}

#pragma mark  - scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < -100 && !_refreshing && !_shouldRefresh)
    {
        _shouldRefresh = YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_shouldRefresh)
    {
        [self _refresh];
        
        _shouldRefresh = NO;
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
    [_loadingIndicator show];
    
    _friendTableView.scrollEnabled = YES;
    
    PULUser *friend = cell.user;
    
    PULFriendManager *friendMan = [PULAccount currentUser].friendManager;
    
    if ([friendMan.nearbyFriends containsObject:friend])
    {
        // pull friend
        [[PULAccount currentUser].pullManager sendPullToUser:friend];
    }
    else
    {
        [[PULAccount currentUser].pullManager unpullUser:friend];
        
        [[[UIAlertView alloc] initWithTitle:@"Pull Stopped"
                                    message:@"You are no longer sharing your location with this person"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
    }
    
    [_friendTableView reloadData];
}

- (void)userCellDidDeclinePull:(PULUserCell *)cell
{
    [_loadingIndicator show];
    
     [[PULAccount currentUser].pullManager unpullUser:cell.user];
    
    [_friendTableView reloadData];
    
    [[[UIAlertView alloc] initWithTitle:@"Pull Request Declined"
                                message:@"You are not sharing your location with this person"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles: nil] show];
}

- (void)userCellDidAcceptPull:(PULUserCell *)cell
{
    [_loadingIndicator show];
    
    [[PULAccount currentUser].pullManager acceptPullFromUser:cell.user];
    
    [_friendTableView reloadData];
}

- (void)userCellDidCancelPull:(PULUserCell *)cell
{
    [_loadingIndicator show];
    
    [[PULAccount currentUser].pullManager unpullUser:cell.user];
    
    [_friendTableView reloadData];
    
    [[[UIAlertView alloc] initWithTitle:@"Pull Request Canceled"
                                message:@"You canceled your pull request with this person"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles: nil] show];
}

- (void)userCellDidTapUserImage:(PULUserCell*)cell;
{
    PULPullDetailViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullDetailViewController class])];
    vc.user = cell.user;
    
    PULSlideSegue *segue = [PULSlideSegue segueWithIdentifier:@"SlideToRightSegue"
                                                       source:self
                                                  destination:vc
                                               performHandler:^{
                                               }];
    segue.slideLeft = YES;
    [segue perform];

}

#pragma mark - Private
- (NSArray*)p_friendArrayForSection:(NSUInteger)index tableView:(UITableView*)tableView
{
    NSAssert(index < kPULPullListNumberOfTableViewSections, @"Index out of bounds");
    
    NSArray *retArray = nil;
    PULFriendManager *friendManager = [[PULAccount currentUser] friendManager];
    
    if ([tableView isEqual:_friendTableView])
    {
        switch (index) {
            case 0:
            {
                retArray = friendManager.pulledFriends;
                break;
            }
            case 1:
            {
                retArray = friendManager.pullPendingFriends;
                break;
            }
            case 2:
            {
                retArray = friendManager.pullInvitedFriends;
                break;
            }
            case 3:
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
