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

NSString * const kPULFriendTypeFacebook = @"fb";

NSString * const kPULLookupSendingUserKey = @"sendingUser";
NSString * const kPULLookupReceivingUserKey = @"receivingUser";

@interface PULParseMiddleMan ()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation PULParseMiddleMan

+ (instancetype)sharedInstance;
{
    static PULParseMiddleMan *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        [PULUser registerSubclass];
        [Parse setApplicationId:@"god9ShWzf5pq0wgRtKsIeTDRpFidspOOLmOxjv5g" clientKey:@"iIruWYgQqsurRYsLYsqT8GJjkYJX4UWlBJXVTjO0"];
        [PFFacebookUtils initializeFacebook];
        
        shared = [[PULParseMiddleMan alloc] init];
    });
    
    return shared;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _cache = [[NSCache alloc] init];
    }
    return self;
}

- (PULUser*)currentUser;
{
    return [PULUser currentUser];
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
             if (user.isNew)
             {
                 [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                     if (!error)
                     {
                         [self _registerUser:(PULUser*)user withFbResult:result completion:completion];
                     }
                     else
                     {
                         PULLog(@"COULD NOT GET FACEBOOK INFO: %@", error);
                         completion(NO, error);
                     }
                 }];
             }
             else
             {
                 
             }
         }
     }];

}

#pragma mark - Getting Friends
- (void)getFriendsInBackground:(PULUsersBlock)completion
{
    [self _runBlockInBackground:^{
        PFQuery *query = [self _queryLookupFriends];
        NSError *err;
        NSArray *objects = [query findObjects:&err];
        NSArray *users = [self _usersFromLookupResults:objects];
        
        if (err)
        {
            completion(nil, err);
        }
        else
        {
            [_cache setObject:users forKey:@"friends"];
            completion(users, nil);
        }
    }];
}

- (void)getBlockedUsersInBackground:(PULUsersBlock)completion
{
    PFQuery *query = [self _queryLookupBlocked];
    
    [self _runBlockInBackground:^{
        NSError *err;
        NSArray *objects = [query findObjects:&err];
        NSArray *users = [self _usersFromLookupResults:objects];
        
        if (err)
        {
            completion(nil, err);
        }
        else
        {
            [_cache setObject:users forKey:@"blocked"];
            completion(users, nil);
        }
    }];
}


- (nullable NSArray<PULUser*>*)cachedFriends
{
    return [_cache objectForKey:@"friends"];
}

- (nullable NSArray<PULUser*>*)cachedBlockedUsers
{
    return [_cache objectForKey:@"blocked"];
}

#pragma mark - Adding / Removing Friends
- (void)friendUsers:(nullable NSArray<PULUser*>*)users
{
    if (users)
    {
        for (PULUser *user in users)
        {
            [self friendUser:user];
        }
    }
}

- (void)friendUser:(PULUser *)user
{
    PFUser *currUser = [PFUser currentUser];
    
    // TODO: check if user is already friends with this user
    PFObject *obj = [PFObject objectWithClassName:@"FriendLookup"];
    
    obj[@"sendingUser"] = currUser;
    obj[@"receivingUser"] = user;
    obj[@"type"] = kPULFriendTypeFacebook;
    obj[@"isAccepted"] = @YES;
    obj[@"isBlocked"] = @NO;
    obj[@"blockedBy"] = [NSNull null];
    
    [obj saveEventually];
}

- (void)blockUser:(PULUser*)user
{
    [self _block:YES user:user];
}

- (void)unblockUser:(PULUser*)user
{
    [self _block:NO user:user];
}

#pragma mark - Getting pulls
- (void)getPullsInBackground:(nullable PULPullsBlock)completion
{
    
}

- (NSArray<PULPull*>*)cachedPulls
{
    return nil;
}

- (nullable PULPull*)nearestPull
{
    return nil;
}


- (void)updateLocation:(CLLocation*)location movementType:(PKMotionType)moveType positionType:(PKPositionType)posType
{
    
}

- (void)updateLocation:(CLLocation*)location movementType:(PKMotionType)moveType positionType:(PKPositionType)posType completion:(nullable PULStatusBlock)completion
{
    
}

- (void)observeChangesInLocationForUser:(PULUser*)user interval:(NSTimeInterval)interval block:(PULUserBlock)block
{
    
}

- (void)stopObservingChangesInLocationForUser:(PULUser*)user
{
    
}

- (void)stopObservingChangesInLocationForAllUsers
{
    
}

- (void)sendPullToUser:(PULUser*)user completion:(nullable PULStatusBlock)completion
{
    
}



#pragma mark - Private
#pragma mark Queries
- (PFQuery*)_queryLookupFriends
{
    return [self _queryLookupUsersBlocked:NO];
}

- (PFQuery*)_queryLookupBlocked
{
    return [self _queryLookupUsersBlocked:YES];
}

- (PFQuery*)_queryLookupUsersBlocked:(BOOL)blocked
{
    PULUser *acct = [PULUser currentUser];
    
    // lookup queries
    PFQuery *senderQuery = [PFQuery queryWithClassName:@"FriendLookup"];
    [senderQuery whereKey:kPULLookupSendingUserKey equalTo:acct];
    [senderQuery whereKey:kPULLookupReceivingUserKey notEqualTo:acct];
    
    PFQuery *recQuery = [PFQuery queryWithClassName:@"FriendLookup"];
    [recQuery whereKey:kPULLookupReceivingUserKey equalTo:acct];
    [recQuery whereKey:kPULLookupSendingUserKey notEqualTo:acct];
    
    PFQuery *lookupQuery = [PFQuery orQueryWithSubqueries:@[senderQuery, recQuery]];
    [lookupQuery whereKey:@"isBlocked" equalTo:@(blocked)];
    if (blocked)
    {
        [lookupQuery whereKey:@"blockedBy" equalTo:acct];
    }
    [lookupQuery whereKey:@"isAccepted" equalTo:@YES];
    
    [lookupQuery includeKey:kPULLookupReceivingUserKey];
    [lookupQuery includeKey:kPULLookupSendingUserKey];

    return lookupQuery;
}

#pragma mark Parsing Results
- (NSArray<PULUser*>*)_usersFromLookupResults:(NSArray<PFObject*>*)objects
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (PFObject *obj in objects)
    {
        PFUser *otherUser = [self _friendLookupOtherUser:obj];
        [arr addObject:otherUser];
    }
    
    return arr;
}

- (BOOL)_friendLookup:(PFObject*)obj containsUser:(PULUser*)user;
{
    return [[self _friendLookupOtherUser:obj] isEqual:user];
}

- (PULUser*)_friendLookupOtherUser:(PFObject*)obj
{
    PULUser *otherUser;
    if (![obj[kPULLookupSendingUserKey] isEqual:[PULUser currentUser]])
    {
        otherUser = obj[kPULLookupSendingUserKey];
    }
    else
    {
        otherUser = obj[kPULLookupReceivingUserKey];
    }
    
    return otherUser;
}

#pragma mark Helpers
- (void)_block:(BOOL)block user:(PULUser*)user
{
    [self _runBlockInBackground:^{
        PFQuery *lookup = block ? [self _queryLookupFriends] : [self _queryLookupBlocked];
        
        NSArray *rows = [lookup findObjects];
        
        if (rows)
        {
            for (PFObject *obj in rows)
            {
                if ([self _friendLookup:obj containsUser:user])
                {
                    // found row to block
                    obj[@"isBlocked"] = @(block);
                    if (block)
                    {
                        obj[@"blockedBy"] = [PULUser currentUser];
                    }
                    else
                    {
                        obj[@"blockedBy"] = [NSNull null];
                    }
                    
                    [obj saveEventually];
                    
                    break;
                }
            }
        }
    }];
}

#pragma mark Registration
- (void)_registerUser:(PULUser*)user withFbResult:(id)result completion:(void(^)(BOOL success, NSError *error))completion
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
}

#pragma mark - Threading
- (void)_runBlockInBackground:(void(^)())block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block();
    });
}

@end
