//
//  PULLocalPush.h
//  Pull
//
//  Created by Chris M on 8/15/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PULLocalPush : NSObject

+ (void)sendLocalPushWithMessage:(NSString*)message;
+ (void)sendLocalPushWithMessage:(NSString*)message delay:(double)delay;

@end
