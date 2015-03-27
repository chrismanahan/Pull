//
//  PULUserScrollView.m
//  Pull
//
//  Created by Development on 3/21/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserOld.h"

#import "PULUserImageView.h"

#import "PULUserScrollView.h"

const NSInteger kPULUserScrollViewPadding = 10;

@implementation PULUserScrollView

- (void)reload
{
    CGSize size = self.cellSize;
    NSInteger numUsers = [_dataSource numberOfUsersInUserScrollView:self];
    
    for (UIView *sub in self.subviews)
    {
        [sub removeFromSuperview];
    }
    
    if ([_dataSource respondsToSelector:@selector(insetsForUserScrollView:)])
    {
        self.contentInset = [_dataSource insetsForUserScrollView:self];
    }
    
    for (int i = 0; i < numUsers; i++)
    {
        BOOL active = NO;
        PULUserOld *user = [_dataSource userForIndex:i isActive:&active userScrollView:self];
        
        PULUserImageView *iv = [[PULUserImageView alloc] initWithFrame:[self _frameForIndex:i]];
        iv.backgroundColor = [UIColor clearColor];
        iv.imageView.image = user.image;
        iv.hasShadow = YES;
        iv.hasBorder = YES;
        
        if (active)
        {
            
            iv.borderColor = PUL_Blue;
        }
        else
        {
            iv.borderColor = [UIColor whiteColor];
        }
        
        [self addSubview:iv];
    }
    
    CGFloat width = numUsers * size.width + (numUsers * kPULUserScrollViewPadding);
    
    if (numUsers > self.maxNumberOfVisibleCells)
    {
        
        CGFloat offset = (numUsers - self.maxNumberOfVisibleCells) * size.width + self.contentInset.right;
        [self setContentOffset:CGPointMake(offset, 0) animated:NO];
        
        
    }
    
    self.contentSize = CGSizeMake(width, CGRectGetHeight(self.frame));
    
}

#pragma mark - Properties
- (NSInteger)maxNumberOfVisibleCells
{
    CGFloat visibleWidth = CGRectGetWidth(self.frame) - self.contentInset.left - self.contentInset.right - kPULUserScrollViewPadding;
    
    NSInteger cells = (int)visibleWidth / (int)self.cellSize.width;
    
    return cells;
}

- (CGSize)cellSize
{
    return [_dataSource cellSizeForUserScrollView:self];
}

#pragma mark - Private
- (CGRect)_frameForIndex:(NSInteger)index
{
    CGRect frame;
    CGSize size = self.cellSize;
    
    CGFloat x = index * size.width + (index * kPULUserScrollViewPadding) + kPULUserScrollViewPadding;
    CGFloat y = (CGRectGetHeight(self.frame) - size.height) / 2;
    frame = CGRectMake(x, y, size.width, size.height);
    
    return frame;
}

- (CGRect)_boundsRectLessInsets
{
    CGRect frame = self.bounds;
    frame.size.width -= self.contentInset.right - self.contentInset.left;
    
    return frame;
}

@end
