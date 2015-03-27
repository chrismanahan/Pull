//
//  PULPull.h
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

@class PULUser;

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

@property (nonatomic, strong) PULUser *sendingUser;
@property (nonatomic, strong) PULUser *receivingUser;

@property (nonatomic, strong) NSDate *expiration;
@property (nonatomic) PULPullStatus status;

@end
