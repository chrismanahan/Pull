//
//  PULPush.h
//  Pull
//
//  Created by Development on 11/28/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PULUserOld;

extern NSString * const kPULPushTypeSendFriendRequest;
extern NSString * const kPULPushTypeAcceptFriendRequest;
extern NSString * const kPULPushTypeSendPull;
extern NSString * const kPULPushTypeAcceptPull;

@interface PULPush : NSObject

+ (void)sendPushType:(NSString*)pushType to:(PULUserOld*)toUser from:(PULUserOld*)fromUser;

@end
