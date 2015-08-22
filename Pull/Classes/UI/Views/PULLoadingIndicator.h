//
//  PULLoadingIndicator.h
//  Pull
//
//  Created by Chris Manahan on 2/8/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PULLoadingIndicator : UIView

@property (nonatomic, strong) NSString *title;

@property (nonatomic, assign, getter=isShowing, readonly) BOOL showing;

+ (instancetype)indicatorOnView:(UIView*)onView;

- (void)show;

- (void)hide;

@end
