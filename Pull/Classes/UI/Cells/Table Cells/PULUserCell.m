//
//  PULUserCell.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUserCell.h"

#import "PULAccount.h"

#import "PULConstants.h"

@interface PULUserCell ()

@property (nonatomic, strong) id userUpdatedObserver;

@property (nonatomic, strong) id accountLocationUpdatedObserver;

@end

@implementation PULUserCell

- (void)setType:(PULUserCellType)type
{
    if (type == PULUserCellTypePulled)
    {
        _userImageViewContainer.borderColor = [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPulledUserImage:)];
        tap.numberOfTapsRequired = 1;
        [_userImageViewContainer addGestureRecognizer:tap];
    }
    else if (type == PULUserCellTypePending || type == PULUserCellTypeWaiting)
    {
        _userImageViewContainer.borderColor = [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000];
    }
    
    _type = type;
}

- (void)didTapPulledUserImage:(UIGestureRecognizer*)gesture
{
    [_delegate userCellDidTapUserImage:self];
}

- (void)setUser:(PULUser *)user
{
    
    // set ui
    _userImageViewContainer.imageView.image = user.image;
    _userDisplayNameLabel.text = user.fullName;
    
    if (_userDistanceLabel)
    {
        CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:user.location];
        
        [self p_updateDistanceLabel:distance];
    }

    _user = user;
    
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
        _accountLocationUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kPULAccountDidUpdateLocationNotification
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

- (void)p_updateDistanceLabel:(CGFloat)distance
{
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
}

- (void)_hideLabels:(BOOL)hide
{
   for (UILabel *label in self.bgView.subviews)
   {
       if ([label isKindOfClass:[UILabel class]])
       {
           label.hidden = hide;
       }
   }
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


#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches began");
    UITouch *touch = [touches allObjects][0];
    CGPoint point = [touch locationInView:_userImageViewContainer];
    
    if (CGRectContainsPoint(_userImageViewContainer.bounds, point) &&
        (_type == PULUserCellTypeNearby || _type == PULUserCellTypePulled))
    {
        self.bgView.pulling = YES;
        self.userImageViewContainer.selected = YES;
        [self.bgView setNeedsDisplay];
        
//        UIColor *borderColor;
//        if (!self.bgView.left)
//        {
//            borderColor = [UIColor redColor];
//        }
//        else
//        {
//            borderColor =  [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
//        }
//        
//        _userImageViewContainer.borderColor = borderColor;
//        
//        [_userImageViewContainer setNeedsDisplay];
        
        // hide some ui
        [self _hideLabels:YES];
        
        [_delegate userCellDidBeginPulling:self];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_bgView.isPulling)
    {
        UITouch *touch = [touches allObjects][0];
        CGPoint point = [touch locationInView:_bgView];

        CGPoint center = _userImageViewContainer.center;
        center.x = point.x;
        
        if (center.x > CGRectGetWidth(_userImageViewContainer.frame) / 2 &&
            center.x < CGRectGetWidth(_bgView.frame) - CGRectGetWidth(_userImageViewContainer.frame) / 2)
        {
            _userImageViewContainer.center = center;
        }
    }
    else
    {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches ended");
    [super touchesEnded:touches withEvent:event];
    [self _touchesStopped];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches canceled");
    [super touchesCancelled:touches withEvent:event];
    
    [self _touchesStopped];
}

- (void)_touchesStopped
{
    // check position of user image view
    if (_bgView.isPulling)
    {
        BOOL success = NO;
        CGRect destRect;
        if (CGRectEqualToRect(_bgView.originalRect, _bgView.rightImageViewFrame))
        {
            destRect = _bgView.leftImageViewFrame;
        }
        else
        {
            destRect = _bgView.rightImageViewFrame;
        }
        
        CGRect sendToRect;
        CGRect intersect = CGRectIntersection(_userImageViewContainer.frame, destRect);
        if (CGSizeEqualToSize(intersect.size, CGSizeZero))
        {
            // return image view to source
            sendToRect = _bgView.originalRect;
        }
        else
        {
            sendToRect = destRect;
            success = YES;
        }
        
        // animate and notify delegate
        [UIView animateWithDuration:0.3 animations:^{
            _userImageViewContainer.center = CGPointMake(CGRectGetMidX(sendToRect), _userImageViewContainer.center.y);
        } completion:^(BOOL finished) {
            if (success)
            {
                [_delegate userCellDidCompletePulling:self];
            }
            else
            {
                [_delegate userCellDidAbortPulling:self];
            }
            
            self.bgView.pulling = NO;
//            _userImageViewContainer.borderColor = nil;
           self.userImageViewContainer.selected = NO;
            
            // show hidden ui
            [self _hideLabels:NO];
        
            [self.bgView setNeedsDisplay];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.bgView setNeedsLayout];
            });

            
        }];
    }
    
}



@end
