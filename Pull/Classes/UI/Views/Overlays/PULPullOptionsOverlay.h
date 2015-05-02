//
//  PULPullOptionsOverlay.h
//  Pull
//
//  Created by Chris M on 4/30/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULOverlayView.h"

@class PULPull;

@interface PULPullOptionsOverlay : PULOverlayView

@property (nonatomic, strong) PULPull *pull;

+ (void)overlayOnView:(UIView*)view withPull:(PULPull*)pull;

@end
