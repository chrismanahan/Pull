 //
//  PULBlockingViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULBlockingViewController.h"

#import "PULAccount.h"

#import "PULUserCell.h"
#import "PULSectionHeader.h"

@interface PULBlockingViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSMutableArray *blocked;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL dirty;
@property (nonatomic, strong) PULUser *selectedUser;

@end

@implementation PULBlockingViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _friends = [[NSMutableArray alloc] init];
    _blocked = [[NSMutableArray alloc] init];
    
    for (PULUser *user in [PULAccount currentUser].friendManager.allFriends)
    {
        if (user.isBlocked)
        {
            [_blocked addObject:user];
        }
        else
        {
            [_friends addObject:user];
        }
    }
    
    [_tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_dirty)
    {
        [[PULAccount currentUser] initializeAccount];
    }
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
    if (section == 0)
    {
        return _friends.count;
    }
    else
    {
        return _blocked.count;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = indexPath.section == 0 ? @"FriendCell" : @"BlockedCell";
    NSArray *dataSource = indexPath.section == 0 ? _friends : _blocked;
    
    PULUser *user = dataSource[indexPath.row];
    
    PULUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    cell.user = user;
    cell.userImageViewContainer.imageView.image = user.image;
    cell.userDisplayNameLabel.text = user.fullName;
    cell.type = PULUserCellTypeNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    PULSectionHeader *header = nil;
    NSString *title;
    NSArray *dataSource = section == 0 ? _friends : _blocked;
    
    switch (section)
    {
        case 0: title = @"Friends"; break;
        case 1: title = @"Blocked"; break;
    }
    
    // we're doing the section title like this in case we need to add more later
    if (dataSource.count != 0)
    {
        header = [[PULSectionHeader alloc] initWithTitle:title width:CGRectGetWidth(tableView.frame)];
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *dataSource = section == 0 ? _friends : _blocked;
    
    if (dataSource.count != 0)
    {
        return kPULSectionHeaderHeight;
    }
    else
    {
        return 0;
    }
}

#pragma mark - table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSArray *dataSource = indexPath.section == 0 ? _friends : _blocked;
    PULUser *user = dataSource[indexPath.row];
    
    UIAlertView *alert;
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

#pragma mark - alert view delegat
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        if (alertView.tag == 1000)
        {
            // block
            [[PULAccount currentUser].friendManager blockUser:_selectedUser];
            
            [_friends removeObject:_selectedUser];
            [_blocked addObject:_selectedUser];
            
            _dirty = YES;
        }
        else if (alertView.tag == 1001)
        {
            // unblock
            [[PULAccount currentUser].friendManager unBlockUser:_selectedUser];
            
            [_blocked removeObject:_selectedUser];
            [_friends addObject:_selectedUser];
            
            _dirty = YES;
        }
        
        [_tableView reloadData];
    }
    
    _selectedUser = nil;
}

@end
