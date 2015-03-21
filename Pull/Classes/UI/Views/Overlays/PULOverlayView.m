//
//  PULOverlayView.m
//  Pull
//
//  Created by Development on 3/14/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULOverlayView.h"

@implementation PULOverlayView

+ (BOOL)viewContainsOverlay:(UIView*)view;
{
    for (UIView *sub in view.subviews)
    {
        if ([sub isKindOfClass:[PULOverlayView class]])
        {
            return YES;
        }
        else if (sub.subviews.count)
        {
            return [self viewContainsOverlay:sub];
        }
    }
    return NO;
}

+ (void)overlayOnView:(UIView*)view fromNib:(NSString*)nib offset:(NSInteger)offset;
{
    UIView *overlay = [[NSBundle mainBundle] loadNibNamed:nib owner:self options:nil][0];
    
    CGRect frame = view.bounds;
    
    if (offset)
    {
        frame.origin.y += offset;
        frame.size.height -= offset;
    }
    
    overlay.frame = frame;
    
    [view addSubview:overlay];
}

+ (void)overlayOnView:(UIView*)view offset:(NSInteger)offset
{
    PULLog(@"WILL ADD OVERLAY TO VIEW");
    // remove existing overlay if any
    [self removeOverlayFromView:view];
    
    // add nib to view
    [self overlayOnView:view fromNib:NSStringFromClass([self class]) offset:offset];
    PULLog(@"DID ADD OVERLAY TO VIEW");
}

+ (void)overlayOnView:(UIView*)view
{
    [self overlayOnView:view offset:0];
}

+ (void)removeOverlayFromView:(UIView*)view;
{
    for (UIView *sub in view.subviews)
    {
        if ([sub isKindOfClass:[PULOverlayView class]])
        {
            PULLog(@"REMOVING OVERLAY VIEW");
            [sub removeFromSuperview];
        }
        else if (sub.subviews.count)
        {
            [self removeOverlayFromView:sub];
        }
    }
}

@end
