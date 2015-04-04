//
//  PULPull.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

@class PULUser;

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
    /**
     *  One user involved in pull has momentarily suspended the pull
     */
    PULPullStatusSuspended = 1,
    /*!
     *  Pull is waiting for acceptance from receving user
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
/*!
 *  The time at which this pull expires and goes out for pruning. -resetExpiration should be called to set the expiration based on the set duration and current time
 */
@property (nonatomic, strong, readonly) NSDate *expiration;
/*!
 *  The status of this pull
 */
@property (nonatomic) PULPullStatus status;

- (BOOL)containsUser:(PULUser*)user;
- (BOOL)initiatedBy:(PULUser*)user;
- (void)resetExpiration;

@end
