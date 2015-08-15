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


@interface PULBlockingViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) PULUser *selectedUser;

@end

@implementation PULBlockingViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
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
        return [PULAccount currentUser].friends.count;
    }
    else
    {
        return [PULAccount currentUser].blocked.count;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = indexPath.section == 0 ? @"FriendCell" : @"BlockedCell";
    FireMutableArray *dataSource = indexPath.section == 0 ? [PULAccount currentUser].friends : [PULAccount currentUser].blocked;
    
    PULUser *user = dataSource[indexPath.row];
    
    PULUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    cell.user = user;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    
    switch (section)
    {
        case 0: title = @"Friends"; break;
        case 1: title = @"Blocked"; break;
    }
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *dataSource = section == 0 ? [PULAccount currentUser].friends : [PULAccount currentUser].blocked;
    
    if (dataSource.count != 0)
    {
        return 30;
    }
    else
    {
        return 0;
    }
}

#pragma mark - table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSArray *dataSource = indexPath.section == 0 ? [PULAccount currentUser].friends : [PULAccount currentUser].blocked;
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
            [[PULAccount currentUser] blockUser:_selectedUser];
        }
        else if (alertView.tag == 1001)
        {
            // unblock
            [[PULAccount currentUser] unblockUser:_selectedUser];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_tableView reloadData];
        });

    }
    
    _selectedUser = nil;
}

@end
