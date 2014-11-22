//
//  AppDelegate.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "PULAccount.h"

#import "PULConstants.h"

#import "PULLoginViewController.h"
#import "PULPullListViewController.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Firebase/Firebase.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    NSString *vcName;
    
    // check if we are logged in
    Firebase *ref = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    if (ref.authData)
    {
        vcName = NSStringFromClass([PULPullListViewController class]);

        PULLog(@"opening active fb session");
        [FBSession openActiveSessionWithReadPermissions:@[@"email", @"public_profile", @"user_friends"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          // TODO: validate that session is open and valid
                                          PULLog(@"opened session");
                                          [[PULAccount currentUser] loginWithFacebookToken:session.accessTokenData.accessToken completion:nil];
                                      }];
    }
    else
    {
        vcName = NSStringFromClass([PULLoginViewController class]);
    }
    
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:vcName];
    
    [self.window setRootViewController:vc];
    [self.window makeKeyAndVisible];
    
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
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Facebook
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

@end
