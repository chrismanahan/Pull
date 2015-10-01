//
//  PFQuery+PullQueries.h
//  Pull
//
//  Created by Chris M on 9/30/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PFQuery.h"

extern NSString * const kPULLookupSendingUserKey;
extern NSString * const kPULLookupReceivingUserKey;

@interface PFQuery (PullQueries)

+ (PFQuery*)queryLookupFriends;
+ (PFQuery*)queryLookupBlocked;
+ (PFQuery*)queryLookupPulls;

@end
