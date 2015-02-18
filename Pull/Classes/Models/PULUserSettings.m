//
//  PULUserSettings.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserSettings.h"

@implementation PULUserSettings

- (instancetype)initFromFirebase:(NSDictionary*)dict;
{
    if (self = [super init])
    {
        NSDictionary *notifs = dict[@"notification"];
        _notifyAccept = notifs ? [notifs[@"accept"] boolValue] : YES;   // set default values if not set
        _notifyInvite = notifs ? [notifs[@"invite"] boolValue] : YES;
        
        _disabled = [dict[@"isDisabled"] boolValue]; 
    }
    
    return self;
}

@end
