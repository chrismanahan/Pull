//
//  PULFriendFinder.h
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PULUserOld;

typedef void(^PULFriendFinderUserBlock)(NSArray *users);

@interface PULFriendFinder : NSObject

+ (void)findUserByPhone:(NSString*)phone completion:(PULFriendFinderUserBlock)completion;

+ (void)findUserByEmail:(NSString*)email completion:(PULFriendFinderUserBlock)completion;

+ (void)findUserByFullName:(NSString*)fullName completion:(PULFriendFinderUserBlock)completion;

@end
