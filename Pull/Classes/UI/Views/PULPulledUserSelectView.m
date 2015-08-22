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
        NSAssert(selectedIndex < _datasource.count, @"selected index out of bounds");
        
        // get image view for previous selected index
        NZCircularImageView *iv = _userImageViews[_selectedIndex];
        // change border color
        iv.borderColor = PUL_LightGray;
        
        // set new index
        _selectedIndex = selectedIndex;
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
            PULPull *pull = _datasource[_selectedIndex];
            [_delegate didSelectPull:pull atIndex:_selectedIndex];
        }
    }
}

- (NSInteger)maxIndex
{
    return _datasource.count - 1;
}

- (void)reload
{
    PULLog(@"reloading pulled user select view");
    _datasource = [[PULAccount currentUser].pulls sortedPullsByDistance];
    PULLog(@"\tdatasource count: %zd", _datasource.count);

    [self _updateUserImageViews];
    
    NSAssert(_datasource.count == _userImageViews.count, @"user image view count does not match pull count");
    
    // load each image view
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        NZCircularImageView *iv = _userImageViews[i];
        PULUser *user = [pull otherUser];
        
        [iv setImageWithResizeURL:user.imageUrlString];
        
        if (!_selectedPull)
        {
            [self setSelectedIndex:0];
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
    CGFloat wh = CGRectGetHeight(self.frame) - padding*3;
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
            imageView.borderWidth = @(3);
            
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
