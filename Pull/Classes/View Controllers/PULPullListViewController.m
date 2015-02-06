//
//  PULPullListViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullListViewController.h"

#import "PULSectionHeader.h"
#import "PULInfoAlert.h"

#import "PULPullDetailViewController.h"

#import "PULAccount.h"

#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>

const NSInteger kPULPullListNumberOfTableViewSections = 4;

@interface PULPullListViewController () <MFMailComposeViewControllerDelegate>

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
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(reload)
//                                                     name:kPULAccountFriendUpdatedNotifcation
//                                                   object:[PULAccount currentUser]];
        
    }
    return self;
}

- (void)reload
{
    PULLog(@"reloading friends tables");
    [_friendTableView reloadData];
//    [_friendRequestTableView reloadData];
}

#pragma mark - Actions
- (IBAction)ibDebug:(id)sender
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    // get some device info
    UIDevice *dev = [UIDevice currentDevice];
    NSString *model = machineName();
    NSString *version = dev.systemVersion;
    
    NSString *body = [NSString stringWithFormat:@"\n\n\n\n-----------------\nDevice Information\n \
OS version: %@\n\
Model: %@\n\
Version: %@\n\
Build: %@\n\
-----------------", version, model, appVersion, buildNumber];
    
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        [mail setSubject:@"Pull Bug Report"];
        [mail setToRecipients:@[@"debugpull@gmail.com"]];
        [mail setMessageBody:body isHTML:NO];
        mail.mailComposeDelegate = self;
        
        [self presentViewController:mail animated:YES completion:nil];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"No mail account detected"
                                    message:@"Please set up a mail account on your phone before continuing"
                                   delegate:self
                          cancelButtonTitle:@"ok" otherButtonTitles: nil]show];
    }
}

NSString* machineName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

#pragma mark - mail delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
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
        
    }
    else if ([tableView isEqual:_friendRequestTableView])
    {
        switch (indexPath.section) {
            case 0: CellId = @"FriendRequestCellID"; break;
            case 1: CellId = @"FriendInvitedCellID"; break;
            default: break;
        }
    }
    
    if (CellId)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellId];
        
        cell.userImageViewContainer.imageView.image = friend.image;
        cell.userDisplayNameLabel.text = friend.fullName;
        
        cell.user = friend;
    }

    NSAssert(cell != nil, @"We need to have a cell");
    
    cell.delegate = self;
    
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
    else if ([tableView isEqual:_friendRequestTableView])
    {
        switch (indexPath.section) {
            case 0: // friend is pending
            {
                [[PULAccount currentUser].friendManager acceptFriendRequestFromUser:friend];
                break;
            }
            case 1:  // friend is invited
            {
                [[PULAccount currentUser].friendManager unfriendUser:friend];
                break;
            }
            default:
                break;
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
    
    PULUser *friend = cell.user;
    
    NSString *alertTitle = nil;
    
    PULFriendManager *friendMan = [PULAccount currentUser].friendManager;
    
    if ([friendMan.nearbyFriends containsObject:friend])
    {
        // pull friend
        [[PULAccount currentUser].pullManager sendPullToUser:friend];
    }
    else
    {
        [[PULAccount currentUser].pullManager unpullUser:friend];
        
        if ([friendMan.pullPendingFriends containsObject:friend])
        {
            alertTitle = @"pull Declined";
        }
        else if ([friendMan.pullInvitedFriends containsObject:friend])
        {
            alertTitle = @"pull Canceled";
        }
        else if ([friendMan.pulledFriends containsObject:friend])
        {
            alertTitle = @"pull Stopped";
        }
            
    }
    
    if (alertTitle)
    {
        PULInfoAlert *alert = [PULInfoAlert alertWithText:alertTitle onView:self.view];
        [alert show];
    }
    
    [_friendTableView reloadData];
}

- (void)userCellDidDeclinePull:(PULUserCell *)cell
{
     [[PULAccount currentUser].pullManager unpullUser:cell.user];
    
    PULInfoAlert *alert = [PULInfoAlert alertWithText:@"pull Declined" onView:self.view];
    [alert show];
    
    [_friendTableView reloadData];
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
