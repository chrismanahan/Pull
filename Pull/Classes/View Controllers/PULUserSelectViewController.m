//
//  PULUserSelectViewController.m
//  Pull
//
//  Created by Chris M on 4/17/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserSelectViewController.h"

#import "PULUserCell.h"

#import "PULAccount.h"

@interface PULUserSelectViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *searchTextField;

@property (strong, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation PULUserSelectViewController


#pragma mark - Actions
- (IBAction)ibCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UITableView Datasource
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"UserCell";
    
    PULUser *user = [PULAccount currentUser].friends[indexPath.row];
    
    PULUserCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    cell.user  = user;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [PULAccount currentUser].friends.count;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
