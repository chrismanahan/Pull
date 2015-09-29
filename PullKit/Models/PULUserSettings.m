//
//  PULUserSettings.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserSettings.h"

@implementation PULUserSettings

@dynamic notifyGone;
@dynamic notifyAccept;
@dynamic notifyInvite;
@dynamic notifyNearby;

+ (instancetype)defaultSettings;
{
    PULUserSettings *settings = [[PULUserSettings alloc] init];
    
    settings.notifyAccept = YES;
    settings.notifyInvite = YES;
    settings.notifyNearby = YES;
    settings.notifyGone = YES;
    
    return settings;
}

#pragma mark - Parse sublcass
+ (NSString*)parseClassName
{
    return @"UserSettings";
}

+ (void)load
{
    [self registerSubclass];
    [super load];
}

@end
