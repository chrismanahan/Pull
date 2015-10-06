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

#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

#import "PULUser.h"
#import "PULParseMiddleMan.h"

#import <parkour/parkour.h>
#import "BackgroundTask.h"

@interface AppDelegate ()
{
    BackgroundTask *bgTask;
}

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
//    [PULUser registerSubclass];
//    [Parse setApplicationId:@"god9ShWzf5pq0wgRtKsIeTDRpFidspOOLmOxjv5g" clientKey:@"iIruWYgQqsurRYsLYsqT8GJjkYJX4UWlBJXVTjO0"];
//    [PFFacebookUtils initializeFacebook];

    [Parse setApplicationId:@"god9ShWzf5pq0wgRtKsIeTDRpFidspOOLmOxjv5g" clientKey:@"iIruWYgQqsurRYsLYsqT8GJjkYJX4UWlBJXVTjO0"];
    [PFFacebookUtils initializeFacebook];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    __block NSString *vcName = NSStringFromClass([PULLoginViewController class]);
    
    // check if we are logged in
    if ([[PULParseMiddleMan sharedInstance] currentUser])
    {
        [[[PULParseMiddleMan sharedInstance] currentUser].location fetchIfNeededInBackground];
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

    bgTask = [[BackgroundTask alloc] init];
    
    [PULUser currentUser].settings = [PULUserSettings defaultSettings];
    [[PULUser currentUser] saveInBackground];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PULPullNoLongerNearbyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * note) {
                                                      // notify user that friend is nearby if we're in the background
                                                      UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
                                                      if (appState != UIApplicationStateActive)
                                                      {
                                                          PULPull *pull = [note object];
                                                          NSString *alertMessage = [NSString stringWithFormat:@"%@ is no longer nearby", [pull otherUser].firstName];
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
    [bgTask startBackgroundTasks:2 target:self selector:@selector(backgroundPing)];
    
    PULUser *user = [PULUser currentUser];
    if (user)
    {
        user.isInForeground = NO;
        user[@"killed"] = @(YES);
        [user saveInBackground];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            user[@"killed"] = @(NO);
            [user saveInBackground];
        });
    }
}
- (void)backgroundPing
{
    ;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [bgTask stopBackgroundTask];
    
    PULUser *user = [PULUser currentUser];
    if (user)
    {
        user.isInForeground = YES;
        user[@"killed"] = @(NO);
        [user saveInBackground];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[PFFacebookUtils session] close];
}

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

#pragma mark - Push notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"did fail to register for remote notifs: %@", error.localizedDescription);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

@end