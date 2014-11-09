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

@interface PULAccount : PULUser <PULFriendManagerDelegate, PULPullManagerDelegate, PULLocationUpdaterDelegate>

@property (nonatomic, strong) PULPullManager *pullManager;
@property (nonatomic, strong) PULFriendManager *friendManager;

@property (nonatomic, strong) PULLocationUpdater *locationUpdater;


//@property (nonatomic, copy) NSString *username;
//@property (nonatomic, copy) NSString *fbId;
//@property (nonatomic, copy) NSString *uid;
//@property (nonatomic, copy) NSString *email;
//@property (nonatomic, assign) NSInteger provider;
//@property (nonatomic, copy) NSString *phoneNumber;
//
//@property (nonatomic, copy) NSString *firstName;
//@property (nonatomic, copy) NSString *lastName;
//@property (nonatomic, copy) NSString *fullName;
//
//@property (nonatomic, strong) UIImage *image;
//
//@property (nonatomic, strong) CLLocation *location;
//
//@property (nonatomic, assign) BOOL isPrivate;

+ (PULAccount*)currentUser;

@end
