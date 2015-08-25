//
//  CALayer+Animations.h
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (Animations)

- (void)addPopAnimation;
- (void)addPopAnimationCompletion:(void(^)())completion;

@end
