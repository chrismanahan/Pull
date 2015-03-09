//
//  PULCellScrollView.m
//  Pull
//
//  Created by admin on 3/9/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULCellScrollView.h"

@implementation PULCellScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self superview]touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self superview]touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self superview]touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self superview]touchesEnded:touches withEvent:event];
}
@end
