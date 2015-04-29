//
//  PULHeaderView.m
//  Pull
//
//  Created by admin on 4/29/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULHeaderView.h"

@implementation PULHeaderView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGRect headRect = CGRectInset(rect, 0, 1);
    
    UIColor *lineColor = PUL_LightGray;
    
    CGContextSetFillColorWithColor(ref, lineColor.CGColor);
    CGContextFillRect(ref, rect);
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    CGContextFillRect(ref, headRect);
}


@end
