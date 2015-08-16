//
//  UIVisualEffectView+PullBlur.m
//  Pull
//
//  Created by Chris Manahan on 3/10/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "UIVisualEffectView+PullBlur.h"

@implementation UIView (PullBlur)

+ (instancetype)pullVisualEffectViewWithFrame:(CGRect)frame;
{
    return [self pullVisualEffectViewWithFrame:frame glass:YES];
}

+ (instancetype)pullVisualEffectViewWithFrame:(CGRect)frame glass:(BOOL)glass;
{
    UIView *vis;
    if ([UIVisualEffectView class] && glass)
    {
        UIVisualEffect *visEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        vis = [[UIVisualEffectView alloc] initWithEffect:visEffect];
        vis.frame = frame;
        vis.alpha = 0.8;
    }
    else
    {
        vis = [[UIView alloc] initWithFrame:frame];
        vis.backgroundColor = [UIColor whiteColor];
        vis.alpha = 0.6;
    }
    
    return vis;
}

@end
