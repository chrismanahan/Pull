//
//  PULPull.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

@class PULUser;

NS_ASSUME_NONNULL_BEGIN

extern const NSTimeInterval kPullDurationHour;
extern const NSTimeInterval kPullDurationHalfDay;
extern const NSTimeInterval kPullDurationDay;
extern const NSTimeInterval kPullDurationAlways;

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

@interface PULPull : FireObject

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
/*!
 *  The time at which this pull expires and goes out for pruning. -resetExpiration should be called to set the expiration based on the set duration and current time
 */
@property (nonatomic, strong, readonly) NSDate *expiration;
/*!
 *  The status of this pull
 */
@property (nonatomic) PULPullStatus status;

@property (nonatomic, strong) NSString *caption;

@property (nonatomic, readonly, getter=isNearby) BOOL nearby;

- (instancetype)initNewBetween:(PULUser*)sender and:(PULUser*)receiver duration:(NSTimeInterval)duration;

- (BOOL)containsUser:(PULUser*)user;
- (BOOL)initiatedBy:(PULUser*)user;
- (PULUser*)otherUser:(PULUser*)thisUser;
- (void)resetExpiration;

NS_ASSUME_NONNULL_END

@end
