//
//  PULParseMiddleMan.m
//  Pull
//
//  Created by Chris M on 9/26/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULParseMiddleMan.h"

#import "PULPush.h"

#import "Amplitude.h"

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
                 [PULUser currentUser].isDisabled = NO;
                 [[PULUser currentUser] saveInBackground];
                 
                 [PULPush subscribeToPushNotifications:[PULUser currentUser]];
                 completion(YES, error);
             }
         }
     }];

}

#pragma mark - Getting Friends
/**
 *  @warning This must be run on a background thread
 *
 *  @return Array of friends
 */
- (NSArray*)_getFriends
{
    PFQuery *query = [PFQuery queryLookupFriends];
    NSArray *objects = [query findObjects:nil];
    NSArray *users = [self _usersFromLookupResults:objects];
    return users;
}

- (void)getFriendsInBackground:(PULUsersBlock)completion
{
    [self _runBlockInBackground:^{
        NSArray *users = [self _getFriends];
        
        [self _runBlockOnMainQueue:^{
            [_cache setFriends:users];
            
            [self _addFriendsFromFacebookForce:NO
                                    completion:^(BOOL success, NSError * _Nullable error) {
                                        completion(users, nil);
                                }];
            
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
    
    [_cache addFriendToCache:user];
    
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
    
    if (saveUser)
    {
        [PULUser currentUser].location = loc;
        [[PULUser currentUser] saveInBackground];
    }
    else
    {
        [loc saveInBackground];
    }
}

#pragma mark - Observing changes
- (void)observeChangesInLocationForUser:(PULUser*)user interval:(NSTimeInterval)interval target:(id)target selecter:(SEL)selector;
{
    PULLog(@"starting timer to observe location changes for user: %@", user);
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(_tickActiveLocationTimer:)
                                                    userInfo:user
                                                     repeats:YES];
    
    
//    [self stopObservingChangesInLocationForUser:user];
    
    if (![self _timerExistsForUser:user target:target selector:selector])
    {
        [self stopObservingChangesInLocationForUser:user];
        _locationTimers[user.username] = @{@"timer": timer,
                                       @"target": target,
                                       @"selector": [NSValue valueWithPointer:selector]};
    }
}

- (BOOL)_timerExistsForUser:(PULUser*)user target:(id)target selector:(SEL)selector
{
    if (_locationTimers[user.username])
    {
        NSDictionary *dict = _locationTimers[user.username];
        id oldTarget = dict[@"target"];
        SEL oldSelector = [dict[@"selector"] pointerValue];
        
        return ([oldTarget isEqual:target] && [NSStringFromSelector(oldSelector) isEqualToString:NSStringFromSelector(selector)]);
    }
    
    return NO;
}

- (void)stopObservingChangesInLocationForUser:(PULUser*)user
{
    if (_locationTimers[user.username])
    {
        PULLog(@"stopping observer timer for user %@", user.username);
        [((NSTimer*)_locationTimers[user.username][@"timer"]) invalidate];
        [_locationTimers removeObjectForKey:user.username];
    }
}

- (void)stopObservingChangesInLocationForAllUsers
{
    for (NSString *username in _locationTimers)
    {
        [((NSTimer*)_locationTimers[username][@"timer"]) invalidate];
    }
    [_locationTimers removeAllObjects];
}


#pragma mark - Monitoring Stuff
- (void)_startMonitoringPullsInBackground:(BOOL)inBackground
{
//    NSAssert(_observerTimerPulls == nil, @"observer timer already set. should be stopped first");
    _observerTimerPulls = [NSTimer
                           scheduledTimerWithTimeInterval:inBackground ? kPULPollTimeBackground : kPULPollTimePassive
                           target:self
                           selector:@selector(_observerTimerTick:)
                           userInfo:nil
                           repeats:YES];
}

- (void)_startMonitoringPulledLocationsInBackground:(BOOL)inBackground
{
//    NSAssert(_observerTimerLocations == nil, @"observer timer already set. should be stopped first");
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
    // check if the app has been killed
    if ([PULUser currentUser].killed || ![PULUser currentUser].isInForeground)
    {
        // stop the timer
        [self stopObservingChangesInLocationForAllUsers];
        return;
    }
    
    [self _runBlockInBackground:^{
        PULUser *user = [timer userInfo];
        
        PULLog(@"updating active pulled user");
        [user fetchIfNeeded];
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
        // timer observing pulls
        if ([timer isEqual:_observerTimerPulls])
        {
            [self _observerTimerPullsTicked];
        }
        // timer observing locations of pulled friends
        else if ([timer isEqual:_observerTimerLocations])
        {
            [self _observerTimerLocationsTicked];
        }
    }];
}

- (void)_observerTimerLocationsTicked
{
    PULLog(@"updating locations of all pulled users");
    // refresh locations
    NSArray *locations = [[_cache cachedPullsPulled]
                          linq_select:^id(PULPull *pull) {
                              return [pull otherUser].location;
                          }];
    
    if (locations.count > 0)
    {
        [PFObject fetchAll:locations];
        [_cache resetPullSorting];
        //                [PFObject fetchAll:[_cache cacwhedFriendsPulled]];
        
        // go through each pull and check if we need to add nearby or together flag
        for (PULPull *pull in [_cache cachedPullsPulled])
        {
            [self _updatePullDistanceFlags:pull];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedLocationsNotification
                                                            object:nil];
    }
}

- (void)_observerTimerPullsTicked
{
    PULLog(@"updating pulls");
    // refresh pulls
    [PFObject fetchAll:[_cache cachedPulls]];
    [_cache resetPullSorting];
    [[NSNotificationCenter defaultCenter] postNotificationName:PULParseObjectsUpdatedPullsNotification
                                                        object:nil];

}

- (void)_updatePullDistanceFlags:(PULPull*)pull
{
    BOOL wasNearby = pull.nearby;
    BOOL wasTogether = pull.together;
    [pull setDistanceFlags];
    
    BOOL dirty = wasNearby != pull.nearby || wasTogether != pull.together;
    
    if (dirty)
    {
        PULLog(@"\tsaving updated distance flags for pull: %@", pull);
        [pull saveEventually];
    }
}

#pragma mark Parsing Results
- (NSArray<PULUser*>*)_usersFromLookupResults:(NSArray<PFObject*>*)objects
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (PFObject *obj in objects)
    {
        PULUser *otherUser = [self _friendLookupOtherUser:obj];
        if (!otherUser.isDisabled)
        {
            [arr addObject:otherUser];
        }
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
    // adjust cache
    if (block)
    {
        [_cache removeFriend:user];
        [_cache addBlockedUserToCache:user];
        
        [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventBlockUser
                   withEventProperties:@{@"user": user.username}];
    }
    else
    {
        [_cache removeBlockedUser:user];
        [_cache addFriendToCache:user];
        
        [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventUnblockUser
                   withEventProperties:@{@"user": user.username}];
    }
    
    // run parse operation
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
    user[@"isDisabled"] = @(NO);
    
    // set acl for user and settings
    PFACL *acl = [PFACL ACLWithUser:user];
    [acl setPublicReadAccess:YES];
    user.ACL = acl;
    settings.ACL = acl;
    
    // set user settings
    user.userSettings = settings;
    
    [user saveInBackground];
    
    [self _addFriendsFromFacebookForce:YES completion:^(BOOL success, NSError * _Nullable error) {
        completion(YES, error);
    }];
}

- (void)_addFriendsFromFacebookForce:(BOOL)force completion:(PULStatusBlock)completion
{
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
                 NSArray *currentFriends;
                 
                 if (!force)
                 {
                     currentFriends = [_cache cachedFriends];
                     if (!currentFriends || currentFriends.count == 0)
                     {
                         currentFriends = [self _getFriends];
                     }
                 }
                 // build query to get all these users
                 PFQuery *friendQuery = [PFUser query];
                 [friendQuery whereKey:@"username" containedIn:usernames];
                 
                 [friendQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                     if (!force)
                     {
                         NSMutableArray *mutableObjects = [[NSMutableArray alloc] init];
                         // remove users that are in current friends
                         for (PULUser *user in objects)
                         {
                             if (![currentFriends containsObject:user])
                             {
                                 [mutableObjects addObject:user];
                             }
                         }
                         
                         [[PULParseMiddleMan  sharedInstance] friendUsers:mutableObjects];
                     }
                     else
                     {
                         [[PULParseMiddleMan  sharedInstance] friendUsers:objects];
                     }
                     
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
