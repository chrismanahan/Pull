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
    if (self = [super initWithFrame:CGRectMake(0, 0, width, kPULSectionHeaderHeight)])
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, kPULSectionHeaderHeight - 2)];
        label.text = title;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont fontWithName:@"Avenir" size:16];
        
        self.backgroundColor = [UIColor colorWithRed:0.455 green:0.000 blue:0.998 alpha:1.000];
        [self addSubview:label];
    }
    
    return self;
}

@end
