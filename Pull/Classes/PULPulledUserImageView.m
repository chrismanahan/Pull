//
//  PULPulledUserImageView.m
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULPulledUserImageView.h"

IB_DESIGNABLE

@implementation PULPulledUserImageView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    [super drawRect:rect];

    NSInteger offset = 12;
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ref, [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000].CGColor);
    
    CGContextFillEllipseInRect(ref, rect);
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    CGRect innerRect = CGRectInset(rect, offset/2, offset/2);
    
    CGContextFillEllipseInRect(ref, innerRect);
}


@end
