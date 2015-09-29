 //
//  PULBlockingViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULBlockingViewController.h"

#import "PULUserCell.h"


@interface PULBlockingViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UISearchBarDelegate, PULUserCellDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) PULUser *selectedUser;

@property (nonatomic, strong) NSArray *searchFriendsDatasource;
@property (nonatomic, strong) NSArray *searchBlockedDatasource;

@end

@implementation PULBlockingViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

#pragma mark - actions
- (IBAction)ibDone:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - table data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self _dataSourceForSection:section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"UserCell";// indexPath.section == 0 ? @"FriendCell" : @"BlockedCell";
    NSArray *dataSource = [self _dataSourceForSection:indexPath.section];
    
    PULUser *user = dataSource[indexPath.row];
    PULUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    BOOL isUnblockedSection = indexPath.section == 0;
    
    cell.user = user;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryButtonType = isUnblockedSection ? PULUserCellAccessoryButtonTypeLight : PULUserCellAccessoryButtonTypeDark;
    [cell.accessoryButton setTitle:(isUnblockedSection ? @"Block" : @"Unblock")
                          forState:UIControlStateNormal];
    
    cell.delegate = self;
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    
    switch (section)
    {
        case 0: title = @"Not Blocked"; break;
        case 1: title = @"Blocked"; break;
    }
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *dataSource = [self _dataSourceForSection:section];
    
    if (dataSource.count != 0)
    {
        return 30;
    }
    else
    {
        return 0;
    }
}

- (NSArray*)_dataSourceForSection:(NSInteger)section
{
    // TODO: RETURN DATA SOURCE
    return nil;
//    if (!_searchFriendsDatasource)
//    {
//        return section == 0 ? [PULUser currentUser].friends : [PULUser currentUser].blocked;
//    }
//    else
//    {
//        return section == 0 ? _searchFriendsDatasource : _searchBlockedDatasource;
//    }
}

#pragma mark - alert view delegat
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // TODO: ALERT USER WHEN BUTTON TAPPED
//    if (buttonIndex == 1)
//    {
//        if (alertView.tag == 1000)
//        {
//            // block
//            [[PULUser currentUser] blockUser:_selectedUser];
//        }
//        else if (alertView.tag == 1001)
//        {
//            // unblock
//            [[PULUser currentUser] unblockUser:_selectedUser];
//        }
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [_tableView reloadData];
//        });
//
//    }
    
//    _searchBar.text = @"";
//    _searchBlockedDatasource = nil;
//    _searchFriendsDatasource = nil;
    
    if (_searchBar.text.length > 0)
    {
        [self searchBar:_searchBar textDidChange:_searchBar.text];
    }
    _selectedUser = nil;
}

#pragma mark - UISearchBar Delgate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self _reloadDatasourceForSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - Private
#pragma mark Helpers
- (void)_reloadDatasourceForSearch:(NSString*)search
{
    // TODO: reload data source
//    if (!search || search.length == 0)
//    {
//        _searchFriendsDatasource = nil;
//        _searchBlockedDatasource = nil;
//    }
//    else
//    {
//        NSMutableArray *temp = [[NSMutableArray alloc] init];
//        search = search.lowercaseString;
//        
//        for (PULUser *user in [PULUser currentUser].friends)
//        {
//            if ([user.firstName.lowercaseString hasPrefix:search] || [user.lastName.lowercaseString hasPrefix:search] ||
//                [user.fullName.lowercaseString hasPrefix:search])
//            {
//                [temp addObject:user];
//            }
//        }
//        _searchFriendsDatasource = [[NSArray alloc] initWithArray:temp];
//        
//        temp = [[NSMutableArray alloc] init];
//        for (PULUser *user in [PULUser currentUser].blocked)
//        {
//            if ([user.firstName.lowercaseString hasPrefix:search] || [user.lastName.lowercaseString hasPrefix:search] ||
//                [user.fullName.lowercaseString hasPrefix:search])
//            {
//                [temp addObject:user];
//            }
//        }
//        _searchBlockedDatasource = [[NSArray alloc] initWithArray:temp];
//    }
//    
//    [_tableView reloadData];
}

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([_searchBar isFirstResponder])
    {
        [_searchBar resignFirstResponder];
    }
}

#pragma mark - User Cell Delegate
- (void)userCell:(PULUserCell*)cell accessoryButtonTappedForUser:(PULUser *)user
{
    UIAlertView *alert;
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    if (indexPath.section == 0)
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Block"
                                           message:[NSString stringWithFormat:@"Are you sure you want to block %@ on pull?", user.firstName]
                                          delegate:self
                                 cancelButtonTitle:@"No"
                                 otherButtonTitles: @"Block", nil];
        
        alert.tag = 1000;
    }
    else
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Unblock"
                                           message:[NSString stringWithFormat:@"Are you sure you want to unblock %@ on pull?", user.firstName]
                                          delegate:self
                                 cancelButtonTitle:@"No"
                                 otherButtonTitles: @"Unblock", nil] ;
        alert.tag = 1001;
    }
    
    _selectedUser = user;
    
    [alert show];
}

@end
