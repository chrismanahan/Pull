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
#import "PULPush.h"

#import "PULUpdateChecker.h"

#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "PULUser.h"
#import "PULParseMiddleMan.h"

#import "Amplitude.h"
#import <parkour/parkour.h>

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

    [Fabric with:@[[Crashlytics class]]];
    [[Amplitude instance] initializeApiKey:@"c055f7a8351346bb5dbb4c57b59531d2"];
    
    [Parse setApplicationId:@"god9ShWzf5pq0wgRtKsIeTDRpFidspOOLmOxjv5g" clientKey:@"iIruWYgQqsurRYsLYsqT8GJjkYJX4UWlBJXVTjO0"];
    [PFFacebookUtils initializeFacebook];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    __block NSString *vcName = NSStringFromClass([PULLoginViewController class]);
    
    // check if we are logged in
    if ([PULUser currentUser])
    {
        [[[PULParseMiddleMan sharedInstance] currentUser].location fetchIfNeededInBackground];
        vcName = NSStringFromClass([PULPullListViewController class]);
        
        // TODO: remove setting user settings when all dev devices updated
        if (![PULUser currentUser].userSettings)
        {
            [PULUser currentUser].userSettings = [PULUserSettings defaultSettings];
            [[PULUser currentUser].userSettings saveInBackground];
        }
        else
        {
            [[PULUser currentUser].userSettings fetchInBackground];
        }
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
    
    launchOverlay.frame = self.window.frame;
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
    
    [self startObservingBatteryLevel];
    
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                 didFinishLaunchingWithOptions:launchOptions];
}

- (void)startObservingBatteryLevel
{
    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = YES;
    
    [self batteryLevelDidChange:device.batteryLevel];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryLevelDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      float level = [UIDevice currentDevice].batteryLevel;
                                                      PULLog(@"received battery update: %.2f", level);
                                                      
                                                      [self batteryLevelDidChange:level];
                                                  }];
}

- (void)batteryLevelDidChange:(float)level
{
    PULUser *currentUser = [PULUser currentUser];
    if (!currentUser) { return ; }
    
    BOOL needsSave = NO;
    
    if (level < 0.02 && !currentUser.lowBattery)
    {
        currentUser.lowBattery = YES;
        needsSave = YES;
    }
    else if ((currentUser.lowBattery && level >= 0.02))
    {
        currentUser.lowBattery = NO;
        needsSave = YES;
    }
    
    if (needsSave)
    {
        [currentUser saveEventually];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    PULUser *user = [PULUser currentUser];
    if (user)
    {
        user.isInForeground = NO;
//        user[@"killed"] = @(YES);
        [user saveInBackground];
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            user[@"killed"] = @(NO);
//            [user saveInBackground];
//        });
    }
}
- (void)backgroundPing
{
    ;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {    
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    application.applicationIconBadgeNumber = 0;
    
    PULUser *user = [PULUser currentUser];
    if (user)
    {
        user.isInForeground = YES;
        user.killed = NO;
        [user saveInBackground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [PULUser currentUser].killed = YES;
    [[PULUser currentUser] save];
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