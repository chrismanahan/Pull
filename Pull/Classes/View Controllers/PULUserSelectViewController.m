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

#import "PULSlideLeftSegue.h"
#import "PULSlideUnwindSegue.h"

@interface PULUserSelectViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *noFriendsOverlay;

@property (nonatomic, strong) NSArray *dataSource;

@property (strong, nonatomic) id pullsLoadedNotification;

@property (strong, nonatomic) IBOutlet UIButton *inviteButtonCenter;
@property (strong, nonatomic) IBOutlet UIButton *inviteButtonRight;
@property (strong, nonatomic) IBOutlet UIButton *inviteButtonLeft;
@property (strong, nonatomic) IBOutlet UILabel *ticketHeaderLabel;

@end

@implementation PULUserSelectViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _searchBar.text = @"";
    
    PULAccount *account = [PULAccount currentUser];
    
    void (^loadBlock)() = ^void(){
        if (account.friends.count == 0 && account.friends.isLoaded)
        {
            _noFriendsOverlay.hidden = NO;
            
            // determine how many invite buttons should be shown
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasSentInviteKey"])
            {
                NSInteger remaining = [[NSUserDefaults standardUserDefaults] integerForKey:@"InvitesRemainingKey"];
                if (remaining < 3)
                {
                    _inviteButtonRight.hidden = YES;
                }
                if (remaining < 2)
                {
                    _inviteButtonCenter.hidden = YES;
                }
                if (remaining < 1)
                {
                    _inviteButtonLeft.hidden = YES;
                }
                
                if (remaining == 0)
                {
                    _ticketHeaderLabel.text = @"You've already sent out your 3 invites";
                }
            }
        }
        else
        {
            if (!_noFriendsOverlay.hidden)
            {
                _noFriendsOverlay.hidden = YES;
            }
            
            [self _reloadDatasource];
        }
    };
    
    if ((account.pulls.isLoaded && account.pulls.count > 0) || account.pulls.count == 0)
    {
        loadBlock();
    }
    
    
    
    _pullsLoadedNotification = [[NSNotificationCenter defaultCenter] addObserverForName:FireArrayLoadedNotification
                                                                                 object:[PULAccount currentUser].pulls
                                                                                  queue:[NSOperationQueue currentQueue]
                                                                             usingBlock:^(NSNotification *note) {
                                                                                 if (!_dataSource)
                                                                                 {
                                                                                     loadBlock();
                                                                                 }
                                                                             }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_pullsLoadedNotification)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_pullsLoadedNotification];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    _searchBar.tintColor = PUL_Purple;
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

#pragma mark - Private
- (void)_reloadDatasource
{
    [self _reloadDatasourceForSearch:nil];
}

- (void)_reloadDatasourceForSearch:(NSString*)search
{
    if (!search || search.length == 0)
    {
        _dataSource = [[PULAccount currentUser] sortedArray:[PULAccount currentUser].unpulledFriends];
    }
    else
    {
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        for (PULUser *user in [PULAccount currentUser].unpulledFriends)
        {
            search = search.lowercaseString;
            if ([user.firstName.lowercaseString hasPrefix:search] || [user.lastName.lowercaseString hasPrefix:search] ||
                [user.fullName.lowercaseString hasPrefix:search])
            {
                [temp addObject:user];
            }
        }
        _dataSource = [[NSArray alloc] initWithArray:temp];
    }
    
    [_tableView reloadData];
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

#pragma mark - UIScrollView Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([_searchBar isFirstResponder])
    {
        [_searchBar resignFirstResponder];
    }
}

@end
