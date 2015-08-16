//
//  PULPullOverlayView.m
//  Pull
//
//  Created by Chris M on 5/3/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPullOverlayView.h"

@implementation PULPullOverlayView

+ (UIView*)overlayOnView:(UIView*)view fromNib:(NSString*)nib offset:(NSInteger)offset pull:(PULPull*)pull
{
    PULPullOverlayView *overlay = (PULPullOverlayView*)[super overlayOnView:view fromNib:nib offset:offset];
    
    overlay.pull = pull;
    
    return overlay;
}

+ (void)overlayOnView:(UIView*)view withPull:(PULPull*)pull;
{
    // remove existing overlay if any
    [self removeOverlayFromView:view];
    
    // add nib to view
    [self overlayOnView:view fromNib:NSStringFromClass([self class]) offset:0 pull:pull];
}


@end
