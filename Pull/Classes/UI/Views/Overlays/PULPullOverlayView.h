//
//  PULPullOverlayView.h
//  Pull
//
//  Created by Chris M on 5/3/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULOverlayView.h"

#import "PULPull.h"

@interface PULPullOverlayView : PULOverlayView

@property (nonatomic, strong) PULPull *pull;

+ (void)overlayOnView:(UIView*)view withPull:(PULPull*)pull;

@end
