//
//  CALayer+Animations.m
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "CALayer+Animations.h"

@implementation CALayer (Animations)

- (void)addPopAnimation
{
    [self addPopAnimationCompletion:nil];
}

- (void)addPopAnimationCompletion:(void(^)())completion;
{
    [self _addPopFrom:1.0 to:1.2 completion:completion];
}

- (void)_addPopFrom:(CGFloat)from to:(CGFloat)to completion:(void(^)())completion;
{
    CAAnimation *existing = [self animationForKey:@"pop"];
    
    if (!existing)
    {
        [CATransaction begin]; {
            [CATransaction setCompletionBlock:^{

                [self removeAnimationForKey:@"pop"];
                
                if (completion)
                {
                    completion();
                }
            }];
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            anim.duration = 0.1;
            anim.fromValue = @(from);
            anim.toValue = @(to);
            anim.autoreverses = YES;
            
            [self addAnimation:anim forKey:@"pop"];
        } [CATransaction commit];
    }
}

@end
