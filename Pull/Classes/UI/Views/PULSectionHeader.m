//
//  PULSectionHeader.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULSectionHeader.h"

#import "UIVisualEffectView+PullBlur.h"

const CGFloat kPULSectionHeaderHeight = 20;

@implementation PULSectionHeader

- (instancetype)initWithTitle:(NSString*)title width:(CGFloat)width
{
    if (self = [super initWithFrame:CGRectMake(0, 0, width, kPULSectionHeaderHeight)])
    {
        // TODO: move color to init parameter for section header
        UIColor *color;
        if ([title isEqualToString:@"Pulled"])
        {
            color = [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000];
        }
        else if ([title isEqualToString:@"Blocked"])
        {
            color = [UIColor colorWithRed:1.000 green:0.552 blue:0.007 alpha:1.000];
        }
        else if ([title isEqualToString:@"Friends"] || [title isEqualToString:@"Nearby"])
        {
            color = [UIColor blackColor];
        }
        else
        {
            color = [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
        }
        
        // label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, kPULSectionHeaderHeight - 2)];
        label.text = title;
        label.textColor = color;
        label.font = [UIFont systemFontOfSize:16];
        [label sizeToFit];
        
        CGPoint center = label.center;
        center.x = CGRectGetMidX(self.frame);
        center.y += 1;
        label.center = center;

        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.8];
        
        [self addSubview:label];
//        [self addSubview:line];
        
    }
    
    return self;
}

@end
