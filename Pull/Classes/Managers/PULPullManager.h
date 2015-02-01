//
//  PULPullManager.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULPull.h"

@class PULUser;

/*****************************************
        Delegate Protocol
 *****************************************/

@protocol PULPullManagerDelegate <NSObject>

- (void)pullManagerDidLoadPulls:(NSArray*)pulls;
- (void)pullManagerDidReceivePull:(PULPull*)pull;
- (void)pullManagerDidSendPull:(PULPull*)pull;
- (void)pullManagerDidRemovePull;
- (void)pullManagerDidDetectPullStatusChange:(PULPull*)pull;

- (void)pullManagerEncounteredError:(NSError*)error;

@end

/*****************************************
        Interface
 *****************************************/

@interface PULPullManager : NSObject <PULPullDelegate>

/*****************************************
        Properties
 *****************************************/

@property (nonatomic, weak) id <PULPullManagerDelegate> delegate;

@property (nonatomic, strong, readonly) NSMutableArray *pulls;

/*****************************************
        Instance Methods
 *****************************************/

/**
 *  Fills _pulls array with pull object by fetching from firebase. Also removes any dead references from /me/pulls on firebase
 *
 *  @param friends Array of PULUser objects that are my friends
 */
- (void)initializePulls;

- (void)sendPullToUser:(PULUser*)user;
- (void)acceptPullFromUser:(PULUser*)user;
- (void)unpullUser:(PULUser*)user;
- (void)suspendPullWithUser:(PULUser*)user;
- (void)resumePullWithUser:(PULUser*)user;

- (PULPullStatus)pullStatusWithUser:(PULUser*)user;

@end
