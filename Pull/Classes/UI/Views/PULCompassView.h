//
//  PULCompassView.h
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PULCompassView : UIView

@property (nonatomic, strong, readonly) PULUser *user;

- (void)setUser:(PULUser *)user;

@end
