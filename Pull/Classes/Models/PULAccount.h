//
//  PULAccountOld.h
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULPull.h"

@interface PULAccount : PULUser

+ (void)loginWithFacebookToken:(NSString*)accessToken completion:(void(^)(PULAccount *account, NSError *error))completion;

+ (instancetype)initializeCurrentUser:(NSString*)uid;

+ (instancetype)currentUser;

- (void)logout;

- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration;
- (void)acceptPull:(PULPull*)pull;
- (void)cancelPull:(PULPull*)pull;


@end
