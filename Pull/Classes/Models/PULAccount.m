//
//  PULAccount.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULAccount.h"

#import "PULConstants.h"

#import <Firebase/Firebase.h>

NSString * const kPULAccountFriendUpdatedNotifcation      = @"kPULAccountFriendUpdatedNotifcation";

NSString * const kPULAccountFriendListUpdatedNotification = @"kPULAccountFriendListUpdatedNotification";

NSString * const kPULAccountDidUpdateLocationNotification = @"kPULAccountDidUpdateLocationNotification";

@interface PULAccount ()

@property (nonatomic, strong) Firebase *fireRef;

@end

@implementation PULAccount

#pragma mark - Initialization
+ (PULAccount*)currentUser;
{
    static PULAccount *acct = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acct = [[PULAccount alloc] init];
    });
    
    return acct;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _friendManager = [[PULFriendManager alloc] init];
        _pullManager   = [[PULPullManager alloc] init];
        
        _friendManager.delegate = self;
        _pullManager.delegate   = self;
        
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    }
    return self;
}

#pragma mark - Public

- (void)initializeAccount;                                                                              // 1. Grabs all of our friends from firebase
{
    [_friendManager initializeFriends];
    [_friendManager addFriendsFromFacebook];
}

- (void)saveUser;
{
    NSAssert(self.uid, @"UID is missing");
    
    PULLog(@"Saving account");
    
    Firebase *userRef = [[_fireRef childByAppendingPath:@"users"] childByAppendingPath:self.uid];
    [userRef updateChildValues:[self firebaseRepresentation] withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (!error)
        {
            PULLog(@"Account did save");
        }
        else
        {
            PULLogError(@"Save account", @"%@", error.localizedDescription);
        }
    }];
}

#pragma mark - Properties
- (void)setLocation:(CLLocation *)location
{    
    Firebase *locRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:self.uid] childByAppendingPath:@"location"];
    [locRef setValue:@{@"lat": @(location.coordinate.latitude),
                       @"lon": @(location.coordinate.longitude),
                       @"alt": @(location.altitude)}];
    
    [super setLocation:location];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountDidUpdateLocationNotification object:self.location];
}

- (void)setFbToken:(NSString *)fbToken
{
    [[NSUserDefaults standardUserDefaults] setObject:fbToken forKey:@"FBTokenKey"];
}

- (NSString*)fbToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FBTokenKey"];
}

#pragma mark - Friend Manager Delegate
- (void)friendManagerDidLoadFriends:(PULFriendManager *)friendManager
{
    [_pullManager initializePullsWithFriends:friendManager.allFriends];                                 // 2. Grab pulls that we have with our friends
}

- (void)friendManagerDidReorganize:(PULFriendManager*)pullManager
{
    // send out notifcation that we have a different friend ordering                                    // 4. Everyone is in order, lets send out a notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)friendManager didForceAddUser:(PULUser*)user;
{
    // added new friend, send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didSendFriendRequestToUser:(PULUser*)user
{
    // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didAcceptFriendRequestFromUser:(PULUser*)user
{
    // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didUnfriendUser:(PULUser*)user
{
       // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager *)friendManager didDetectFriendChange:(PULUser *)user
{
    // someone changed, lets reorganize
    [_friendManager updateOrganizationForUser:user];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendUpdatedNotifcation object:user];
}

- (void)friendManager:(PULFriendManager *)friendManager didEncounterError:(NSError *)error
{
    PULLogError(@"Friend Manager", @"%@", error.localizedDescription);
}

#pragma mark - Pull Manager Delegate
- (void)pullManagerDidLoadPulls:(NSArray*)pulls
{
    [_friendManager reorganizeWithPulls:pulls];                                                             // 3. Now that we have pulls, we can organize our friends correctly
}

- (void)pullManagerDidReceivePull:(PULPull*)pull
{
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerDidSendPull:(PULPull*)pull
{
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerDidRemovePull
{
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
}

- (void)pullManagerDidDetectPullStatusChange:(PULPull*)pull
{
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerEncounteredError:(NSError *)error
{
    PULLogError(@"Pull Manager", @"%@", error.localizedDescription);
}

#pragma mark - Location Updater Delegate
- (void)locationUpdater:(PULLocationUpdater*)updater didUpdateLocation:(CLLocation*)location;
{
    self.location = location;
}

@end
