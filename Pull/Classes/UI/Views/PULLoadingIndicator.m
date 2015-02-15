//
//  PULLoadingIndicator.m
//  Pull
//
//  Created by Chris Manahan on 2/8/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULLoadingIndicator.h"

@interface PULLoadingIndicator ()

@property (nonatomic, strong) UIView *onView;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) BOOL isAnimating;

@property (nonatomic, assign) CGFloat circleRadius;
@property (nonatomic, assign) CGFloat circleY;
@property (nonatomic, assign) CGRect circleContainer;

@property (nonatomic, assign) CGRect container;

@end

@implementation PULLoadingIndicator

+ (instancetype)indicatorOnView:(UIView*)onView;
{
    PULLoadingIndicator *ai = [[PULLoadingIndicator alloc] initWithFrame:onView.frame];
    ai.onView = onView;
    
//    CGFloat width = 280;
//    CGFloat height = 200;
//    ai.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(onView.frame) - width) / 2, CGRectGetHeight(onView.frame) / 4, width, height)];
//    ai.imageView.image = [UIImage imageNamed:@"loading_1"];
//    
//    ai.imageView.animationImages = @[[UIImage imageNamed:@"loading_1"],
//                                     [UIImage imageNamed:@"loading_2"],
//                                     [UIImage imageNamed:@"loading_3"]];
//    ai.imageView.animationRepeatCount = 0;
//    ai.imageView.animationDuration = .6;
//    ai.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    
//    [ai addSubview:ai.imageView];
    
//    [ai addCircles];
    
    return ai;
}

- (void)show;
{
    [_onView addSubview:self];
    [self setNeedsDisplay];
 
    
//    [self startAnimating];
//    [self.imageView startAnimating];
}

- (void)hide;
{
    [self removeFromSuperview];
//    [self.imageView stopAnimating];
    [self stopAnimating];
}

- (void)startAnimating {
    if (!self.isAnimating) {
        [self addCircles];
        [self addLoadingBar];
        self.hidden = NO;
        self.isAnimating = YES;
    }
}

- (void)addLoadingBar
{

    CGFloat padding = 20;
    CGFloat width = CGRectGetWidth(_container) - padding;
    CGFloat height = 100;
    CGFloat y = CGRectGetMinY(_container) + CGRectGetHeight(_container) - height;
    CGFloat x= CGRectGetMinX(_container) + padding / 2;
    CGRect frame = CGRectMake(x, y, width, height);
    _imageView = [[UIImageView alloc] initWithFrame:frame];
    _imageView.image = [UIImage imageNamed:@"loading_blank"];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_imageView];
    
    frame.origin = CGPointZero;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(frame, 4, 2)];
    label.text = _title;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Avenir-Heavy" size:26.0];
    label.textAlignment = NSTextAlignmentCenter;
    [_imageView addSubview:label];
}

- (void)stopAnimating {
    if (self.isAnimating) {
        [self removeCircles];
        self.hidden = YES;
        self.isAnimating = NO;
    }
}

- (void)removeCircles {
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
}

- (UIView *)createCircleWithRadius:(CGFloat)radius
                             color:(UIColor *)color
                         positionX:(CGFloat)x {
    
    x = CGRectGetMinX(_circleContainer) + x;
    
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(x, _circleY, radius * 2, radius * 2)];
    circle.backgroundColor = color;
    circle.layer.cornerRadius = radius;
    circle.translatesAutoresizingMaskIntoConstraints = NO;
    return circle;
}

- (CABasicAnimation *)createAnimationWithDuration:(CGFloat)duration delay:(CGFloat)delay {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    anim.delegate = self;
    anim.fromValue = [NSNumber numberWithFloat:0.5f];
    anim.toValue = [NSNumber numberWithFloat:1.0f];
    anim.autoreverses = YES;
    anim.duration = duration;
    anim.removedOnCompletion = NO;
    anim.beginTime = CACurrentMediaTime()+delay;
    anim.repeatCount = INFINITY;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return anim;
}

- (void)addCircles {
    CGFloat spacing = 5;
    CGFloat startX = (CGRectGetWidth(_circleContainer) - (_circleRadius * 6 + (2 * spacing))) / 2;
    for (NSUInteger i = 0; i < 3; i++) {
        UIColor *color = [UIColor whiteColor];
        UIView *circle = [self createCircleWithRadius:_circleRadius
                                                color:color
                                            positionX:startX + (i * ((2 * _circleRadius) + spacing))];
        [circle setTransform:CGAffineTransformMakeScale(0, 0)];
        [circle.layer addAnimation:[self createAnimationWithDuration:0.5 delay:(i * 0.1)] forKey:@"scale"];
        [self addSubview:circle];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGRect origRect = rect;
    
    CGFloat width = 280;
    CGFloat height = 225;
    CGFloat y = CGRectGetHeight(_onView.frame) / 4;
    
    // draw background rect
    rect = CGRectMake((CGRectGetWidth(_onView.frame) - width) / 2, y, width, height);
    _container = rect;
    // set color and shadow
    CGContextSetShadow(ref, CGSizeMake(0, 2), 2.0);
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    //draw rect
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:10.0];
    [roundedRect fill];
    
    // draw circle
    CGFloat circleWidth = width / 3 + 10;
    _circleRadius = circleWidth / 8;
    CGFloat circleX = CGRectGetMidX(origRect) - (circleWidth / 2);
    CGRect circleRect = CGRectMake(circleX, y + 10, circleWidth, circleWidth);
    _circleContainer = circleRect;
    
    _circleY = CGRectGetMidY(circleRect) - _circleRadius;
    
    
    
    
    
    CGFloat colors [] = {
        0.054, 0.464, 0.998, 1.0,
        0.537, 0.184, 1.0, 1.0
    };
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGContextSaveGState(ref);
    CGContextAddEllipseInRect(ref, circleRect);
    CGContextClip(ref);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(circleRect), CGRectGetMinY(circleRect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(circleRect), CGRectGetMaxY(circleRect));
    
    CGContextDrawLinearGradient(ref, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient), gradient = NULL;
    
    CGContextRestoreGState(ref);
    
    CGContextAddEllipseInRect(ref, circleRect);
    
    
    
    
    
    
    
//    CGContextSetFillColorWithColor(ref, [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000].CGColor);
//    
//    CGContextFillEllipseInRect(ref, circleRect);
    
    [self startAnimating];
}

@end
