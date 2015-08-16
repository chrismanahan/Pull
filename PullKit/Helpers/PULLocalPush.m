//
//  PULLocalPush.m
//  Pull
//
//  Created by Chris M on 8/15/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULLocalPush.h"

#import <UIKit/UIKit.h>

@implementation PULLocalPush

+ (void)sendLocalPushWithMessage:(NSString*)message;
{
    [self sendLocalPushWithMessage:message delay:0];
}

+ (void)sendLocalPushWithMessage:(NSString*)message delay:(float)delay;
{
#ifndef PULLKIT
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    notif.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notif.soundName = UILocalNotificationDefaultSoundName;
    notif.alertBody = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
#endif
}

@end
