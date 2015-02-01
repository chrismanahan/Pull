//
//  PULSectionHeader.h
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat kPULSectionHeaderHeight;

@interface PULSectionHeader : UIView

- (instancetype)initWithTitle:(NSString*)title width:(CGFloat)width;

@end
