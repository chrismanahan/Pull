//
//  PULUserTableCellBackgroundView.m
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULUserTableCellBackgroundView.h"

IB_DESIGNABLE

@implementation PULUserTableCellBackgroundView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetShadow(ref, CGSizeMake(0, 3), 5.0);
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    
    CGRect innerRect = CGRectInset(rect, 2, 4);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:innerRect cornerRadius:45];
    [path fill];
}


@end
