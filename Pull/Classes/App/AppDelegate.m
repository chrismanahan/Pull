//
//  AppDelegate.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "PULLoginViewController.h"
#import "PULPullListViewController.h"

#import "PULNoConnectionView.h"
#import "PULLocalPush.h"

#import "PULUpdateChecker.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    [Fabric with:@[CrashlyticsKit]];
    
    //    // register for remote notifications
    //    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
    //        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
    //                                                                                             |UIRemoteNotificationTypeSound
    //                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
    //        [application registerUserNotificationSettings:settings];
    //    } else {
    //        // FIX: < iOS8 doesn't register for push
    //        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
    //        [application registerForRemoteNotificationTypes:myTypes];
    //    }
    
    
    //    [[FBSDKApplicationDelegate sharedInstance] loadCache];
    
    // start parse
    [Parse setApplicationId:@"god9ShWzf5pq0wgRtKsIeTDRpFidspOOLmOxjv5g" clientKey:@"iIruWYgQqsurRYsLYsqT8GJjkYJX4UWlBJXVTjO0"];
    [PFFacebookUtils initializeFacebook];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    __block NSString *vcName = NSStringFromClass([PULLoginViewController class]);
    
    // check if we are logged in
    if ([PULAccount currentUser])
    {
        vcName = NSStringFromClass([PULPullListViewController class]);
    }
    else /*not logged in*/
    {
        vcName = NSStringFromClass([PULLoginViewController class]);
    }
    
    
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:vcName];
    
    
    [self.window setRootViewController:vc];
    [self.window makeKeyAndVisible];
    
    
    UIView *launchOverlay = [[NSBundle mainBundle] loadNibNamed:@"LaunchScreen"
                                                          owner:nil
                                                        options:nil][0];
    [self.window addSubview:launchOverlay];
 
    [UIView animateWithDuration:0.5
                          delay:0.2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame = launchOverlay.frame;
                         frame.origin.y = -CGRectGetHeight(frame);
                         launchOverlay.frame = frame;
                     } completion:^(BOOL finished) {
                         [launchOverlay removeFromSuperview];
                     }];

    
    // check if we need to notify the user of an update
    [PULUpdateChecker checkForUpdate];
    
    // start watching for nearby notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:PULPullNearbyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * note) {
                                                      // notify user that friend is nearby if we're in the background
                                                      UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
                                                      if (appState != UIApplicationStateActive)
                                                      {
                                                          PULPull *pull = [note object];
                                                          NSString *alertMessage = [NSString stringWithFormat:@"%@ is nearby!", [pull otherUser].firstName];
                                                          [PULLocalPush sendLocalPushWithMessage:alertMessage];
                                                      }
                                                  }];
    
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    //    if ([PULAccountOld currentUser].uid)
    //    {
    //        [[PULAccountOld currentUser] goOnline];
    //    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
    
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

#pragma mark - Push notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"did register for remote notifs");
    
    if (deviceToken)
    {
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"DeviceToken"];
        
        if ([PULAccount currentUser].uid)
        {
            PULLog(@"saving device token");
            [PULAccount currentUser].deviceToken = [deviceToken hexadecimalString];
            [[PULAccount currentUser] saveKeys:@[@"deviceToken"]];
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"did fail to register for remote notifs: %@", error.localizedDescription);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"did receive notif");
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"did register user notif settings");
    
    [application registerForRemoteNotifications];
}

@end