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

#import "PULUpdateChecker.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [Fabric with:@[CrashlyticsKit]];

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

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    __block NSString *vcName = NSStringFromClass([PULLoginViewController class]);
    
    // check if we are logged in
//    Firebase *ref = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    NSData *tokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBToken"];
    FBSDKAccessToken *facebookAccessToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];;// [FBSDKAccessToken currentAccessToken];
    if (facebookAccessToken)
    {
        vcName = NSStringFromClass([PULPullListViewController class]);
        [PULAccount loginWithFacebookToken:facebookAccessToken completion:^(PULAccount *account, NSError *error) {
            if (error)
            {
                vcName = NSStringFromClass([PULLoginViewController class]);
                
                UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:vcName];
                
                
                [self.window setRootViewController:vc];
                [self.window makeKeyAndVisible];
            }
        }];
    }
    else
    {
        vcName = NSStringFromClass([PULLoginViewController class]);
    }
    
    
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:vcName];

    
    [self.window setRootViewController:vc];
    [self.window makeKeyAndVisible];
    
    [PULNoConnectionView startMonitoringConnection];
    [PULUpdateChecker checkForUpdate];

    
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