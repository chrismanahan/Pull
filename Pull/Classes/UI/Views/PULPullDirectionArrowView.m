//
//  PULPullDirectionArrowView.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPullDirectionArrowView.h"

@implementation PULPullDirectionArrowView

- (void)drawRect:(CGRect)rect
{
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ref, [UIColor purpleColor].CGColor);
    
    CGFloat offset = 40;
    CGFloat padding = 10;
    CGRect circleRect = CGRectInset(rect, offset, offset);
    
    CGContextAddEllipseInRect(ref, circleRect);
    
    CGContextMoveToPoint(ref, CGRectGetMinX(rect) + offset, CGRectGetMidY(rect) + padding);
    CGContextAddLineToPoint(ref, 0, 0);
    
    CGContextAddLineToPoint(ref, CGRectGetMidX(rect) + padding, CGRectGetMinY(rect) + offset);
    CGContextClosePath(ref);
    
    CGContextFillPath(ref);
}

@end
