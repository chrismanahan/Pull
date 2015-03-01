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
    // register for remote notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        // FIX: < iOS8 doesn't register for push
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    
    [self next];
}

- (void)next
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullListViewController class])];

    [self presentViewController:vc animated:YES completion:nil];
}


@end
