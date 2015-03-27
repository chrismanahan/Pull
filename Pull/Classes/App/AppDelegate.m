//
//  AppDelegate.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "PULAccountOld.h"

#import "PULConstants.h"

#import "PULLoginViewController.h"
#import "PULPullListViewController.h"

#import "PULNoConnectionView.h"

#import "PULUpdateChecker.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Firebase/Firebase.h>
#import <Fabric/Fabric.h>

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
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    NSString *vcName;
    
    // check if we are logged in
    Firebase *ref = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    if (ref.authData)
    {
        vcName = NSStringFromClass([PULPullListViewController class]);
        FBSession *fbSesh = [FBSession activeSession];
        
        if (fbSesh.accessTokenData.accessToken && fbSesh.state == FBSessionStateOpen )
        {
            // i don't think this will actually ever get called. one day i'll figure out the whole fb login flow. just not now
            PULLog(@"logging in with existing session");
//            [ref authWithOAuthProvider:@"facebook" token:ref.authData.token withCompletionBlock:^(NSError *error, FAuthData *authData) {
                [[PULAccountOld currentUser] loginWithFacebookToken:[FBSession activeSession].accessTokenData.accessToken completion:nil];
//            }];
        }
        else if (fbSesh.state == FBSessionStateCreatedTokenLoaded)
        {
            
            PULLog(@"opening active fb session");
            [FBSession openActiveSessionWithReadPermissions:@[@"email", @"public_profile", @"user_friends"]
                                               allowLoginUI:NO
                                          completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                              if (!error)
                                              {
                                                  // TODO: validate that session is open and valid
                                                  PULLog(@"opened session");
                                                  [[PULAccountOld currentUser] loginWithFacebookToken:session.accessTokenData.accessToken completion:nil];
                                              }
                                              else
                                              {
                                                  PULLog(@"%@", error.localizedDescription);
                                              }
                                          }];
        }
        else
        {
            vcName = NSStringFromClass([PULLoginViewController class]);
        }
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
    
    return YES;
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
    
    if ([PULAccountOld currentUser].uid)
    {
        [[PULAccountOld currentUser] goOnline];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[FBSession activeSession] handleDidBecomeActive];
    
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

#pragma mark - Push notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"did register for remote notifs");
    
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"DeviceToken"];
    
    if ([PULAccountOld currentUser].uid)
    {
        [[PULAccountOld currentUser] writePushToken];
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