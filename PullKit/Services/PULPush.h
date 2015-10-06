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

typedef NS_ENUM(NSInteger)
{
    PULPushTypeSendPull,
    PULPushTypeAcceptPull
}  PULPushType;

@interface PULPush : NSObject

/**
 *  Send a push notification to a user from a user
 *
 *  @param  type        Type of push to send
 *  @param  toUser      User to send push to
 *  @param  fromUser    Originating user
 */
+ (void)sendPushType:(PULPushType)type to:(PULUser*)toUser from:(PULUser*)fromUser;

+ (void)subscribeToPushNotifications:(PULUser*)user;

NS_ASSUME_NONNULL_END

@end
