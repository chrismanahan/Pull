//
//  PULAccount.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULAccount.h"

#import "PULConstants.h"  

#import "PULLocationUpdater.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>

NSString * const kPULAccountFriendUpdatedNotifcation      = @"kPULAccountFriendUpdatedNotifcation";

NSString * const kPULAccountFriendListUpdatedNotification = @"kPULAccountFriendListUpdatedNotification";

NSString * const kPULAccountDidUpdateLocationNotification = @"kPULAccountDidUpdateLocationNotification";

NSString * const kPULAccountDidUpdateHeadingNotification = @"kPULAccountDidUpdateHeadingNotification";

@interface PULAccount ()

@property (nonatomic, strong) Firebase *fireRef;

@property (nonatomic) BOOL needsAddFromFacebook;

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
        
        [PULLocationUpdater sharedUpdater].delegate = self;
    }
    return self;
}

#pragma mark - Public

-(void)initializeAccount;                                                                   // 1. Grabs all of our friends from firebase
{
    _needsAddFromFacebook = YES;
    [_friendManager initializeFriends];
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

- (void)loginWithFacebookToken:(NSString*)accessToken completion:(PULAccountLoginCompletionBlock)completion;
{
    PULLog(@"Logging in with facebook token");
    [_fireRef authWithOAuthProvider:@"facebook" token:accessToken withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error)
        {
            if (completion)
            {
                completion(nil, error);
            }
        }
        else
        {
            PULLog(@"logged in with facebook");
            // check if user already exists
            Firebase *userExistsRef = [[_fireRef childByAppendingPath:@"users"] childByAppendingPath:authData.uid];
            [userExistsRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                BOOL isNewUser = !snapshot.hasChildren;
                
                if (isNewUser)
                {
                    [self p_registerUserWithFacebookAuthData:authData];
                }
                self.uid = snapshot.key;
                
                [self initializeAccount];
                
                if (completion)
                {
                    completion(self, nil);
                }
                
                [[PULLocationUpdater sharedUpdater] startUpdatingLocation];
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
    
    NSString *displayName = providerData[@"displayName"];
    if (displayName)
    {
        NSRegularExpression *firstRegex = [NSRegularExpression regularExpressionWithPattern:@"^(\\w+)"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:nil];
        
        // TODO: decide if we want to include middle names
        NSString *lastNameOnlyPattern = @"(?<= )(\\w+)$";
        NSString *fullDisplayNameWithoutFirst = @"((?<= )\\w+)( \\w+)+$";
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

#pragma mark - Properties
- (void)setLocation:(CLLocation *)location
{
    PULLog(@"account setting location");
    
    Firebase *locRef = [[[_fireRef childByAppendingPath:@"users"] childByAppendingPath:self.uid] childByAppendingPath:@"location"];
    [locRef setValue:@{@"lat": @(location.coordinate.latitude),
                       @"lon": @(location.coordinate.longitude),
                       @"alt": @(location.altitude)}];
    
    [super setLocation:location];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountDidUpdateLocationNotification object:self.location];
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
    
    // send out notifcation that we have a different friend ordering                                    // 4. Everyone is in order, lets send out a notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)friendManager didForceAddUser:(PULUser*)user;
{
    PULLog(@"friend manager did force add user");
    
    // added new friend, send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didSendFriendRequestToUser:(PULUser*)user
{
    PULLog(@"friend manager did send friend request");
    
    // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didAcceptFriendRequestFromUser:(PULUser*)user
{
    PULLog(@"friend manager did accept friend request");
    
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
    // send out notifcation
//    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager *)friendManager friendRequestWasAcceptedWithUser:(PULUser *)user
{
    PULLog(@"friend manager friend request was accepted");
    
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
}

- (void)friendManager:(PULFriendManager *)friendManager didReceiveFriendRequestFromUser:(PULUser *)user
{
    PULLog(@"friend manager did receive friend request");
    
    // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager*)pullManager didUnfriendUser:(PULUser*)user
{
    PULLog(@"friend manager did unfriend user");
    
       // send out notifcation
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountFriendListUpdatedNotification object:self];
}

- (void)friendManager:(PULFriendManager *)friendManager didDetectFriendChange:(PULUser *)user
{
    PULLog(@"friend manager did detect friend change");
    
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
    PULLog(@"pull manager did load pulls");
    
    [_friendManager reorganizeWithPulls:pulls];                                                             // 3. Now that we have pulls, we can organize our friends correctly
}

- (void)pullManagerDidReceivePull:(PULPull*)pull
{
    PULLog(@"pull manager did receive pull");
    
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerDidSendPull:(PULPull*)pull
{
    PULLog(@"pull manager did send pull");
    [_friendManager updateOrganizationWithPull:pull];
}

- (void)pullManagerDidRemovePull
{
    PULLog(@"pull manager did remove pull");
    [_friendManager reorganizeWithPulls:_pullManager.pulls];
}

- (void)pullManagerDidDetectPullStatusChange:(PULPull*)pull
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kPULAccountDidUpdateHeadingNotification object:heading];
}

@end
