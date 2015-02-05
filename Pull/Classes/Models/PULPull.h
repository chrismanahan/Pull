//
//  PULPull.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULFirebaseProtocol.h"

@class PULUser;
@class PULPull;


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


@protocol PULPullDelegate <NSObject>

@required
- (void)pull:(PULPull*)pull didUpdateStatus:(PULPullStatus)status;
- (void)pull:(PULPull *)pull didUpdateExpiration:(NSDate*)date;
- (void)pullDidDelete:(PULPull*)pull;

@end

@interface PULPull : NSObject <PULFirebaseProtocol>

/*******************************
        Properties
 ******************************/

/**
 *  Pull's delegate
 */
@property (nonatomic, weak) id <PULPullDelegate> delegate;

/**
 *  UID
 */
@property (nonatomic, copy) NSString *uid;

/*!
 *  User who is sending the pull
 */
@property (nonatomic, strong) PULUser *sendingUser;

/*!
 *  User to receive the pull
 */
@property (nonatomic, strong) PULUser *receivingUser;

/**
 *   Pull status
 */
@property (nonatomic, assign) PULPullStatus status;

/**
 *  Expiration date of pull
 */
@property (nonatomic, strong) NSDate *expiration;

/*******************************
        Instance Methods
 ******************************/

/**
 *  Instantiates a new pull with the status of pending. Does not save to firebase, that's the job of the manager
 *
 *  @param sendingUser   Sending user
 *  @param receivingUser Receiving user
 *
 *  @return Pull
 */
- (instancetype)initNewPullBetweenSender:(PULUser*)sendingUser receiver:(PULUser*)receivingUser;

/**
 *  Instantiates an existing pull that was pulled down from fire base
 *
 *  @param sendingUser   the sending user
 *  @param receivingUser the receiving user
 *  @param status        status
 *  @param expiration    expiration
 *
 *  @return Pull
 */
- (instancetype)initExistingPullWithUid:(NSString*)uid sender:(PULUser*)sendingUser receiver:(PULUser*)receivingUser status:(PULPullStatus)status expiration:(NSDate*)expiration;

/**
 *  Checks if pull contains a user
 *
 *  @param user User
 */
- (BOOL)containsUser:(PULUser*)user;

- (void)startObserving;

- (void)stopObserving;

@end
