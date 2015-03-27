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

@property (nonatomic, strong) NSArray *allFriends;
@property (nonatomic, strong) NSArray *nearbyFriends;
@property (nonatomic, strong) NSArray *pulledFriends;
@property (nonatomic, strong) NSArray *pullInvitedFriends;
@property (nonatomic, strong) NSArray *pullPendingFriends;
@property (nonatomic, strong) NSArray *blockedUsers;

@property (nonatomic, strong) NSArray *pulls;

@end
