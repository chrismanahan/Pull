//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserSettings.h"
#import "PULLocation.h"

#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

#import "PFObject+Subclass.h"

@class CLPlacemark;

NS_ASSUME_NONNULL_BEGIN

@interface PULUser : PFUser <PFSubclassing>

/*!
 *  Facebook ID
 */
@property (nonatomic, strong) NSString *fbId;
/*!
 *  Email address of user
 */
@property (nonatomic, strong) NSString *email;
/*!
 *  First name
 */
@property (nonatomic, strong) NSString *firstName;
/*!
 *  Last name
 */
@property (nonatomic, strong) NSString *lastName;
 /*!
 *  Full name
 */
@property (nonatomic, strong, readonly) NSString *fullName;
/*!
 *  URL string to get user's profile image. Currently only pulls from facebook
 */
@property (nonatomic, strong, readonly) NSString *imageUrlString;
/*!
 *  Most recent location of user
 */
@property (nonatomic, strong) PULLocation *location;


@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSArray *blocked;
@property (nonatomic, strong) NSArray *unpulledFriends;
@property (nonatomic, strong) NSArray *pulledFriends;
// pulls
@property (nonatomic, strong) NSArray *pulls;
// settings
@property (nonatomic, strong) PULUserSettings *settings;

@property (nonatomic, assign, getter=isInForeground) BOOL inForeground;

- (double)distanceFromUser:(PULUser*)user;

- (void)initialize;

+ (NSString*)parseClassName;

NS_ASSUME_NONNULL_END

@end
