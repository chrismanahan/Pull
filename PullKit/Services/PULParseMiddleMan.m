//
//  PULParseMiddleMan.m
//  Pull
//
//  Created by Chris M on 9/26/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULParseMiddleMan.h"

#import "PFQuery+PullQueries.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

const NSTimeInterval kPULIntervalTimeFrequent   = 5;
const NSTimeInterval kPULIntervalTimeModerate   = 20;
const NSTimeInterval kPULIntervalTimeOccasional = 45;
const NSTimeInterval kPULIntervalTimeSeldom     = 120;
const NSTimeInterval kPULIntervalTimeRare       = 5 * 60;

NSString * const kPULFriendTypeFacebook = @"fb";

NSString * const PULParseObjectsUpdatedLocationsNotification = @"PULParseObjectsUpdatedLocationsNotification";
NSString * const PULParseObjectsUpdatedPullsNotification = @"PULParseObjectsUpdatedPullsNotification";

@interface PULParseMiddleMan ()

@property (nonatomic, strong) NSCache *cache;

@property (nonatomic, strong) NSMutableDictionary *locationTimers;
@property (nonatomic, strong) NSTimer *observerTimerPulls;
@property (nonatomic, strong) NSTimer *observerTimerLocations;

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
        _locationTimers = [[NSMutableDictionary alloc] init];
        _cache = [[NSCache alloc] init];
        
        [self _startMonitoringPullsInBackground:NO];
        [self _startMonitoringPulledLocationsInBackground:NO];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          // observe locations of pulled users
                                                          [self _stopMonitoringPulls];
                                                          [self _stopMonitoringPulledLocations];
                                                          
                                                          [self _startMonitoringPullsInBackground:YES];
                                                          [self _startMonitoringPulledLocationsInBackground:YES];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          // observe locations of pulled users
                                                          [self _stopMonitoringPulls];
                                                          [self _stopMonitoringPulledLocations];
                                                          
                                                          [self _startMonitoringPullsInBackground:NO];
                                                          [self _startMonitoringPulledLocationsInBackground:NO];
                                                      }];
        
    }
    return self;
}

- (PULUser*)currentUser;
{
    return [PULUser currentUser];
}

- (void)_observerTimerTick:(NSTimer*)timer
{
    if ([timer isEqual:_observerTimerPulls])
    {
        // refresh pulls
        [self getPullsInBackground:^(NSArray<PULPull *> * _Nullable pulls, NSError * _Nullable error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedPullsNotification
                                                                object:nil];
        } ignoreCache:YES];
    }
    else if ([timer isEqual:_observerTimerLocations])
    {
        // refresh locations
        NSMutableArray *locations = [[NSMutableArray alloc] init];
        for (PULPull *pull in [self cachedPulls])
        {
            [locations addObject:[pull otherUser].location];
        }
        
        if (locations.count > 0)
        {
            [PFObject fetchAll:locations];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedLocationsNotification
                                                                object:nil];
        }
    }
}

- (void)_startMonitoringPullsInBackground:(BOOL)inBackground
{
    [self _startObserverTimer:_observerTimerPulls inBackground:inBackground];
}

- (void)_startMonitoringPulledLocationsInBackground:(BOOL)inBackground
{
    [self _startObserverTimer:_observerTimerLocations inBackground:inBackground];
}

- (void)_startObserverTimer:(NSTimer*)timer inBackground:(BOOL)background
{
    NSAssert(timer == nil, @"observer timer already set. should be stopped first");
    timer = [NSTimer
             scheduledTimerWithTimeInterval:background ? kPULPollTimeBackground : kPULPollTimePassive
             target:self
             selector:@selector(_observerTimerTick:)
             userInfo:nil
             repeats:YES];
}



- (void)_stopMonitoringPulls
{
    [self _stopObserverTimer:_observerTimerPulls];
}

- (void)_stopMonitoringPulledLocations
{
    [self _stopObserverTimer:_observerTimerLocations];
}

- (void)_stopObserverTimer:(NSTimer*)timer
{
    NSAssert(timer != nil, @"timer doesn't exist");
    [timer invalidate];
    timer = nil;
}



- (void)_addPullToCache:(PULPull*)pull
{
    NSMutableArray *pulls = [_cache objectForKey:@"pulls"];
    [pulls addObject:pull];
    [self _setPullCache:pulls];
}

- (void)_setPullCache:(NSArray*)pulls
{
    [_cache setObject:pulls forKey:@"pulls"];
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
        PFQuery *query = [PFQuery queryLookupFriends];
        NSError *err;
        NSArray *objects = [query findObjects:&err];
        NSArray *users = [self _usersFromLookupResults:objects];
        
        [self _runBlockOnMainQueue:^{
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
    }];
}

- (void)getBlockedUsersInBackground:(PULUsersBlock)completion
{
    PFQuery *query = [PFQuery queryLookupBlocked];
    
    [self _runBlockInBackground:^{
        NSError *err;
        NSArray *objects = [query findObjects:&err];
        NSArray *users = [self _usersFromLookupResults:objects];
        
        [self _runBlockOnMainQueue:^{
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
    [self getPullsInBackground:completion ignoreCache:NO];
}

- (void)getPullsInBackground:(nullable PULPullsBlock)completion ignoreCache:(BOOL)ignoreCache;
{
    if ([self cachedPulls] && !ignoreCache)
    {
        completion([self cachedPulls], nil);
    }
    
    [self _runBlockInBackground:^{
        PFQuery *query  = [PFQuery queryLookupPulls];
        NSError *err;
        NSArray *objs = [query findObjects:&err];
        
        for (PULPull *pull in objs)
        {
            PULUser *otherUser = [pull otherUser];
            [otherUser.location fetchIfNeeded];
        }
        
        // set these pulls into the cache
        [self _setPullCache:objs];
        
        [self _runBlockOnMainQueue:^{
            completion(objs, err);
        }];
    }];
    
}

- (NSArray<PULPull*>*)cachedPulls
{
    return [_cache objectForKey:@"pulls"];
}

- (nullable PULPull*)nearestPull
{
    return nil;
}

#pragma mark - Location
- (void)updateLocation:(CLLocation*)location movementType:(PKMotionType)moveType positionType:(PKPositionType)posType
{
    PULLocation *loc = [PULUser currentUser].location;
    BOOL saveUser = NO;
    
    if (!loc)
    {
        loc = [PULLocation object];
        saveUser = YES;
    }
    
    loc.lat = location.coordinate.latitude;
    loc.lon = location.coordinate.longitude;
    loc.alt = location.altitude;
    loc.accuracy = location.horizontalAccuracy;
    loc.course = location.course;
    loc.speed = location.speed;
    loc.movementType = moveType;
    loc.positionType = posType;
    
    [loc saveEventually];
    
    if (saveUser)
    {
        [PULUser currentUser].location = loc;
        [[PULUser currentUser] saveEventually];
    }
}

#pragma mark - Observing changes
- (void)observeChangesInLocationForUser:(PULUser*)user interval:(NSTimeInterval)interval target:(id)target selecter:(SEL)selector;
{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(_tickObserverTimer:)
                                                    userInfo:user
                                                     repeats:YES];
    
    
//    [self stopObservingChangesInLocationForUser:user];
    
    _locationTimers[user.username] = @{@"timer": timer,
                                       @"target": target,
                                       @"selector": [NSValue valueWithPointer:selector]};
}

- (void)stopObservingChangesInLocationForUser:(PULUser*)user
{
    if (_locationTimers[user.username])
    {
        [((NSTimer*)_locationTimers[user.username][@"timer"]) invalidate];
        [_locationTimers removeObjectForKey:user.username];
    }
}

- (void)stopObservingChangesInLocationForAllUsers
{
    for (NSDictionary *dict in _locationTimers)
    {
        NSTimer *timer = dict[@"timer"];
        [timer invalidate];
    }
    [_locationTimers removeAllObjects];
}

- (void)_tickObserverTimer:(NSTimer*)timer
{
    PULUser *user = [timer userInfo];
    
    [user.location fetch];
    
    NSString *key = user.username;
    NSDictionary *dict = _locationTimers[key];
    
    SEL selector = [dict[@"selector"] pointerValue];
    id target = dict[@"target"];
    
    [target performSelector:selector];
}

#pragma mark - Pulls
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration completion:(nullable PULStatusBlock)completion
{
    [self getPullsInBackground:^(NSArray<PULPull *> * _Nullable pulls, NSError * _Nullable error) {
        if (error)
        {
            completion(NO, error);
            return;
        }
        
        if (pulls)
        {
            for (PULPull *pull in pulls)
            {
                if ([pull containsUser:user])
                {
                    // pull already exists with this user
                    completion(NO, nil);
                    return;
                }
            }
        }
        
        [self _runBlockInBackground:^{
            // create new pull
            PULPull *pull = [PULPull object];
            pull.sendingUser = [PULUser currentUser];
            pull.receivingUser = user;
            pull.status = PULPullStatusPending;
            pull.duration = duration;
            pull.canDelete = NO;
            pull.together = NO;
            
            PFACL *acl = [PFACL ACL];
            [acl setPublicReadAccess:NO];
            [acl setWriteAccess:YES forUser:[PULUser currentUser]];
            [acl setWriteAccess:YES forUser:user];
            
            [self _runBlockOnMainQueue:^{
                completion([pull save], nil);;
            }];
        }];
    }];
}

- (void)acceptPull:(PULPull*)pull
{
    NSAssert([pull.receivingUser isEqual:[PULUser currentUser]], @"can only accept a pull if we're the receiver");
    [self _runBlockInBackground:^{
        pull.status = PULPullStatusPulled;
        pull.expiration = [NSDate dateWithTimeIntervalSinceNow:pull.duration];
        [pull save];

    }];
}

- (void)deletePull:(PULPull*)pull
{
    // remove from cache
    NSMutableArray *pulls = [[self cachedPulls] mutableCopy];
    [pulls removeObject:pull];
    [_cache setObject:pulls forKey:@"pulls"];
    
    // delete from parse
    [pull deleteEventually];
}

#pragma mark - Private
#pragma mark Parsing Results
- (NSArray<PULUser*>*)_usersFromLookupResults:(NSArray<PFObject*>*)objects
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (PFObject *obj in objects)
    {
        PULUser *otherUser = [self _friendLookupOtherUser:obj];
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
        PFQuery *lookup = block ? [PFQuery queryLookupFriends] : [PFQuery queryLookupBlocked];
        
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
                     [[PULParseMiddleMan  sharedInstance] friendUsers:objects];
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
    [self _runBlock:block onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)_runBlockOnMainQueue:(void(^)())block
{
    [self _runBlock:block onQueue:dispatch_get_main_queue()];
}

- (void)_runBlock:(void(^)())block onQueue:(dispatch_queue_t)queue
{
    dispatch_async(queue, ^{
        block();
    });
}

@end
