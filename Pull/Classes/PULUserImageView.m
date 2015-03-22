//
//  PULUserImageView.m
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULUserImageView.h"

@implementation PULUserImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:self.bounds];
        
        _imageView = iv;
        [self addSubview:iv];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (UIColor*)borderColor
{
    if (!_borderColor || !_hasBorder)
    {
        return [UIColor whiteColor];
    }
    else
    {
        return _borderColor;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    self.imageView.center = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) / 2);
    
    NSInteger offset = _hasBorder ? 12 : _selected ? 1 : 0;
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(offset / 2, offset / 2, self.imageView.frame.size.width - offset, self.imageView.frame.size.height - offset) cornerRadius:MAX(self.imageView.frame.size.width, self.imageView.frame.size.height)];
    
    circle.path = circularPath.CGPath;
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    self.imageView.layer.mask = circle;
 
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    rect = CGRectInset(rect, 2, 2);
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ref);
    
    if (_selected || _hasBorder || _hasShadow)
    {
        CGContextSetShadow(ref, CGSizeMake(0, 1), 2);
    }
    
    CGColorRef color = self.borderColor.CGColor;
//    if (!_selected)
//    {
//        color = self.borderColor.CGColor;// [UIColor whiteColor].CGColor;
//    }
//    else
//    {
//        color = [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000].CGColor;
//    }
    
    CGContextSetFillColorWithColor(ref, color);
    
    CGContextFillEllipseInRect(ref, rect);
    
    CGContextRestoreGState(ref);
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    PULUserImageView *copy = [[[self class] alloc] init];
    
    if (copy)
    {
        [copy setImageView:self.imageView];
        [copy setBorderColor:self.borderColor];
        [copy setSelected:self.isSelected];
    }
    
    return copy;
}

@end
