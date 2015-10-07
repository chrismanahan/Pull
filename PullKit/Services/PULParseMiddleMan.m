//
//  PULParseMiddleMan.m
//  Pull
//
//  Created by Chris M on 9/26/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULParseMiddleMan.h"

#import "PULPush.h"

#import "PFQuery+PullQueries.h"
#import "PFACL+Users.h"

#import "NSDate+Utilities.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <LinqToObjectiveC/NSArray+LinqExtensions.h>

const NSTimeInterval kPULIntervalTimeFrequent   = 5;
const NSTimeInterval kPULIntervalTimeModerate   = 20;
const NSTimeInterval kPULIntervalTimeOccasional = 45;
const NSTimeInterval kPULIntervalTimeSeldom     = 120;
const NSTimeInterval kPULIntervalTimeRare       = 5 * 60;

NSString * const kPULFriendTypeFacebook = @"fb";

NSString * const PULParseObjectsUpdatedLocationsNotification = @"PULParseObjectsUpdatedLocationsNotification";
NSString * const PULParseObjectsUpdatedPullsNotification = @"PULParseObjectsUpdatedPullsNotification";

@interface PULParseMiddleMan ()

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
        shared = [[PULParseMiddleMan alloc] init];
    });
    
    return shared;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _locationTimers = [[NSMutableDictionary alloc] init];
        
        _cache = [[PULCache alloc] init];
        
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

#pragma mark - Login
- (void)loginWithFacebook:(PULStatusBlock)completion
{
    PULLog(@"presenting facebook login");
    
    NSArray *permissions = @[@"email", @"public_profile", @"user_friends"];
    
    [PFFacebookUtils setFacebookLoginBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent];
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
                         [self _registerUser:(PULUser*)user withFbResult:result completion:^(BOOL success, NSError * _Nonnull error) {
                             
                             if (success)
                             {
                                 [PULPush subscribeToPushNotifications:[PULUser currentUser]];
                             }
                             completion(success, error);
                         }];
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
                 [PULPush subscribeToPushNotifications:[PULUser currentUser]];
                 completion(YES, error);
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
                [_cache setUsers:users];
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
                [_cache setBlockedUsers:users];
                completion(users, nil);
            }
        }];
    }];
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
    
    // set acl
    PFACL *acl = [PFACL ACLWithUser:[PULUser currentUser] and:user];
    obj.ACL = acl;
    
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
    if ([_cache cachedPullsOrdered] && !ignoreCache)
    {
        completion([_cache cachedPullsOrdered], nil);
    }
    
    [self _runBlockInBackground:^{
        PFQuery *query  = [PFQuery queryLookupPulls];
        NSError *err;
        NSMutableArray *objs = [[query findObjects:&err] mutableCopy];
        NSMutableIndexSet *flaggedIndexes = [[NSMutableIndexSet alloc] init];
        
        for (PULPull *pull in objs)
        {
            PULUser *otherUser = [pull otherUser];
            [otherUser.location fetchIfNeeded];
            
            if ([pull.expiration isInPast])
            {
                [flaggedIndexes addIndex:[objs indexOfObject:pull]];
            }
            else
            {
                // need to explicity set this user
                if ([pull.sendingUser isEqual:otherUser])
                {
                    pull.receivingUser = [PULUser currentUser];
                }
                else
                {
                    pull.sendingUser = [PULUser currentUser];
                }
            }
        }
        
        // remove expired pulls and delete
        NSArray *flaggedPulls = [objs objectsAtIndexes:flaggedIndexes];
        [objs removeObjectsAtIndexes:flaggedIndexes];
        
        if (flaggedPulls.count > 0)
        {
            for (PULPull *pull in flaggedPulls)
            {
                [self deletePull:pull];
            }
        }
        
        // set these pulls into the cache
        [_cache setPulls:objs];
        
        // run completion
        [self _runBlockOnMainQueue:^{
            completion(objs, err);
        }];
    }];
    
}

// TODO: refactor caches into their own class
#pragma mark - Cache


#pragma mark - Location
- (void)updateLocation:(CLLocation*)location movementType:(PKMotionType)moveType positionType:(PKPositionType)posType
{
    PULLocation *loc = [PULUser currentUser].location;
    BOOL saveUser = NO;
    
    if (!loc)
    {
        loc = [PULLocation object];
        
        PFACL *acl = [PFACL ACLWithUser:[PULUser currentUser]];
        [acl setPublicReadAccess:YES];
        loc.ACL = acl;
        
        saveUser = YES;
    }
    
    loc.coordinate = [PFGeoPoint geoPointWithLocation:location];
    loc.alt = location.altitude;
    loc.accuracy = location.horizontalAccuracy;
    loc.course = location.course;
    loc.speed = location.speed;
    loc.movementType = moveType;
    loc.positionType = posType;
    
    [loc saveInBackground];
    
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
                                                    selector:@selector(_tickActiveLocationTimer:)
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
            pull.together = NO;
            pull.nearby = NO;
            pull.ACL = [PFACL ACLWithUser:[PULUser currentUser] and:user];
            
            BOOL success = [pull save];
            
            [self _runBlockOnMainQueue:^{
                //send push to other user
                [PULPush sendPushType:PULPushTypeSendPull to:user from:[PULUser currentUser]];
                completion(success, nil);;
            }];
        }];
    } ignoreCache:YES];
}

- (void)acceptPull:(PULPull*)pull
{
    NSAssert([pull.receivingUser isEqual:[PULUser currentUser]], @"can only accept a pull if we're the receiver");
    [self _runBlockInBackground:^{
        pull.status = PULPullStatusPulled;
        pull.expiration = [NSDate dateWithTimeIntervalSinceNow:pull.duration];
        [pull save];

        //send push to other user
        [PULPush sendPushType:PULPushTypeAcceptPull to:[pull otherUser] from:[PULUser currentUser]];
    }];
}

- (void)deletePull:(PULPull*)pull
{
    // remove from cache
    [_cache removePull:pull];
    
    // delete from parse
    [pull deleteEventually];
}


#pragma mark - Monitoring Stuff
- (void)_startMonitoringPullsInBackground:(BOOL)inBackground
{
    NSAssert(_observerTimerPulls == nil, @"observer timer already set. should be stopped first");
    _observerTimerPulls = [NSTimer
                           scheduledTimerWithTimeInterval:inBackground ? kPULPollTimeBackground : kPULPollTimePassive
                           target:self
                           selector:@selector(_observerTimerTick:)
                           userInfo:nil
                           repeats:YES];
}

- (void)_startMonitoringPulledLocationsInBackground:(BOOL)inBackground
{
    NSAssert(_observerTimerLocations == nil, @"observer timer already set. should be stopped first");
    _observerTimerLocations = [NSTimer
                               scheduledTimerWithTimeInterval:inBackground ? kPULPollTimeBackground : kPULPollTimePassive
                               target:self
                               selector:@selector(_observerTimerTick:)
                               userInfo:nil
                               repeats:YES];
}

- (void)_stopMonitoringPulls
{
    if (_observerTimerPulls)
    {
        [_observerTimerPulls invalidate];
        _observerTimerPulls = nil;
    }
}

- (void)_stopMonitoringPulledLocations
{
    if (_observerTimerLocations)
    {
        [_observerTimerLocations invalidate];
        _observerTimerLocations = nil;
    }
}


#pragma mark - Private
- (void)_tickActiveLocationTimer:(NSTimer*)timer
{
    [self _runBlockInBackground:^{
        PULUser *user = [timer userInfo];
        
        [user.location fetch];
        
        NSString *key = user.username;
        NSDictionary *dict = _locationTimers[key];
        
        SEL selector = [dict[@"selector"] pointerValue];
        id target = dict[@"target"];
        
        [self _runBlockOnMainQueue:^{
            [target performSelector:selector];
        }];
        
    }];
}

- (void)_observerTimerTick:(NSTimer*)timer
{
    if (![PULUser currentUser].isDataAvailable)
    {
        return;
    }
    [self _runBlockInBackground:^{
        if ([timer isEqual:_observerTimerPulls])
        {
            // refresh pulls
            [PFObject fetchAll:[_cache cachedPulls]];
            [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedPullsNotification
                                                                object:nil];
//            [self getPullsInBackground:^(NSArray<PULPull *> * _Nullable pulls, NSError * _Nullable error) {
//                [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedPullsNotification
//                                                                    object:nil];
//                ;
//                //TODO: go through each pull and see if we have a nearby flag that we need to notify the user about
//            } ignoreCache:YES];
        }
        else if ([timer isEqual:_observerTimerLocations])
        {
            // refresh locations
            NSArray *locations = [[_cache cachedPullsPulled]
                                  linq_select:^id(PULPull *pull) {
                                      return [pull otherUser].location;
                                  }];
            
            if (locations.count > 0)
            {
                [PFObject fetchAll:locations];
//                [PFObject fetchAll:[_cache cacwhedFriendsPulled]];
                
                // go through each pull and check if we need to add nearby or together flag
                for (PULPull *pull in [_cache cachedPullsPulled])
                {
                    BOOL wasNearby = pull.nearby;
                    BOOL wasTogether = pull.together;
                    [pull setDistanceFlags];
                    
                    BOOL dirty = wasNearby != pull.nearby || wasTogether != pull.together;
                    
                    if (dirty)
                    {
                        [pull saveEventually];
                    }
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedLocationsNotification
                                                                    object:nil];
            }
        }
    }];
}

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
    
    PULUserSettings *settings = [PULUserSettings defaultSettings];
    
    if (fbData[@"first_name"]) { user[@"firstName"] = fbData[@"first_name"]; }
    if (fbData[@"last_name"]) { user[@"lastName"] = fbData[@"last_name"]; }
    if (fbData[@"gender"] && [fbData[@"gender"] length] > 0) { user[@"gender"] = [fbData[@"gender"] substringToIndex:1]; }
    if (fbData[@"id"]) { user[@"fbId"] = fbData[@"id"]; }
    if (fbData[@"email"]) { user[@"email"] = fbData[@"email"]; }
    if (fbData[@"locale"]) { user[@"locale"] = fbData[@"locale"]; }
    user[@"username"] = [NSString stringWithFormat:@"fb:%@", user[@"fbId"]];
    user[@"isInForeground"] = @(YES);
    
    // set acl for user and settings
    PFACL *acl = [PFACL ACLWithUser:user];
    [acl setPublicReadAccess:YES];
    user.ACL = acl;
    settings.ACL = acl;
    
    // set user settings
    user.userSettings = settings;
    
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
                     completion(YES, nil);
                 }];
             }
             else
             {
                 // return nil
                 completion(YES, nil);
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
