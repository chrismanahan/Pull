//
//  PULUserImageView.m
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULUserImageView.h"

@implementation PULUserImageView

IB_DESIGNABLE

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSInteger offset = 12;
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(offset / 2, offset / 2, self.imageView.frame.size.width - offset, self.imageView.frame.size.height - offset) cornerRadius:MAX(self.imageView.frame.size.width, self.imageView.frame.size.height)];
    
    circle.path = circularPath.CGPath;
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    self.imageView.layer.mask = circle;
//    self.imageView.center = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) / 2);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetShadow(ref, CGSizeMake(1, 1), 2);
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    
    CGContextFillEllipseInRect(ref, rect);
}


@end
