//
//  PULCache.m
//  Pull
//
//  Created by Development on 10/19/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULCache.h"

@implementation PULCache

+ (instancetype)sharedCache
{
    static PULCache *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[[self class] alloc] init];
    });
    
    return shared;
}

@end
