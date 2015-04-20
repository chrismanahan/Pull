//
//  PULUserSelectViewController.m
//  Pull
//
//  Created by Chris M on 4/17/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserSelectViewController.h"
#import "PULNewPullViewController.h"

#import "PULUserCell.h"

#import "PULAccount.h"

#import "PULSlideLeftSegue.h"
#import "PULSlideUnwindSegue.h"

@interface PULUserSelectViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *searchTextField;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *dataSource;

@property (strong, nonatomic) id obsPullCount;

@end

@implementation PULUserSelectViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (([PULAccount currentUser].pulls.isLoaded && [PULAccount currentUser].pulls.count > 0) || [PULAccount currentUser].pulls.count == 0)
    {
        _dataSource = [[PULAccount currentUser] sortedArray:[PULAccount currentUser].unpulledFriends];
        [_tableView reloadData];
    }
    
    [[PULAccount currentUser].pulls registerLoadedBlock:^(FireMutableArray *objects) {
        _dataSource = [[PULAccount currentUser] sortedArray:[PULAccount currentUser].unpulledFriends];
        [_tableView reloadData];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[PULAccount currentUser].pulls unregisterLoadedBlock];
}

#pragma mark - Actions
- (IBAction)ibCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender {}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    PULSlideUnwindSegue *segue = [[PULSlideUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    
    segue.slideRight = YES;
    return segue;
}

#pragma mark -
#pragma mark UITableView Datasource
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"UserCell";
    
    PULUser *user = _dataSource[indexPath.row];
    
    PULUserCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    cell.user  = user;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSource.count;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    PULUser *user = _dataSource[indexPath.row];
    
    PULNewPullViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULNewPullViewController class])];
    vc.user = user;
    
    PULSlideLeftSegue *seg = [PULSlideLeftSegue segueWithIdentifier:@"nextVc" source:self destination:vc performHandler:^{
        ;
    }];
    [seg perform];
}

@end
