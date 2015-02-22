//
//  PULAccount.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULFriendManager.h"
#import "PULPullManager.h"

#import "PULLocationUpdater.h"

@class FAuthData;
@class PULAccount;

typedef void(^PULAccountLoginCompletionBlock)(PULAccount *account, NSError *error);

/**
 *  Notification sent when a friend array is updated. This encompasses a new friend being added, invited, accepted, etc. And also for when a user is pulled, or pull status changes with some user. Or when the order of an array is changed 
 */
extern NSString * const kPULAccountFriendListUpdatedNotification;

/**
 *  Sent out when account's location is changed. Attached object is cllocation
 */
extern NSString * const kPULAccountDidUpdateLocationNotification;

/**
 *  Sent out when account's magnetic heading is changed. Attached object is CLHeading
 */
extern NSString * const kPULAccountDidUpdateHeadingNotification;

@interface PULAccount : PULUser <PULFriendManagerDelegate, PULPullManagerDelegate, PULLocationUpdaterDelegate>

@property (nonatomic, strong) PULPullManager *pullManager;
@property (nonatomic, strong) PULFriendManager *friendManager;

@property (nonatomic, strong) PULLocationUpdater *locationUpdater;

@property (nonatomic) NSString *authToken;

/**
 *  Flag indicated if the user is authenticated with Firebase
 */
@property (nonatomic, assign, getter=isAuthenticated, readonly) BOOL authenticated;

+ (PULAccount*)currentUser;

/**
 *  Saves all basic info to firebase
 */
- (void)saveUser;

- (void)saveUserCompletion:(void(^)())completion;

/**
 *  Initializes account by getting friends from firebase and adding friends from facebook if they have not been added yet
 */
- (void)initializeAccount;

- (void)goOnline;
- (void)goOffline;

/**
 *  Logs the user out
 */
- (void)logout;

/**
 *  Authenticates the user with a token retreived from facebook
 *
 *  @param accessToken facebook access token
 */
- (void)loginWithFacebookToken:(NSString*)accessToken completion:(PULAccountLoginCompletionBlock)completion;

/**
 *  Registers a new user to firebase with auth data
 *
 *  @param authData Auth data
 */
- (void)registerUserWithFacebookAuthData:(FAuthData*)authData;

@end
