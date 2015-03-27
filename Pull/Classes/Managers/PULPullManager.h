//
//  PULPullManager.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULPullOld.h"

@class PULUserOld;

/*****************************************
        Delegate Protocol
 *****************************************/

@protocol PULPullManagerDelegate <NSObject>

- (void)pullManagerDidLoadPulls:(NSArray*)pulls;
- (void)pullManagerDidReceivePull:(PULPullOld*)pull;
- (void)pullManagerDidTryToReceivePull;
- (void)pullManagerDidSendPull:(PULPullOld*)pull;
- (void)pullManagerDidRemovePull;
- (void)pullManagerDidDetectPullStatusChange:(PULPullOld*)pull;

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

- (void)sendPullToUser:(PULUserOld*)user;
- (void)acceptPullFromUser:(PULUserOld*)user;
- (void)unpullUser:(PULUserOld*)user;
- (void)unpullEveryone;
- (void)suspendPullWithUser:(PULUserOld*)user;
- (void)resumePullWithUser:(PULUserOld*)user;

- (PULPullStatus)pullStatusWithUser:(PULUserOld*)user;

@end
