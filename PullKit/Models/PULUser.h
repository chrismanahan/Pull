//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULLocation.h"

#import <Parse/Parse.h>
#import "PFObject+Subclass.h"
#import "PULUserSettings.h"

@class CLPlacemark;

NS_ASSUME_NONNULL_BEGIN

@interface PULUser : PFUser <PFSubclassing>

/*****************************
 Properties
 *****************************/

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
/**
 *  Gender of user. Either m, f, or o (other)
 */
@property (nonatomic, strong) NSString *gender;
 /*!
 *  Full name
 */
@property (nonatomic, strong, readonly) NSString *fullName;
/*!
 *  Username of user, auto generated based on signup type
 */
@property (nonatomic, strong) NSString *username;
/*!
 *  URL string to get user's profile image. Currently only pulls from facebook
 */
@property (nonatomic, strong, readonly) NSString *imageUrlString;
/**
 *  Flag indicating if this user is in the foreground
 */
@property (nonatomic, assign) BOOL isInForeground;
/**
 *  Indicates this user has disabled their account
 */
@property (nonatomic, assign) BOOL isDisabled;
/**
 *  Indicates this user is currently online
 */
@property (nonatomic, assign) BOOL isOnline;

@property (nonatomic, assign) BOOL lowBattery;

@property (nonatomic, assign) BOOL noLocation;
@property (nonatomic, assign) BOOL killed;
/*!
 *  Most recent location of user
 */
@property (nonatomic, strong) PULLocation *location;
/**
 *  User settings
 */
@property (nonatomic, strong) PULUserSettings *userSettings;

/*****************************
 Instance Methods
 *****************************/

/**
 *   Helper method to determine distance to other user
 *
 *  @param user Other user to determine distance from
 *
 *  @return Distance in meters
 */
- (CLLocationDistance)distanceFromUser:(PULUser*)user;
/**
 *  Calculates the angle between this user and other user given a magnetic heading
 *
 *  @param heading Heading to calculate against
 *  @param user    Other user
 *
 *  @return Angle in radians
 */
- (double)angleWithHeading:(CLHeading*)heading fromUser:(PULUser*)user;

@end

NS_ASSUME_NONNULL_END
