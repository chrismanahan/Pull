//
//  PULRequestNotificationsViewController.m
//  Pull
//
//  Created by admin on 2/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULRequestNotificationsViewController.h"

#import "PULPullListViewController.h"

@interface PULRequestNotificationsViewController ()

@end

@implementation PULRequestNotificationsViewController

- (IBAction)ibNext:(id)sender
{
    UIApplication *application = [UIApplication sharedApplication];
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    [self next];
}

- (void)next
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullListViewController class])];

    [self presentViewController:vc animated:YES completion:nil];
}


@end
