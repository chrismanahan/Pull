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

#import "PULLoadingIndicator.h"
#import "PULParseMiddleMan.h"
#import "PULUser.h"
#import "PULSlideLeftSegue.h"
#import "PULSlideUnwindSegue.h"

#import "SVPullToRefresh.h"

#import "Amplitude.h"

@interface PULUserSelectViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *noFriendsOverlay;

@property (nonatomic, strong) NSArray *dataSource;

@property (strong, nonatomic) IBOutlet UILabel *ticketHeaderLabel;

@property (nonatomic, strong) PULParseMiddleMan *parse;
@property (nonatomic, strong) PULLoadingIndicator *ai;

@end

@implementation PULUserSelectViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _ai = [PULLoadingIndicator indicatorOnView:self.view];
    if ([_parse.cache cachedFriendsNotPulled])
    {
        [self _reloadDatasource];
    }
    else
    {
        [_ai show];
    }
    
    [_parse getFriendsInBackground:^(NSArray<PULUser *> * _Nullable users, NSError * _Nullable error) {
        // hide or show no friends overlay if needed
        if (!_dataSource || _dataSource.count == 0) {
            self.noFriendsOverlay.hidden = YES;
        } else if (self.noFriendsOverlay.hidden) {
            self.noFriendsOverlay.hidden = NO;
        }
        
        [self _reloadDatasource];
        [_ai hide];
    }];
    
    __weak id weakSelf = self;
    [_tableView addPullToRefreshWithActionHandler:^{
        [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventRefreshFriendsList];
        
        [[PULParseMiddleMan sharedInstance] getFriendsInBackground:^(NSArray<PULUser *> * _Nullable users, NSError * _Nullable error) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf _reloadDatasource];
                [[weakSelf tableView].pullToRefreshView stopAnimating];
            });
        }];

    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    _searchBar.tintColor = PUL_Purple;
    
    _parse = [PULParseMiddleMan sharedInstance];
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
    // TODO: reload data source
    if (!search || search.length == 0)
    {
        _dataSource = [_parse.cache cachedFriendsNotPulled];
    }
    else
    {
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        for (PULUser *user in [_parse.cache cachedFriendsNotPulled])
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
