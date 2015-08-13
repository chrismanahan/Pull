//
//  PULPush.h
//  Pull
//
//  Created by Development on 11/28/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PULUser;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kPULPushTypeSendFriendRequest;
extern NSString * const kPULPushTypeAcceptFriendRequest;
extern NSString * const kPULPushTypeSendPull;
extern NSString * const kPULPushTypeAcceptPull;

@interface PULPush : NSObject

/**
 *  Send a push notification to a user from a user
 *
 *  @param  pushType    kPULPushType constant for the type of push to send
 *  @param  toUser      User to send push to
 *  @param  fromUser    Originating user
 */
+ (void)sendPushType:(NSString*)pushType to:(PULUser*)toUser from:(PULUser*)fromUser;

NS_ASSUME_NONNULL_END

@end
