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

- (UIColor*)borderColor
{
    UIColor *color = [super borderColor];
    if ([color isEqual:[UIColor whiteColor]])
    {
        return PUL_Purple;
    }
    else
    {
        return color;
    }
}

//// Only override drawRect: if you perform custom drawing.
//// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//
//    [super drawRect:rect];
//
//    NSInteger offset = 12;
//    
//    CGContextRef ref = UIGraphicsGetCurrentContext();
//    
//    CGContextSetFillColorWithColor(ref, self.borderColor.CGColor);
//    
//    CGContextFillEllipseInRect(ref, rect);
//    
//    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
//    CGRect innerRect = CGRectInset(rect, offset/2, offset/2);
//    
//    CGContextFillEllipseInRect(ref, innerRect);
//}


@end
