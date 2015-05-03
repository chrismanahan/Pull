//
//  PULAccountOld.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULAccount.h"

#import "FireSync.h"

#import "PULConstants.h"

#import "NSDate+Utilities.h"

#import <Firebase/Firebase.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

NSString * const PULAccountDidLoginNotification = @"PULAccountDidLoginNotification";

const NSTimeInterval kPruneTimerInterval = 5.0;

@interface PULAccount ()

@property (nonatomic, strong) NSMutableArray *observers;

@property (nonatomic, strong) NSTimer *pruneTimer;

@end

@implementation PULAccount

static PULAccount *account = nil;

+ (instancetype)initializeCurrentUser:(NSString*)uid withAuthData:(FAuthData*)authData
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        account = [[PULAccount alloc] initEmptyWithUid:uid];
        [account initialize];
        
        NSDictionary *providerData = authData.providerData;
        
        NSString *displayName = providerData[@"displayName"];
        if (displayName)
        {
            NSRegularExpression *firstRegex = [NSRegularExpression regularExpressionWithPattern:@"^(\\w+)"
                                                                                        options:NSRegularExpressionCaseInsensitive
                                                                                          error:nil];
            
            // TODO: decide if we want to include middle names
            NSString *lastNameOnlyPattern = @"(?<= )(\\w+)$";
            //        NSString *fullDisplayNameWithoutFirst = @"((?<= )\\w+)( \\w+)+$";
            NSRegularExpression *lastRegex = [NSRegularExpression regularExpressionWithPattern:lastNameOnlyPattern
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
            
            NSRange firstRange = [[firstRegex firstMatchInString:displayName options:0 range:NSMakeRange(0, displayName.length)] range];
            NSRange lastRange = [[lastRegex firstMatchInString:displayName options:0 range:NSMakeRange(0, displayName.length)] range];
            
            account.firstName = [displayName substringWithRange:firstRange];
            account.lastName = [displayName substringWithRange:lastRange];
        }
    
        // find friends on pull
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=friends" parameters:nil];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            if (error)
            {
                PULLog(@"ERROR: %@", error.localizedDescription);
            }
            else
            {
                
                NSArray *friends = ((NSDictionary*)result)[@"friends"][@"data"];
                PULLog(@"got %zd friends from facebook", friends.count);
                
                for (NSDictionary *friend in friends)
                {
                    NSString *fbId = friend[@"id"];
                    NSString *userUID = [NSString stringWithFormat:@"facebook:%@", fbId];
                    
                    PULUser *user = [[PULUser alloc] initWithUid:userUID];
                    
                    [[PULAccount currentUser].friends addAndSaveObject:user];
                }
            }
            // check if this is the first registration
            BOOL newUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"UserIsRegisteredKey"];
            if (newUser)
            {
                account.fbId = providerData[@"id"];
                account.email = providerData[@"email"];
                
                // initialize settings
                account.settings = [PULUserSettings defaultSettings];
                
                [account saveAll];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UserIsRegisteredKey"];
            }
            else
            {
                [account saveKeys:@[@"firstName", @"lastName"]];
                
                [PULAccount initializeCurrentUser:uid];
            }
        }];
    
        [CrashlyticsKit setUserIdentifier:uid];
    });
    return account;
}

+ (instancetype)initializeCurrentUser:(NSString*)uid
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        account = [[PULAccount alloc] initWithUid:uid];
        [account initialize];
        
        [CrashlyticsKit setUserIdentifier:uid];
    });
    
    return account;
}

+ (instancetype)currentUser;
{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (!account)
//        {
//            account = [[PULAccount alloc] init];
//        }
//    });
//    
//    return account;
    
    return account;
}

- (void)initialize
{
    [super initialize];
    if (!_pruneTimer)
    {
        _pruneTimer = [NSTimer scheduledTimerWithTimeInterval:kPruneTimerInterval
                                                       target:self
                                                     selector:@selector(pruneExpiredPulls)
                                                     userInfo:nil
                                                      repeats:YES];
        

    }
    
    if (!_observers)
    {
        _observers = [[NSMutableArray alloc] init];
    }
    
    [self addNewFriendsFromFacebook];
}

- (void)pruneExpiredPulls
{
    PULLog(@"Checking for expired pulls");
    if (self.pulls.count > 0 && self.pulls.isLoaded)
    {
        [self.pulls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PULPull *pull = obj;
            
            if ([pull.expiration isInPast] && pull.duration != kPullDurationAlways)
            {
                PULLog(@"pruning pull: %@", pull);
                [self cancelPull:pull];
            }
        }];
    }
}

#pragma mark - Authentication
- (void)logout;
{
    [[FireSync sharedSync] unauth];
}

+ (void)loginWithFacebookToken:(FBSDKAccessToken*)accessToken completion:(void(^)(PULAccount *account, NSError *error))completion;
{
    PULLog(@"Logging in with facebook token");
    
    [[FireSync sharedSync] loginToProvider:@"facebook"
                               accessToken:accessToken.tokenString
                                completion:^(NSError *error, FAuthData *authData) {
                                    if (error)
                                    {
                                        PULLog(@"error logging in: %@", error.localizedDescription);
                                        if (completion)
                                        {
                                            completion(nil, error);
                                        }
                                    }
                                    else
                                    {
                                        PULLog(@"logged in with facebook");
                                        
                                        [PULAccount initializeCurrentUser:authData.uid];
                                        
                                        if (completion)
                                        {
                                            completion([PULAccount currentUser], nil);
                                        }
                                        
                                        [[NSNotificationCenter defaultCenter] postNotificationName:PULAccountDidLoginNotification object:self];
                                    }
                                }];
    
}

#pragma mark - Pulling

- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration;
{
    [self sendPullToUser:user duration:duration caption:nil];
}

- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration caption:(NSString*)caption;
{
    PULLog(@"sending pull to: %@", user);
    // create pull
    PULPull *pull = [[PULPull alloc] initNewBetween:self and:user duration:duration];
    if (caption)
    {
        pull.caption = caption;
    }
    [pull saveAll];
    
    // add pull to my pulls
    [self willChangeValueForKey:@"pulls"];
    [self.pulls addAndSaveObject:pull];
    [self didChangeValueForKey:@"pulls"];
    
    // add pull to friend's pulls
    [user.pulls addAndSaveObject:pull];
}

- (void)acceptPull:(PULPull*)pull;
{
    PULLog(@"accepting pull: %@", pull);
    pull.status = PULPullStatusPulled;
    [pull resetExpiration];
    [pull saveKeys:@[@"status", @"expiration"]];
}

- (void)cancelPull:(PULPull*)pull;
{
    PULLog(@"canceling/removing pull: %@", pull);
    
    // remove pull from my pulls
    [self willChangeValueForKey:@"pulls"];
    [self.pulls removeAndSaveObject:pull];
    [self didChangeValueForKey:@"pulls"];
    
    // remove pull from friend's pulls
    if (pull.hasLoaded)
    {
        PULUser *friend = [pull otherUser:self];
        
        if (friend.hasLoaded)
        {
            [friend willChangeValueForKey:@"pulls"];
            [friend.pulls removeAndSaveObject:pull];
            [friend didChangeValueForKey:@"pulls"];
            
            [pull deleteObject];
        }
    }
    else
    {
        id obs = [THObserver observerForObject:pull keyPath:@"loaded" oldAndNewBlock:^(id oldValue, id newValue) {
            PULUser *friend = [pull otherUser:self];
            if (friend)
            {
                [friend willChangeValueForKey:@"pulls"];
                [friend.pulls removeAndSaveObject:pull];
                [friend didChangeValueForKey:@"pulls"];
                [pull deleteObject];
                
                [_observers removeObject:obs];
            }
        }];
        
        [_observers addObject:obs];
    }
}

#pragma mark - Friend Management
- (void)blockUser:(PULUser*)user;
{
    NSAssert(![self.blocked containsObject:user], @"blocked users already contains this user");
    
    PULLog(@"blocking user: %@", user);
    
    // add this user to blocked
    [self willChangeValueForKey:@"blocked"];
    [self.blocked addAndSaveObject:user];
    [self didChangeValueForKey:@"blocked"];
    
    // remove this user from friends
    [self willChangeValueForKey:@"friends"];
    [self.friends removeAndSaveObject:user];
    [self didChangeValueForKey:@"friends"];

}

- (void)unblockUser:(PULUser*)user;
{
    NSAssert([self.blocked containsObject:user], @"blocked users already contains this user");
    
    PULLog(@"unblocking user: %@", user);
    
    // remove this user from blocked
    [self willChangeValueForKey:@"blocked"];
    [self.blocked removeAndSaveObject:user];
    [self didChangeValueForKey:@"blocked"];
    
    // add user back to friends
    [self willChangeValueForKey:@"friends"];
    [self.friends addAndSaveObject:user];
    [self didChangeValueForKey:@"friends"];
}

- (void)addUser:(PULUser*)user;
{
    if (![self.friends containsObject:user] && ![self.blocked containsObject:user])
    {
        PULLog(@"adding user: %@", user);
        
        // add friend to friend list
        [self willChangeValueForKey:@"friends"];
        [self.friends addAndSaveObject:user];
        [self didChangeValueForKey:@"friends"];
        
        // TODO: BUG: not saving to friend's array because friend has not fully loaded yet so the array is nil
        // add self to friend's friends list
        [user willChangeValueForKey:@"friends"];
        [user.friends addAndSaveObject:self];
        [user didChangeValueForKey:@"friends"];
    }
    else
    {
        PULLog(@"tried to add user %@, but user already exists in friends or blocked array", user);
    }
}

- (void)addNewFriendsFromFacebook;
{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=friends" parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error)
        {
            PULLog(@"ERROR requesting friends from facebook: %@", error.localizedDescription);
        }
        else
        {
            NSArray *friends = ((NSDictionary*)result)[@"friends"][@"data"];
            PULLog(@"got %zd friends from facebook", friends.count);
            
            for (NSDictionary *friend in friends)
            {
                NSString *fbId = friend[@"id"];
                NSString *uid = [NSString stringWithFormat:@"facebook:%@", fbId];
                
                PULUser *user = [[PULUser alloc] initWithUid:uid];
                if (![self.friends containsObject:user] && ![self.blocked containsObject:user])
                {
                    PULLog(@"adding new friend: %@", user);
                    [self addUser:user];
                }
            }
        }
    }];
    

}

#pragma mark - Helpers
- (NSArray*)pullsPending;
{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.pulls.count];
    
    for (PULPull *pull in self.pulls)
    {
        if (pull.status == PULPullStatusPending && ![pull initiatedBy:self])
        {
            [arr addObject:pull];
        }
    }
    
    return arr;
}

- (NSArray*)pullsWaiting;
{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.pulls.count];
    
    for (PULPull *pull in self.pulls)
    {
        if (pull.status == PULPullStatusPending && [pull initiatedBy:self])
        {
            [arr addObject:pull];
        }
    }
    
    return arr;

}

- (NSArray*)pullsPulledNearby;
{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.pulls.count];
    
    for (PULPull *pull in self.pulls)
    {
        if (pull.status == PULPullStatusPulled)
        {
            PULUser *friend = [pull otherUser:self];
            CGFloat distance = [friend.location distanceFromLocation:self.location];
            
            if (distance <= kPULNearbyDistance)
            {
                [arr addObject:pull];
            }
        }
    }
    
    return arr;

}

- (NSArray*)pullsPulledFar;
{
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:self.pulls.count];
    
    for (PULPull *pull in self.pulls)
    {
        if (pull.status == PULPullStatusPulled)
        {
            PULUser *friend = [pull otherUser:self];
            CGFloat distance = [friend.location distanceFromLocation:self.location];
            
            if (distance > kPULNearbyDistance)
            {
                [arr addObject:pull];
            }
        }
    }
    
    return arr;

}

#pragma mark - Fireable Protocol

- (NSDictionary*)firebaseRepresentation
{
    return [super firebaseRepresentation];
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    [super loadFromFirebaseRepresentation:repr];
}

@end
