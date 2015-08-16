//
//  PULPassthroughView.m
//  Pull
//
//  Created by Chris M on 4/21/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPassthroughView.h"

@implementation PULPassthroughView
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}
@end