//
//  PULInfoAlert.m
//  Pull
//
//  Created by Chris Manahan on 2/1/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULInfoAlert.h"

const CGFloat kPULInfoAlertDefaultDuration = 0.6;

@interface PULInfoAlert ()

@property (nonatomic, strong) UIView *parentView;

@end

@implementation PULInfoAlert

+ (PULInfoAlert*)alertWithText:(NSString*)text onView:(UIView*)view;
{
    CGFloat padding = 10;
    CGFloat height = CGRectGetHeight(view.frame) / 2;
    CGFloat width = CGRectGetWidth(view.frame) - 2 * padding;
    
    PULInfoAlert *alert = [[PULInfoAlert alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    alert.center = view.center;
    alert.backgroundColor = [UIColor clearColor];
    
    alert.parentView = view;
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width - padding, height - padding)];
    lbl.numberOfLines = 2;
    lbl.text = text;
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont fontWithName:@"TimeBurner" size:60];
    [lbl sizeToFit];
    
    lbl.center = CGPointMake(CGRectGetMidX(alert.frame), CGRectGetHeight(alert.frame) / 3);
    CGRect frame = lbl.frame;
    frame.origin.x = (CGRectGetWidth(alert.frame) - CGRectGetWidth(lbl.frame)) / 2;
    lbl.frame = frame;
    
    [alert addSubview:lbl];
    
    alert.userInteractionEnabled = NO;
    
    return alert;
}

- (void)show;
{
    [self showWithDuration:kPULInfoAlertDefaultDuration];
}
- (void)showWithDuration:(CGFloat)duration;
{
    [_parentView addSubview:self];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    });
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ref, [UIColor orangeColor].CGColor);
    
    rect = CGRectInset(rect, 4, 4);
    CGContextFillEllipseInRect(ref, rect);
}

@end
