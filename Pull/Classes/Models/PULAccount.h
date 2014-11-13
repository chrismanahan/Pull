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

/**
 *  Notifcation sent when a single user is updated. The object with the notif is the updated user
 */
extern NSString * const kPULAccountFriendUpdatedNotifcation;
/**
 *  Notification sent when a friend array is updated. This encompasses a new friend being added, invited, accepted, etc. And also for when a user is pulled, or pull status changes with some user. Or when the order of an array is changed 
 */
extern NSString * const kPULAccountFriendListUpdatedNotification;

/**
 *  Sent out when account's location is changed. Attached object is cllocation
 */
extern NSString * const kPULAccountDidUpdateLocationNotification;

@interface PULAccount : PULUser <PULFriendManagerDelegate, PULPullManagerDelegate, PULLocationUpdaterDelegate>

@property (nonatomic, strong) PULPullManager *pullManager;
@property (nonatomic, strong) PULFriendManager *friendManager;

@property (nonatomic, strong) PULLocationUpdater *locationUpdater;

@property (nonatomic) NSString *fbToken;

+ (PULAccount*)currentUser;

/**
 *  Saves all basic info to firebase
 */
- (void)saveUser;

- (void)initializeAccount;

@end
