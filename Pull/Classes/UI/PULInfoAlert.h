//
//  PULInfoAlert.h
//  Pull
//
//  Created by Chris Manahan on 2/1/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@class UIView;

@interface PULInfoAlert : UIView

@property (nonatomic, strong) NSString *text;

+ (PULInfoAlert*)alertWithText:(NSString*)text onView:(UIView*)view;

- (void)show;

- (void)showWithDuration:(CGFloat)duration;

@end
