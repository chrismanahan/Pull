//
//  PULPull.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Parse/Parse.h>

#import "PFObject+Subclass.h"

@class PULUser;

NS_ASSUME_NONNULL_BEGIN

/*****************************
 Constants
 *****************************/

extern const NSTimeInterval kPullDurationHour;
extern const NSTimeInterval kPullDurationHalfDay;
extern const NSTimeInterval kPullDurationDay;
extern const NSTimeInterval kPullDurationAlways;

/*****************************
 Enums
 *****************************/

/*!
 *  Pull status
 */
typedef NS_ENUM(NSInteger, PULPullStatus)
{
    /*!
     *  Pull has either expired, been rejected, or is invalid
     */
    PULPullStatusNone = 0,
    /*!
     *  Pull is waiting for acceptance from receving user. When used relative to current account, pending means the pull is pending on this account to accept
     */
    PULPullStatusPending = 2,
    /*!
     *  Pull is valid and active
     */
    PULPullStatusPulled = 3,
    /**
     *  Pull is expired
     */
    PULPullStatusExpired = 4
};

typedef NS_ENUM(NSInteger, PULPullDistanceState)
{
    PULPullDistanceStateInaccurate = -1,
    PULPullDistanceStateFar,
    PULPullDistanceStateNearby,
    PULPullDistanceStateAlmostHere,
    PULPullDistanceStateHere
};


/*****************************
 Interface
 *****************************/
@interface PULPull : PFObject <PFSubclassing>

/*****************************
 Properties
 *****************************/

/*!
 *  User that initiated this pull
 */
@property (nonatomic, strong) PULUser *sendingUser;
/*!
 *  User that is receiving this pull
 */
@property (nonatomic, strong) PULUser *receivingUser;
/*!
 *  The duration that this pull is good for
*/
@property (nonatomic) NSTimeInterval duration;
/**
 *  The duration that this pull is good for converted to hours
 */
@property (nonatomic, readonly) NSInteger durationHours;
/**
 *  Property that returns the duration as human readable string
 */
@property (nonatomic, strong, readonly) NSString *durationRemaingString;
/*!
 *  The time at which this pull expires and goes out for pruning. -resetExpiration should be called to set the expiration based on the set duration and current time
 */
@property (nonatomic, strong) NSDate *expiration;
/*!
 *  The status of this pull
 */
@property (nonatomic) PULPullStatus status;
/**
 *  Indicates that the two users involved in this pull are physically together
 */
@property (nonatomic, assign, getter=areTogether) BOOL together;

/*****************************
 Instance Methods
 *****************************/

/**
 *  Helper method to check if the users are nearby
 *
 *  @return YES if nearby
 */
- (BOOL)isNearby;
/**
 *  Helper to indicate if the users are almost together
 *
 *  @return Yes if users are almost together
 */
- (BOOL)isAlmostHere;
/**
 *  Helper to indicate if the users are within visible distance
 *
 *  @return Yes if within visible distance
 */
- (BOOL)isHere;
- (BOOL)containsUser:(PULUser*)user;
- (BOOL)initiatedBy:(PULUser*)user;
- (BOOL)isAccurate;

- (PULPullDistanceState)pullDistanceState;

- (PULUser*)otherUser;
- (PULUser*)otherUserThatIsNot:(PULUser*)user;
- (void)resetExpiration;

/*****************************
 Class Methods
 *****************************/

+ (NSString*)parseClassName;

NS_ASSUME_NONNULL_END

@end
