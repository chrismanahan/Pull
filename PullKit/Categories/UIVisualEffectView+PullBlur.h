//
//  UIVisualEffectView+PullBlur.h
//  Pull
//
//  Created by Chris Manahan on 3/10/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (PullBlur)

+ (instancetype)pullVisualEffectViewWithFrame:(CGRect)frame;

+ (instancetype)pullVisualEffectViewWithFrame:(CGRect)frame glass:(BOOL)glass;

@end
