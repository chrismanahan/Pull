//
//  PULCompassView.h
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PULPull;

NS_ASSUME_NONNULL_BEGIN

@interface PULCompassView : UIView

@property (nonatomic, strong, readonly) PULPull *pull;

- (void)setPull:(nullable PULPull*)pull;
- (void)showNoLocation;

- (void)showBusy:(BOOL)busy;

@end

NS_ASSUME_NONNULL_END