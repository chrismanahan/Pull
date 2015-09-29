//
//  PULParseMiddleMan.m
//  Pull
//
//  Created by Chris M on 9/26/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULParseMiddleMan.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

const NSTimeInterval kPULIntervalTimeFrequent   = 5;
const NSTimeInterval kPULIntervalTimeModerate   = 20;
const NSTimeInterval kPULIntervalTimeOccasional = 45;
const NSTimeInterval kPULIntervalTimeSeldom     = 120;
const NSTimeInterval kPULIntervalTimeRare       = 5 * 60;

@implementation PULParseMiddleMan

+ (instancetype)sharedInstance;
{
    static PULParseMiddleMan *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PULUser registerSubclass];
        [Parse setApplicationId:@"god9ShWzf5pq0wgRtKsIeTDRpFidspOOLmOxjv5g" clientKey:@"iIruWYgQqsurRYsLYsqT8GJjkYJX4UWlBJXVTjO0"];
        [PFFacebookUtils initializeFacebook];
        
        shared = [[PULParseMiddleMan alloc] init];
    });
    
    return shared;
}

#pragma mark - Login
- (void)loginWithFacebook:(PULStatusBlock)completion
{
    PULLog(@"presenting facebook login");
    
    NSArray *permissions = @[@"email", @"public_profile", @"user_friends"];
    
    [PFFacebookUtils
     logInWithPermissions:permissions
     block:^(PFUser * _Nullable user, NSError * _Nullable error) {
         if (error || !user)
         {
             completion(NO, error);
         }
         else
         {
             [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                 if (!error)
                 {
                     [self _initializeUserInfo:(PULUser*)user fbResult:result completion:completion];
                 }
                 else
                 {
                     PULLog(@"COULD NOT GET FACEBOOK INFO: %@", error);
                     completion(NO, error);
                 }
             }];
         }
     }];

}

#pragma mark - Adding / Removing Friends
- (void)friendUsers:(nullable NSArray<PULUser*>*)users inBackground:(nullable PULStatusBlock)completion;
{
    if (users)
    {
        PFUser *currUser = [PFUser currentUser];
        for (PULUser *user in users)
        {
            PFObject *obj = [PFObject objectWithClassName:@"FriendLookup"];
            
            obj[@"sendingUser"] = currUser;
            obj[@"receivingUser"] = user;
            obj[@"type"] = @"friend";
            obj[@"isAccepted"] = @YES;
            [obj saveInBackground];
        }
        
        if (completion)
        {
            completion(YES, nil);
        }
    }
    else
    {
        completion(YES, nil);
    }
}

#pragma mark - Private

- (void)_initializeUserInfo:(PULUser*)user fbResult:(id)result completion:(void(^)(BOOL success, NSError *error))completion
{
    NSDictionary *fbData = (NSDictionary*)result;
    
    if (fbData[@"first_name"]) { user[@"firstName"] = fbData[@"first_name"]; }
    if (fbData[@"last_name"]) { user[@"lastName"] = fbData[@"last_name"]; }
    if (fbData[@"gender"] && [fbData[@"gender"] length] > 0) { user[@"gender"] = [fbData[@"gender"] substringToIndex:1]; }
    if (fbData[@"id"]) { user[@"fbId"] = fbData[@"id"]; }
    if (fbData[@"email"]) { user[@"email"] = fbData[@"email"]; }
    if (fbData[@"locale"]) { user[@"locale"] = fbData[@"locale"]; }
    user[@"username"] = [NSString stringWithFormat:@"fb:%@", user[@"fbId"]];
    
    [user saveInBackground];
    
    [[FBRequest requestForMyFriends]
     startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
         if (error)
         {
             PULLog(@"ERROR: %@", error.localizedDescription);
             
             completion(NO, error);
         }
         else
         {
             
             NSArray *friends = ((NSDictionary*)result)[@"data"];
             NSMutableArray *usernames = [[NSMutableArray alloc] init];
             PULLog(@"got %zd friends from facebook", friends.count);
             
             // derive and add usernames for each user
             for (NSDictionary *friend in friends)
             {
                 NSString *fbId = friend[@"id"];
                 NSString *username = [NSString stringWithFormat:@"fb:%@", fbId];
                 [usernames addObject:username];
             }
             
             // check if we have friends
             if (usernames.count > 0)
             {
                 // build query to get all these users
                 PFQuery *friendQuery = [PFUser query];
                 [friendQuery whereKey:@"username" containedIn:usernames];
                 [friendQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                     [[PULParseMiddleMan  sharedInstance] friendUsers:objects inBackground:^(BOOL success, NSError * _Nullable error) {
                         completion(success, error);
                     }];
                 }];
             }
             else
             {
                 // return nil
                 completion(NO, nil);
             }
         }
         
     }];
    
    
    //    // get friends from facebook
    //    [[PULParseMiddleMan sharedInstance] getFacebookFriendsAsUsers:^(NSArray<PULUser *> * _Nonnull users, NSError * _Nullable error) {
    //        // add fb friends as pull friends
    //        if (users)
    //        {
    //            [[PULParseMiddleMan  sharedInstance] friendUsers:users inBackground:^(BOOL success, NSError * _Nullable error) {
    //                completion(success, error);
    //            }];
    //        }
    //        else if (error)
    //        {
    //            completion(NO, error);
    //        }
    //        else
    //        {
    //            completion(YES, nil);
    //        }
    //    }];
}


@end
