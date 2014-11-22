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


- (void)drawRect:(CGRect)rect {
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);

    CGContextSetShadow(ref, CGSizeMake(0, 3), 5.0);
    
    NSInteger minSide = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect));
    NSInteger offset  = 5;
    CGRect squareRect = CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), minSide, minSide);
    squareRect        = CGRectInset(squareRect, offset, offset);
    
    CGContextFillEllipseInRect(ref, squareRect);
}

@end
