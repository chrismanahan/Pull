//
//  PULOverlayView.h
//  Pull
//
//  Created by Development on 3/14/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PULOverlayView : UIView

+ (BOOL)viewContainsOverlay:(UIView*)view;

+ (void)overlayOnView:(UIView*)view offset:(NSInteger)offset;
+ (void)overlayOnView:(UIView*)view;

+ (void)removeOverlayFromView:(UIView*)view;

@end
