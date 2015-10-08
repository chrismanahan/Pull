//
//  PULLoadingIndicator.m
//  Pull
//
//  Created by Chris Manahan on 2/8/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULLoadingIndicator.h"

@interface PULLoadingIndicator ()

@property (nonatomic, strong) UIView *onView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PULLoadingIndicator

+ (instancetype)indicatorOnView:(UIView*)onView;
{
    PULLoadingIndicator *ai = [[PULLoadingIndicator alloc] initWithFrame:onView.frame];
    ai.onView = onView;
    
    CGFloat width = 200;
    CGFloat height = 200;
    ai.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(onView.frame) - width) / 2, CGRectGetHeight(onView.frame) / 4, width, height)];
    
    ai.imageView.animationImages = @[[UIImage imageNamed:@"home_loading"],
                                     [UIImage imageNamed:@"home_loading2"],
                                     [UIImage imageNamed:@"home_loading3"],
                                     [UIImage imageNamed:@"home_loading4"]];
    ai.imageView.animationRepeatCount = 0;
    ai.imageView.animationDuration = .6;
    ai.imageView.contentMode = UIViewContentModeScaleAspectFit;
    ai.imageView.backgroundColor = [UIColor whiteColor];
    ai.imageView.layer.cornerRadius = width / 4;
    ai.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    ai.imageView.layer.shadowOffset = CGSizeMake(0, 1);
    ai.imageView.layer.shadowOpacity = 0.25;
    
    [ai addSubview:ai.imageView];
    
    return ai;
}

- (void)show;
{
    _showing = YES;
    [_onView addSubview:self];
    [self.imageView startAnimating];
}

- (void)hide;
{
    _showing = NO;
    if (self.superview)
    {
        [self removeFromSuperview];
        [self.imageView stopAnimating];
    }
    
}

@end
