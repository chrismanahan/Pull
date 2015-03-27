//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

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

@end
