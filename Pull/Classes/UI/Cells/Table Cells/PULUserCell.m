//
//  PULUserCell.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUserCell.h"

#import "PULAccountOld.h"

#import "PULConstants.h"

@interface PULUserCell ()

@property (nonatomic, strong) id userUpdatedObserver;

@property (nonatomic, strong) id accountLocationUpdatedObserver;

@end

@implementation PULUserCell

- (void)setUser:(PULUserOld *)user
{
    _user = user;

    // set ui
    _userImageViewContainer.imageView.image = user.image;
    _userDisplayNameLabel.text = user.fullName;
    
    if (_userDistanceLabel)
    {
        CGFloat distance = [[PULAccountOld currentUser].location distanceFromLocation:user.location];
        
        [self p_updateDistanceLabel:distance];
        
//        if (_user.isOnline)
//        {
//            _userImageViewContainer.imageView.alpha = 1.0;
//        }
//        else
//        {
//            _userImageViewContainer.imageView.alpha = 0.4;
//        }
    }
    
    // subscribe to notifications
    if (_userUpdatedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_userUpdatedObserver];
        _userUpdatedObserver = nil;
    }
    if (_accountLocationUpdatedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_accountLocationUpdatedObserver];
        _accountLocationUpdatedObserver = nil;
    }
    
    // start observing updates from this user
    _userUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kPULFriendUpdatedNotifcation
                                                                             object:user
                                                                              queue:[NSOperationQueue currentQueue]
                                                                         usingBlock:^(NSNotification *note) {
                                                                             // set updated user
                                                                             self.user = [note object];
                                                                         }];
    
    if (_userDistanceLabel)
    {
        _accountLocationUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kPULAccountOldDidUpdateLocationNotification
                                                                                          object:nil
                                                                                           queue:[NSOperationQueue mainQueue]
                                                                                      usingBlock:^(NSNotification *note) {
                                                                                          // update distance label
                                                                                          
                                                                                          CLLocation *loc = [note object];
                                                 
                                                                                          CGFloat distance = [loc distanceFromLocation:_user.location];
                                                                                          
                                                                                          [self p_updateDistanceLabel:distance];
                                                                                          
                                                                                      }];
    }
}

#pragma mark - private
- (void)p_updateDistanceLabel:(CGFloat)distance
{
    static UIColor *originalLabelColor = nil;
    if (!originalLabelColor)
    {
        originalLabelColor = _userDistanceLabel.textColor;
    }
//    if (_user.isOnline)
//    {
        CGFloat convertedDistance;
        NSString *unit, *formatString;
        // TODO: localize distance
        if (distance < kPULDistanceUnitCutoff)
        {
            // distance as ft
            convertedDistance = METERS_TO_FEET(distance);
            unit = @"Feet";
            formatString = @"%i %@";
        }
        else
        {
            // distance as miles
            convertedDistance = METERS_TO_MILES(distance);
            unit = @"Miles";
            formatString = @"%.2f %@";
        }
        
        NSString *string = [NSString stringWithFormat:@"%.2f %@", convertedDistance, unit];
        
        _userDistanceLabel.text = string;
        
        _userDistanceLabel.textColor = originalLabelColor;
//    }
//    else
//    {
//        _userDistanceLabel.text = @"Unavailable";
//        
//        _userDistanceLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
//    }
}

- (void)_hideLabels:(BOOL)hide
{
    _userDistanceLabel.hidden = hide;
}

#pragma mark - Actions
- (IBAction)ibDecline:(id)sender
{
    [_delegate userCellDidDeclinePull:self];
}

- (IBAction)ibAccept:(id)sender
{
    [_delegate userCellDidAcceptPull:self];
}
- (IBAction)ibCancel:(id)sender
{
    [_delegate userCellDidCancelPull:self];
}

#pragma mark - scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    
    if (offset.x < 0 && _type == PULUserCellTypePulled)
    {
        [scrollView setContentOffset:CGPointZero];
    }
    else if (offset.x > 0 && _type == PULUserCellTypeNearby)
    {
        [scrollView setContentOffset:CGPointZero];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([_delegate respondsToSelector:@selector(userCellDidBeginPulling:)])
    {
        [_delegate userCellDidBeginPulling:self];
    }
    
    [self _hideLabels:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    CGFloat offset = scrollView.contentOffset.x;
    
    if ((_type == PULUserCellTypePulled && offset > CGRectGetWidth(scrollView.frame) - CGRectGetMinX(_accessoryImageView.frame)) ||
        (_type == PULUserCellTypeNearby && abs(offset) > CGRectGetMaxX(_accessoryImageView.frame)))
    {
        if ([_delegate respondsToSelector:@selector(userCellDidCompletePulling:)])
        {
            [_delegate userCellDidCompletePulling:self];
        }
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(userCellDidAbortPulling:)])
        {
            [_delegate userCellDidAbortPulling:self];
        }
    }
    
    [self _hideLabels:NO];
}

@end
