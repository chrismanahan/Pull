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
    _showing = YES;
    [_onView addSubview:self];
    [self setNeedsDisplay];
 
    
//    [self startAnimating];
//    [self.imageView startAnimating];
}

- (void)hide;
{
    _showing = NO;
    [self removeFromSuperview];
//    [self.imageView stopAnimating];
    [self stopAnimating];
}

- (void)startAnimating {
    if (!self.isAnimating) {
        
        self.hidden = NO;
        self.isAnimating = YES;
    }
}

- (void)stopAnimating {
    if (self.isAnimating) {

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


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
}

@end
