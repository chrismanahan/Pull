//
//  PULPulledUserSelectView.m
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPulledUserSelectView.h"

#import "NSArray+Sorting.h"
#import "CALayer+Animations.h"

#import "NZCircularImageView.h"

@interface PULPulledUserSelectView ()

@property (nonatomic, strong) NSArray *datasource;

@property (nonatomic, strong) NSMutableArray *userImageViews;

@end

@implementation PULPulledUserSelectView

- (void)initialize
{
    PULAccount *acct = [PULAccount currentUser];
    
    NSAssert(acct != nil, @"account cannot be nil");
    
    if (acct.isLoaded)
    {
        // remove load observer if exists
        if ([acct isObservingKeyPath:@"loaded"])
        {
            [acct stopObservingKeyPath:@"loaded"];
        }
        
        [self _loadDatasourceCompletion:^(NSArray *ds) {
            // create image views
            [self _updateUserImageViews];
            
            // load each image view
            [self _populateImageViews];
            
            [self _startObservingPulls];
        }];
        
    }
    else
    {
        [acct observeKeyPath:@"loaded"
                       block:^{
                           [self initialize];
                       }];
    }
}

- (void)_loadDatasourceCompletion:(void(^)(NSArray *ds))completion
{
    PULAccount *acct = [PULAccount currentUser];
    // check if pulls are loaded
    if (acct.pulls.isLoaded)
    {
        // unregister from pulls loaded block if needed
        [acct.pulls unregisterLoadedBlock];
        
        // create data source
        [self _buildDatasource];
        
        if (completion)
        {
            completion(_datasource);
        }
    }
    else
    {
        // wait until pulls are loaded
        [acct.pulls registerLoadedBlock:^(FireMutableArray *objects) {
            [self _loadDatasourceCompletion:completion];
        }];
    }
}

- (void)_startObservingPulls
{
    [[PULAccount currentUser].pulls registerLoadedBlock:^(FireMutableArray *objects) {
        [self _refresh];
    }];
    
    [[PULAccount currentUser].pulls registerForKeyChange:@"status"
                                   onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
                                       [self _refresh];
                                   }];
    
    // locations
    [[PULAccount currentUser].friends registerForKeyChange:@"location"
                                     onAllObjectsWithBlock:^(FireMutableArray *array, FireObject *object) {
                                         BOOL valid = [self _validateDatasource];
                                         if (!valid)
                                         {
                                             [self _refresh];
                                         }
                                     }];
    
    [[PULAccount currentUser] observeKeyPath:@"location"
                                       block:^{
                                           BOOL valid = [self _validateDatasource];
                                           if (!valid)
                                           {
                                               [self _refresh];
                                           }
                                       }];
}

- (void)_refresh
{
    [self _loadDatasourceCompletion:^(NSArray *ds) {
        // create image views
        [self _updateUserImageViews];
        
        // load each image view
        [self _populateImageViews];
        
        [self setSelectedPull:_selectedPull];
    }];
}

- (BOOL)_validateDatasource
{
    double lastDistance = 0.0;
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        double thisDistance = [[pull otherUser] distanceFromUser:[PULAccount currentUser]];
        
        if (thisDistance < lastDistance)
        {
            return NO;
        }
        else
        {
            lastDistance = thisDistance;
        }
    }
    
    return YES;
}

- (void)_buildDatasource
{
    NSMutableArray *ds;
    
    PULAccount *acct = [PULAccount currentUser];
    // get active pulls
    NSMutableArray *activePulls = [[NSMutableArray alloc] initWithArray:acct.pullsPulledNearby];
    [activePulls addObjectsFromArray:acct.pullsPulledFar];
    
    // sort by distance and store
    ds = [[NSMutableArray alloc] initWithArray:[activePulls sortedPullsByDistance]];
    
    // add the rest of pulls
    [ds addObjectsFromArray:acct.pullsPending];
    [ds addObjectsFromArray:acct.pullsWaiting];
    
    // set data source
    _datasource = [[NSArray alloc] initWithArray:ds];
}

- (void)_populateImageViews
{
    NSAssert(_datasource.count == _userImageViews.count, @"user image view count does not match pull count");
    
    // load each image view
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        NZCircularImageView *iv = _userImageViews[i];
        PULUser *user = [pull otherUser];
        
        [iv setImageWithResizeURL:user.imageUrlString];
    }
}

#pragma mark - Public
- (nullable PULPull*)pullAtIndex:(NSUInteger)index;
{
    if (index < _datasource.count)
    {
        return _datasource[index];
    }
    return nil;
}

- (void)setSelectedPull:(PULPull * __nullable)selectedPull;
{
    _selectedPull = selectedPull;
    [self setSelectedIndex:[self _indexForPull:selectedPull]];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated;
{
    if (_datasource.count > 0)
    {
        //NSAssert(selectedIndex < _datasource.count, @"selected index out of bounds");
        if (selectedIndex < 0)
        {
            selectedIndex = 0;
        }
        
        // get image view for previous selected index
        NZCircularImageView *iv = _userImageViews[_selectedIndex];
        // change border color
        iv.borderColor = PUL_LightGray;
        
        
        // set new index and pull
        _selectedIndex = selectedIndex;
        PULPull *pull = _datasource[_selectedIndex];
        _selectedPull = pull;
        
        // update selected image
        iv = _userImageViews[_selectedIndex];
        // change border color
        iv.borderColor = PUL_Purple;
        
        if (animated)
        {
            [iv.layer addPopAnimation];
        }

        // notify delegate
        if ([_delegate respondsToSelector:@selector(didSelectPull:atIndex:)])
        {
            [_delegate didSelectPull:pull atIndex:_selectedIndex];
        }
    }
}

#pragma mark - Private
- (PULUser*)_userForIndex:(NSInteger)index;
{
    PULPull *pull = _datasource[index];
    return [pull otherUser];
}

- (NSInteger)_indexForUser:(PULUser*)aUser;
{
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        PULUser *user = [pull otherUser];
        if ([user isEqual:aUser])
        {
            return i;
        }
    }
    
    return -1;
}

- (NSInteger)_indexForPull:(PULPull*)aPull;
{
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        if ([pull isEqual:aPull])
        {
            return i;
        }
    }
    
    return -1;
}

/**
 *  Updates the array of user image views
 */
- (void)_updateUserImageViews
{
    if (!_userImageViews)
    {
        _userImageViews = [[NSMutableArray alloc] init];
    }
 
    CGFloat padding = 10;
    // determine size for each new view
    CGFloat wh = CGRectGetHeight(self.frame) - padding*2;
    // determine how many views are needed
    NSInteger viewsNeeded = [PULAccount currentUser].pulls.count - _userImageViews.count;
    
    if (viewsNeeded < 0)
    {
        PULLog(@"\tremoving  %zd old views", labs(viewsNeeded));
        // remove extra views
        [_userImageViews removeObjectsInRange:NSMakeRange(_userImageViews.count + viewsNeeded, labs(viewsNeeded))];
    }
    else if (viewsNeeded > 0)
    {
        PULLog(@"\tcreating %zd new views", viewsNeeded);
        for (int i = 0; i < viewsNeeded; i++)
        {
            // create view
            NZCircularImageView *imageView = [[NZCircularImageView alloc] initWithFrame:CGRectMake(0, padding, wh, wh)];
            imageView.borderColor = PUL_LightGray;
            imageView.borderWidth = @(4);
            
            [_userImageViews addObject:imageView];
        }
    }
    
    // update x for each user image view
    for (int i = 0; i < _userImageViews.count; i++)
    {
        NZCircularImageView *iv = _userImageViews[i];
        CGRect frame = iv.frame;
        CGFloat newX = padding;
        
        if (i != 0)
        {
            // get previous view
            NZCircularImageView *prevIv = _userImageViews[i-1];
            newX += CGRectGetMaxX(prevIv.frame);
        }
        
        frame.origin.x = newX;
        iv.frame = frame;
        
        if (!iv.superview)
        {
            [self addSubview:iv];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] firstObject];
    CGPoint point = [touch locationInView:self];

    for (NZCircularImageView *iv in _userImageViews)
    {
        if (CGRectContainsPoint(iv.frame, point))
        {
            [self setSelectedIndex:[_userImageViews indexOfObject:iv] animated:YES];
            break;
        }
    }
}

@end
