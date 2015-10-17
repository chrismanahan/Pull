//
//  PULParseMiddleMan+Pulls.h
//  Pull
//
//  Created by Chris M on 10/17/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULParseMiddleMan.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  This block is called when an array of pulls is passed to the block
 *
 *  @param pulls Array of pulls
 *  @param error Error if any
 */
typedef void(^PULPullsBlock)(NSArray <PULPull*> * __nullable pulls, NSError * __nullable error);

@class PULPull;

@interface PULParseMiddleMan (Pulls)

/*****************************************************/
/*****************************************************/
#pragma mark - Getting Pulls
/*****************************************************/
/**
 *  Gets all pulls for the current user in status order. Active pulls will be at the front of the array, and pending at the end.
 *
 *  @discussion If a pull is returned in the internal query that is past it's expiration, it will mark that pull for deletion. If the pull was already marked for deletion, this will delete the pull altogether. Marking a pull for deletion is the solution to making sure we don't delete a pull when the other user involved is currently reading that same pull.
 *
 *  @param completion Block to run when pulls are returned.
 *
 *  @note Completion block will run twice if cached pulls are available
 *
 */
- (void)getPullsInBackground:(nullable PULPullsBlock)completion;
- (void)getPullsInBackground:(nullable PULPullsBlock)completion ignoreCache:(BOOL)ignoreCache;


- (void)deletePull:(PULPull*)pull;
- (void)acceptPull:(PULPull*)pull;

- (void)deleteAllPullsCompletion:(void(^)())completion;

/*****************************************************/
/*****************************************************/
#pragma mark - Sending Pulls
/*****************************************************/
/**
 *  Sends a pull to a user
 *
 *  @param user       User to send pull to
 *  @param completion Completion block to run
 */
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration completion:(nullable void(^)(BOOL success, NSError * __nullable error))completion;


@end


NS_ASSUME_NONNULL_END