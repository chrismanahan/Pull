//
//  PULAccountOld.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULAccount.h"

#import "FireSync.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>

@implementation PULAccount

static PULAccount *account = nil;

+ (instancetype)initializeCurrentUser:(NSString*)uid withAuthData:(FAuthData*)authData
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        account = [[PULAccount alloc] initEmptyWithUid:uid];
        
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
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error)
            {
                PULLog(@"ERROR: %@", error.localizedDescription);
            }
            else
            {
                
                NSArray *friends = ((NSDictionary*)result)[@"data"];
                NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:friends.count];
                PULLog(@"got %zd friends from facebook", friends.count);
                
                for (NSDictionary *friend in friends)
                {
                    NSString *fbId = friend[@"id"];
                    NSString *userUID = [NSString stringWithFormat:@"facebook:%@", fbId];
                    
                    PULUser *user = [[PULUser alloc] initWithUid:userUID];
                    
                    [users addObject:user];
                }
                
                [PULAccount currentUser].allFriends = users;
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
        
        [CrashlyticsKit setUserIdentifier:uid];
    });
    
    return account;
}

+ (instancetype)currentUser;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!account)
        {
            account = [[PULAccount alloc] init];
        }
    });
    
    return account;
}

+ (void)loginWithFacebookToken:(NSString*)accessToken completion:(void(^)(PULAccount *account, NSError *error))completion;
{
    PULLog(@"Logging in with facebook token");
    
    [[FireSync sharedSync] loginToProvider:@"facebook"
                               accessToken:accessToken
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
                                    }
                                }];
    
}

#pragma mark - Public
- (void)logout;
{
    [[FireSync sharedSync] unauth];
}

- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration;
{
    PULPull *pull = [[PULPull alloc] initNew];
    pull.sendingUser = self;
    pull.receivingUser = user;
    pull.status = PULPullStatusPending;
    pull.duration = duration;
    [pull resetExpiration];
    [pull saveAll];
    
    [self willChangeValueForKey:@"pulls"];
    [self.pulls addObject:pull];
    [self didChangeValueForKey:@"pulls"];
    
    [user.pulls addObject:pull];
}

- (void)acceptPull:(PULPull*)pull;
{
    pull.status = PULPullStatusPulled;
    [pull resetExpiration];
    [pull saveKeys:@[@"status", @"expiration"]];
}

- (void)cancelPull:(PULPull*)pull;
{
    pull.status = PULPullStatusExpired;
    [pull saveKeys:@[@"status"]];
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
