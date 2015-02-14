//
//  PULSectionHeader.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULSectionHeader.h"

const CGFloat kPULSectionHeaderHeight = 25;

@implementation PULSectionHeader

- (instancetype)initWithTitle:(NSString*)title width:(CGFloat)width
{
    NSInteger padding = 12;

    if (self = [super initWithFrame:CGRectMake(padding, 0, width - (2 * padding), kPULSectionHeaderHeight)])
    {
        
        UIColor *color;
        if ([title isEqualToString:@"Pulled"])
        {
            color = [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000];
        }
        else
        {
            color = [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
        }
        
        // line
//        NSInteger lineHeight = 4;
//        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(padding, kPULSectionHeaderHeight - lineHeight, width - (2 * padding), lineHeight)];
//        line.backgroundColor = color;
        
        // label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, kPULSectionHeaderHeight - 2)];
        label.text = title;
        label.textColor = color;
        label.font = [UIFont fontWithName:@"Avenir" size:16];
        [label sizeToFit];
        
        CGPoint center = label.center;
        center.x = CGRectGetMidX(self.frame);
        label.center = center;

        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.7];
        
        [self addSubview:label];
//        [self addSubview:line];
        
    }
    
    return self;
}

@end
