//
//  PULCircleButton.m
//  Pull
//
//  Created by Development on 10/12/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULCircleButton.h"

IB_DESIGNABLE

@implementation PULCircleButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);

    CGFloat shadowY = self.isHighlighted ? 1 : 3;
    CGFloat shadowBlur = self.isHighlighted ? 1 : 5;
    CGContextSetShadow(ref, CGSizeMake(0, shadowY), shadowBlur);
    
    NSInteger minSide = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect));
    NSInteger offset  = 6;
    CGRect squareRect = CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), minSide, minSide);
    squareRect        = CGRectInset(squareRect, offset, offset);
    
    CGContextFillEllipseInRect(ref, squareRect);
}

@end
