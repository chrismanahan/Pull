//
//  PULParseMiddleMan.h
//  Pull
//
//  Created by Chris M on 9/26/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <parkour/parkour.h>

#import "PULUser.h"
#import "PULPull.h"

NS_ASSUME_NONNULL_BEGIN

/*****************************
 Constants
 *****************************/
/**
 *  Time interval for refreshing data frequently. 5 seconds
 */
extern const NSTimeInterval kPULIntervalTimeFrequent;
/**
 *  Time interval for refreshing data at a moderate interval. 20 seconds
 */
extern const NSTimeInterval kPULIntervalTimeModerate;
/**
 *  Time interval for refreshing data occasionally. 45 seconds
 */
extern const NSTimeInterval kPULIntervalTimeOccasional;
/**
 *  Time interval for refreshing data seldomly. 2 minutes
 */
extern const NSTimeInterval kPULIntervalTimeSeldom;
/**
 *  Time interval for refreshing data rarely. 5 minutes
 */
extern const NSTimeInterval kPULIntervalTimeRare;

extern NSString * const PULParseObjectsUpdatedLocationsNotification;
extern NSString * const PULParseObjectsUpdatedPullsNotification;

/*****************************
 Blocks
 *****************************/

/**
 *  This block is called when an array of users needs to be passed back as a block
 *
 *  @param users Array of PULUsers
 *  @param error   Error if any
 */
typedef void(^PULUsersBlock)(NSArray <PULUser*> * __nullable users, NSError * __nullable error);
/**
 *  This block is called when a single user needs to be passed back as a block
 *
 *  @param user User
 *  @param error   Error if any
 */
typedef void(^PULUserBlock)(PULUser *user, NSError * __nullable error);
/**
 *  This block is called when an array of pulls is passed to the block
 *
 *  @param pulls Array of pulls
 *  @param error Error if any
 */
typedef void(^PULPullsBlock)(NSArray <PULPull*> * __nullable pulls, NSError * __nullable error);
/**
 *  This block is called to indicate if some sort of write or update action that doesn't return any data is successful or not
 *
 *  @param success Indicates if request was successful
 *  @param error   Error if any
 */
typedef void(^PULStatusBlock)(BOOL success, NSError * __nullable error);

/*****************************
 Interface
 *****************************/

/**
 *  PULParseMiddleMan is exactly that, a middle man between Pull and Parse. This class takes care of all the logic behind interacting with Parse.
 */
@interface PULParseMiddleMan : NSObject

/*****************************
 Class Methods
 *****************************/
+ (instancetype)sharedInstance;

/*****************************
 Instance Methods
 *****************************/

- (PULUser*)currentUser;


/*****************************************************/
/*****************************************************/
#pragma mark - Logging In
/*****************************************************/

- (void)loginWithFacebook:(PULStatusBlock)completion;




/*****************************************************/
/*****************************************************/
#pragma mark - Getting Friends
/*****************************************************/

/**
 *  Retrieves all friends of the logged in user. This does not include users that this user has blocked or have blocked this user
 *
 *  @param completion Block to run when the users are returned. If no users come back in the query, the array will be empty
 */
- (void)getFriendsInBackground:(nullable PULUsersBlock)completion;
/**
 *  Retrieves all users that this user has blocked
 *
 *  @param completion Block to run when the users are returned. If no users come back in the query, the array will be empty
 */
- (void)getBlockedUsersInBackground:(nullable PULUsersBlock)completion;
/**
 *  Gets the cached array of friends
 *
 *  @return Array of friends or nil
 */
- (nullable NSArray<PULUser*>*)cachedFriends;
- (nullable NSArray<PULUser*>*)cachedFriendsNotPulled;
/**
 *  Gets the cached array of blocked users
 *
 *  @return Array of blocked users or nil
 */
- (nullable NSArray<PULUser*>*)cachedBlockedUsers;


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

- (nullable NSArray<PULPull*>*)cachedPulls;
- (nullable PULPull*)nearestPull;



- (void)deletePull:(PULPull*)pull;
- (void)acceptPull:(PULPull*)pull;


/*****************************************************/
/*****************************************************/
#pragma mark - Adding / Removing Friends
/*****************************************************/

/**
 *  Adds an array of users as friends to the logged in user
 *
 *  @param users      Array of users
 *  @param completion Block to run when action is complete
 *
 *  @note This method will assert that the users are not already friends
 */
- (void)friendUsers:(nullable NSArray<PULUser*>*)users;
/**
 *  Adds a user as a friend to the logged in user
 *
 *  @param user       User to add as friend
 *  @param completion Block to run when action is complete
 *
 *  @note This method will assert that the users are not already friends
 */
- (void)friendUser:(PULUser*)user;
/**
 *  Blocks a user
 *
 *  @param user       User to block
 *
 */
- (void)blockUser:(PULUser*)user;
/**
 *  Unblocks a blocked user
 *
 *  @param user User to block
 */
- (void)unblockUser:(PULUser*)user;


/*****************************************************/
/*****************************************************/
#pragma mark - Updating User Data
/*****************************************************/
/**
 *  Updates the current user's location
 *
 *  @param location Location to update to
 *  @param moveType Current movement type
 *  @param posType  Current position type
 */
- (void)updateLocation:(CLLocation*)location movementType:(PKMotionType)moveType positionType:(PKPositionType)posType;



/*****************************************************/
/*****************************************************/
#pragma mark - Monitoring Changes
/*****************************************************/
/**
 *  Starts monitoring changes in location for a given user.
 *
 *  @param user     User to observe for location changes
 *  @param interval kPULIntervalTime constant to define the time interval. This paramater is not asserted and can be any number of seconds other than the constant values available
 *  @param block    Block to run when data is refreshed
 *
 *  @note This method will assert that this user isn't already being observed
 */
- (void)observeChangesInLocationForUser:(PULUser*)user interval:(NSTimeInterval)interval target:(id)target selecter:(SEL)selector;
/**
 *  Stops monitoring for location changes for a specific user
 *
 *  @param user User to stop observing
 */
- (void)stopObservingChangesInLocationForUser:(PULUser*)user;
/**
 *  Stops monitoring location updates for all users that are being monitored
 */
- (void)stopObservingChangesInLocationForAllUsers;




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
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration completion:(nullable PULStatusBlock)completion;

- (void)_registerUser:(PULUser*)user withFbResult:(id)result completion:(void(^)(BOOL success, NSError *error))completion;

@end


NS_ASSUME_NONNULL_END