//
//  PULPullListViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullListViewController.h"

#import "PULSectionHeader.h"

#import "PULUserCell.h"

#import "PULPullDetailViewController.h"

#import "PULAccount.h"

const NSInteger kPULPullListNumberOfTableViewSections = 4;

@interface PULPullListViewController ()

@property (nonatomic, strong) IBOutlet UITableView *friendTableView;
@property (nonatomic, strong) IBOutlet UITableView *friendRequestTableView;
@property (nonatomic, strong) IBOutlet UICollectionView *farFriendsCollectionView;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reload)
                                                     name:kPULAccountFriendUpdatedNotifcation
                                                   object:[PULAccount currentUser]];
        
    }
    return self;
}

- (void)reload
{
    PULLog(@"reloading friends tables");
    [_friendTableView reloadData];
}

#pragma mark - Table View Data Source
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *friendsArray = [self p_friendArrayForSection:indexPath.section tableView:tableView];
    PULUser *friend = friendsArray[indexPath.row];
    
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
        
        if (CellId)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:CellId];
            
            cell.userImageView.image = friend.image;
            cell.userDisplayNameLabel.text = friend.fullName;
        }
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

//- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    PULSectionHeader *header = nil;
//    NSString *title;
//    
//    if (section == 0)
//    {
//        title = @"Near Me";
//    }
//    
//    // we're doing the section title like this in case we need to add more later
//    if (title)
//    {
//        header = [[PULSectionHeader alloc] initWithTitle:title];
//    }
//    
//    return header;
//}

#pragma mark - Table View Delegate 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *friendsArray = [self p_friendArrayForSection:indexPath.section tableView:tableView];
    PULUser *friend = friendsArray[indexPath.row];
    
    if ([tableView isEqual:_friendTableView])
    {
        switch (indexPath.section)
        {
            case 0: // pulled users
            {
                PULPullDetailViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullDetailViewController class])];
                
                [self.navigationController pushViewController:vc animated:YES];
                
                vc.user = friend;

                break;
            }
            case 1: // pending users
            {
                [[PULAccount currentUser].pullManager acceptPullFromUser:friend];
                break;
            }
            case 2: // invited users
            {
                [[PULAccount currentUser].pullManager unpullUser:friend];
                break;
            }
            case 3:     // unpulled users
            {
                [[PULAccount currentUser].pullManager sendPullToUser:friend];
                break;
            }
                default:
            {
                break;
            }
        }
        
    }
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
            default:
                break;
        }
    }
    else
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
