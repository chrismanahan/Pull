////
////  PULAccountOld.h
////  Pull
////
////  Created by Chris Manahan on 11/6/14.
////  Copyright (c) 2014 Pull LLC. All rights reserved.
////
//
//#import "PULUserOld.h"
//
//#import "PULFriendManager.h"
//#import "PULPullManager.h"
//
//#import "PULLocationUpdater.h"
//
//@class FAuthData;
//@class PULAccountOld;
//
//typedef void(^PULAccountOldLoginCompletionBlock)(PULAccountOld *account, NSError *error);
//
///**
// *  Notification sent when a friend array is updated. This encompasses a new friend being added, invited, accepted, etc. And also for when a user is pulled, or pull status changes with some user. Or when the order of an array is changed 
// */
//extern NSString * const kPULAccountOldFriendListUpdatedNotification;
//
///**
// *  Sent out when account's location is changed. Attached object is cllocation
// */
//extern NSString * const kPULAccountOldDidUpdateLocationNotification;
//
///**
// *  Sent out when account's magnetic heading is changed. Attached object is CLHeading
// */
//extern NSString * const kPULAccountOldDidUpdateHeadingNotification;
//
//extern NSString * const kPULAccountOldLoginFailedNotification;
//
//@interface PULAccountOld : PULUserOld <PULFriendManagerDelegate, PULPullManagerDelegate, PULLocationUpdaterDelegate>
//
//@property (nonatomic, strong) PULPullManager *pullManager;
//@property (nonatomic, strong) PULFriendManager *friendManager;
//
//@property (nonatomic, strong) PULLocationUpdater *locationUpdater;
//
//@property (nonatomic, assign) BOOL didLoad;
//
//@property (nonatomic) NSString *authToken;
//
///**
// *  Flag indicated if the user is authenticated with Firebase
// */
//@property (nonatomic, assign, getter=isAuthenticated, readonly) BOOL authenticated;
//
//+ (PULAccountOld*)currentUser;
//
///**
// *  Saves all basic info to firebase
// */
//- (void)saveUser;
//
//- (void)saveUserCompletion:(void(^)())completion;
//
//- (void)writePushToken;
//
///**
// *  Initializes account by getting friends from firebase and adding friends from facebook if they have not been added yet
// */
//- (void)initializeAccount;
//
//- (void)goOnline;
//
///**
// *  Logs the user out
// */
//- (void)logout;
//
///**
// *  Authenticates the user with a token retreived from facebook
// *
// *  @param accessToken facebook access token
// */
//- (void)loginWithFacebookToken:(NSString*)accessToken completion:(PULAccountOldLoginCompletionBlock)completion;
//
///**
// *  Registers a new user to firebase with auth data
// *
// *  @param authData Auth data
// */
//- (void)registerUserWithFacebookAuthData:(FAuthData*)authData;
//
//@end
