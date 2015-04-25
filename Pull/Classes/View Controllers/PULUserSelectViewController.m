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

@property (strong, nonatomic) IBOutlet UIView *noFriendsOverlay;

@property (nonatomic, strong) NSArray *dataSource;

@property (strong, nonatomic) id obsPullCount;

@end

@implementation PULUserSelectViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    PULAccount *account = [PULAccount currentUser];
    
    void (^loadBlock)() = ^void(){
        if (account.friends.count == 0 && account.friends.isLoaded)
        {
            _noFriendsOverlay.hidden = NO;
        }
        else
        {
            if (!_noFriendsOverlay.hidden)
            {
                _noFriendsOverlay.hidden = YES;
            }
            
            _dataSource = [account sortedArray:[PULAccount currentUser].unpulledFriends];
            [_tableView reloadData];
        }
    };
    
    if ((account.pulls.isLoaded && account.pulls.count > 0) || account.pulls.count == 0)
    {
        loadBlock();
    }
    
    [account.pulls registerLoadedBlock:^(FireMutableArray *objects) {
        loadBlock();
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
