//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

#import "PULUserSettings.h"

@class CLLocation;
@class CLPlacemark;
@class UIImage;

@interface PULUser : FireObject

// identifiers
@property (nonatomic, strong) NSString *fbId;
@property (nonatomic, strong) NSString *deviceToken;
// contact info
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *email;
// basic details
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) UIImage *image;
// location
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) CLPlacemark *placemark;
// friends
@property (nonatomic, strong) NSArray *allFriends;
@property (nonatomic, strong) NSArray *nearbyFriends;
@property (nonatomic, strong) NSArray *pulledFriends;
@property (nonatomic, strong) NSArray *pullInvitedFriends;
@property (nonatomic, strong) NSArray *pullPendingFriends;
@property (nonatomic, strong) NSArray *blockedUsers;
// pulls
@property (nonatomic, strong) NSArray *pulls;
// settings
@property (nonatomic, strong) PULUserSettings *settings;

@end
