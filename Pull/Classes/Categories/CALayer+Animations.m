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
    CAAnimation *existing = [self animationForKey:@"pop"];
    
    if (!existing)
    {
        [CATransaction begin]; {
            [CATransaction setCompletionBlock:^{
                [self removeAnimationForKey:@"pop"];
            }];
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            anim.duration = 0.1;
            anim.fromValue = @(1.0);
            anim.toValue = @(1.2);
            anim.autoreverses = YES;
            [self addAnimation:anim forKey:@"pop"];
        } [CATransaction commit];
        
    }
}

@end
