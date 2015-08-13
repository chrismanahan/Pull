//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

#import "FireMutableArray.h"
#import "PULUserSettings.h"

@import CoreLocation;

@class CLPlacemark;
@class UIImage;

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, assign) NSInteger currentMotionType;
@property (nonatomic, assign) NSInteger currentPositionType;
// friends
@property (nonatomic, strong) FireMutableArray *friends;
@property (nonatomic, strong) FireMutableArray *blocked;
@property (nonatomic, strong) NSArray *unpulledFriends;
@property (nonatomic, strong) NSArray *pulledFriends;
// pulls
@property (nonatomic, strong) FireMutableArray *pulls;
// settings
@property (nonatomic, strong) PULUserSettings *settings;

//TODO: -sortedArray: doesn't belong here
- (id)sortedArray:(NSArray*)array;

- (void)initialize;

NS_ASSUME_NONNULL_END

@end
