//
//  PULAccountOld.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULAccountOld.h"

#import "PULConstants.h"  

#import "PULLocationUpdater.h"

#import "NSData+Hex.h"

#import "PULNoConnectionView.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>


NSString * const kPULAccountOldFriendListUpdatedNotification = @"kPULAccountOldFriendListUpdatedNotification";

NSString * const kPULAccountOldDidUpdateLocationNotification = @"kPULAccountOldDidUpdateLocationNotification";

NSString * const kPULAccountOldDidUpdateHeadingNotification = @"kPULAccountOldDidUpdateHeadingNotification";

NSString * const kPULAccountOldLoginFailedNotification = @"kPULAccountOldLoginFailedNotification";

@interface PULAccountOld ()

@property (nonatomic, strong) Firebase *fireRef;

@property (nonatomic) BOOL needsAddFromFacebook;

// protected
- (void)p_loadPropertiesFromDictionary:(NSDictionary*)dict;

@end

@implementation PULAccountOld

#pragma mark - Initialization
+ (PULAccountOld*)currentUser;
{
    static PULAccountOld *acct = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acct = [[PULAccountOld alloc] init];
    });
    
    return acct;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        PULLog(@"init account");
        _friendManager = [[PULFriendManager alloc] init];
        _pullManager   = [[PULPullManager alloc] init];
        
        _friendManager.delegate = self;
        _pullManager.delegate   = self;
        
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
        
        [PULLocationUpdater sharedUpdater].delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:PULConnectionLostNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [Firebase goOffline];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:PULConnectionRestoredNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [Firebase goOnline];
                                                      }];
    }
    return self;
}

#pragma mark - Public

-(void)initializeAccount;                                                                   // 1. Grabs all of our friends from firebase
{
    _didLoad = NO;
    PULLog(@"initializing account");
    
    // remove old notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kPULFriendBlockedSomeoneNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kPULFriendEnabledAccountNotification
                                                  object:nil];
    
    
    // check if user was previously disabled
    if (self.settings.disabled)
    {
        // reactivate the user
        self.settings.disabled = NO;
        [self saveUser];
    }
    
    _needsAddFromFacebook = YES;
    [_friendManager initializeFriends];
    
    // lets make sure our device token is uploaded
    [self writePushToken];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_friendBlockedNotification:)
                                                 name:kPULFriendBlockedSomeoneNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initializeAccount)
                                                 name:kPULFriendEnabledAccountNotification
                                               object:nil];
    
}

- (void)writePushToken
{
    Firebase *tokenRef = [[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:self.uid];
    NSData *tokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceToken"];
    
    if (tokenData)
    {
        NSString *token = [tokenData hexadecimalString];
        PULLog(@"writing token: %@", tokenData);
        [tokenRef updateChildValues:@{@"deviceToken": token}];
    }
}

- (void)saveUser;
{
    [self saveUserCompletion:nil];
}

- (void)saveUserCompletion:(void(^)())completion;
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
        
        if (completion)
        {
            completion();
        }
    }];

}

- (void)goOnline
{
    Firebase *connectedref = [[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@".info/connected"];
    [connectedref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([snapshot.value boolValue])
        {
            Firebase *fire = [[[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:[PULAccountOld currentUser].uid] childByAppendingPath:@"isOnline"];
            [fire setValue:@(YES)];
            
            [fire onDisconnectSetValue:@(NO)];
        }
    }];
}

- (void)logout
{
    [_fireRef unauth];
}

- (void)loginWithFacebookToken:(NSString*)accessToken completion:(PULAccountOldLoginCompletionBlock)completion;
{
    PULLog(@"Logging in with facebook token");
    [_fireRef authWithOAuthProvider:@"facebook" token:accessToken withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error)
        {
            PULLog(@"error logging in: %@", error.localizedDescription);
            if (completion)
            {
                completion(nil, error);
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldLoginFailedNotification object:self];
        }
        else
        {
            PULLog(@"logged in with facebook");
            // check if user already exists
            Firebase *userExistsRef = [[_fireRef childByAppendingPath:@"users"] childByAppendingPath:authData.uid];
            [userExistsRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                BOOL isNewUser = !snapshot.hasChildren;
                self.uid = snapshot.key;
                
                [CrashlyticsKit setUserIdentifier:self.uid];
                
                if (isNewUser)
                {
                    [self p_registerUserWithFacebookAuthData:authData];
                }
                else
                {
                    [self p_loadPropertiesFromDictionary:snapshot.value];
                    [self goOnline];
                }
                
                
                [self initializeAccount];
                
                if (completion)
                {
                    completion(self, nil);
                }
                
                if ([[PULLocationUpdater sharedUpdater] hasPermission])
                {
                    [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
                }
            }];
        }
    }];
}

- (void)p_registerUserWithFacebookAuthData:(FAuthData*)authData;
{
    NSDictionary *providerData = authData.providerData;
    self.uid = authData.uid;
    self.fbId = providerData[@"id"];
    self.email = providerData[@"email"];
    self.isPrivate = NO;
//    self.online = YES;
    
    // initialize settings
    self.settings = [PULUserSettings defaultSettings];
    
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
        
        self.firstName = [displayName substringWithRange:firstRange];
        self.lastName = [displayName substringWithRange:lastRange];
    }
    
    [self saveUser];
}

- (void)_friendBlockedNotification:(NSNotification*)notif;
{
    NSString *blockedUid = [notif object];
    if ([blockedUid isEqualToString:self.uid])
    {
        PULLog(@"we have been blocked!");
        
        [self initializeAccount];
    }
}

#pragma mark - Properties
- (void)setLocation:(CLLocation *)location
{
    CLSLog(@"account setting location");
    
    Firebase *locRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:self.uid] childByAppendingPath:@"location"];
    [locRef setValue:@{@"lat": @(location.coordinate.latitude),
                       @"lon": @(location.coordinate.longitude),
                       @"alt": @(location.altitude)}];
    
    [super setLocation:location];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldDidUpdateLocationNotification object:self.location];
}

- (void)setAuthToken:(NSString *)authToken
{
    [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:@"AuthTokenKey"];
}

- (NSString*)authToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"AuthTokenKey"];
}

- (BOOL)isAuthenticated
{
    return (BOOL)_fireRef.authData;
}

#pragma mark - Friend Manager Delegate
- (void)friendManagerDidLoadFriends:(PULFriendManager *)friendManager
{
    PULLog(@"friend manager did load friends");
    
    if (_needsAddFromFacebook)
    {
        [_friendManager addFriendsFromFacebook];
        _needsAddFromFacebook = NO;
    }
    
    [_pullManager initializePulls];                                 // 2. Grab pulls that we have with our friends
}

- (void)friendManagerDidReorganize:(PULFriendManager*)pullManager
{
    PULLog(@"friend manager did reorganize");
    
    for (PULUserOld *friend in _friendManager.allFriends)
    {
        [friend stopObservingLocationChanges];
        [friend startObservingAccount];
    }
    
    for (PULUserOld *friend in _friendManager.pulledFriends)
    {
        [friend startObservingLocationChanges];
    }
    
    // send out notifcation that we have a different friend ordering                                    // 4. Everyone is in order, lets send out a notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
    _didLoad = YES;
}

- (void)friendManager:(PULFriendManager*)friendManager didForceAddUser:(PULUserOld*)user;
{
    PULLog(@"friend manager did force add user");
    [self.friendManager reorganizeWithPulls:_pullManager.pulls];
    // added new friend, send notification
//    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didSendFriendRequestToUser:(PULUserOld*)user
{
    PULLog(@"friend manager did send friend request");
    
    // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didAcceptFriendRequestFromUser:(PULUserOld*)user
{
    PULLog(@"friend manager did accept friend request");
    
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
    // send out notifcation
//    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager *)friendManager friendRequestWasAcceptedWithUser:(PULUserOld *)user
{
    PULLog(@"friend manager friend request was accepted");
    
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
}

- (void)friendManager:(PULFriendManager *)friendManager didReceiveFriendRequestFromUser:(PULUserOld *)user
{
    PULLog(@"friend manager did receive friend request");
    
    // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didUnfriendUser:(PULUserOld*)user
{
    PULLog(@"friend manager did unfriend user");
    
       // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager *)friendManager didBlockUser:(PULUserOld *)user
{
    [self.pullManager unpullUser:user];
    PULLog(@"friend manager did block user: %@", user.firstName);
    [self initializeAccount];
}

- (void)friendManager:(PULFriendManager *)friendManager didUnBlockUser:(PULUserOld *)user
{
    PULLog(@"friend manager did unblock user: %@", user.firstName);
    [self initializeAccount];
}

- (void)friendManager:(PULFriendManager*)friendManager didDetectNewFriend:(PULUserOld*)user;
{
    PULLog(@"friend manager did detect new friend: %@", user.firstName);
    [self.friendManager reorganizeWithPulls:self.pullManager.pulls];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldFriendListUpdatedNotification object:self];
}

//- (void)friendManager:(PULFriendManager *)friendManager didDetectFriendChange:(PULUser *)user
//{
//    PULLog(@"friend manager did detect friend change");
//    
//    // someone changed, lets reorganize
//   // [_friendManager updateOrganizationForUser:user];
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:kPULFriendUpdatedNotifcation object:user];
//}

- (void)friendManager:(PULFriendManager *)friendManager didEncounterError:(NSError *)error
{
    PULLogError(@"Friend Manager", @"%@", error.localizedDescription);
}

#pragma mark - Pull Manager Delegate
- (void)pullManagerDidLoadPulls:(NSArray*)pulls
{
    PULLog(@"pull manager did load pulls");
    
    [_friendManager reorganizeWithPulls:pulls];                                                             // 3. Now that we have pulls, we can organize our friends correctly
}

- (void)pullManagerDidReceivePull:(PULPullOld*)pull
{
    PULLog(@"pull manager did receive pull");
    
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerDidTryToReceivePull
{
    PULLog(@"pull manager did try to receive pull");
    
    [self initializeAccount];
}

- (void)pullManagerDidSendPull:(PULPullOld*)pull
{
    PULLog(@"pull manager did send pull");
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerDidRemovePull
{
    PULLog(@"pull manager did remove pull");
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
}

- (void)pullManagerDidDetectPullStatusChange:(PULPullOld*)pull
{
    PULLog(@"pull manager did detect pull status change");
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

- (void)locationUpdater:(PULLocationUpdater *)updater didUpdateHeading:(CLHeading *)heading
{    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountOldDidUpdateHeadingNotification object:heading];
}

@end