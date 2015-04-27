//
//  PULRoundedMapView.m
//  Pull
//
//  Created by admin on 4/27/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULRoundedMapView.h"

@implementation PULRoundedMapView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    self.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
//    self.center = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) / 2);
    
    NSInteger offset = 0;
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(offset / 2, offset / 2, self.frame.size.width - offset, self.frame.size.height - offset) cornerRadius:MAX(self.frame.size.width, self.frame.size.height)];
    
    circle.path = circularPath.CGPath;
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    self.layer.mask = circle;
    
}

@end
