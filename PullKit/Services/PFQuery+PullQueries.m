//
//  PFQuery+PullQueries.m
//  Pull
//
//  Created by Chris M on 9/30/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PFQuery+PullQueries.h"

#import "PULUser.h"
#import "PULPull.h"

NSString * const kPULLookupSendingUserKey = @"sendingUser";
NSString * const kPULLookupReceivingUserKey = @"receivingUser";

@implementation PFQuery (PullQueries)

#pragma mark - Public
+ (PFQuery*)queryLookupFriends
{
    return [self _queryLookupUsersBlocked:NO];
}

+ (PFQuery*)queryLookupBlocked
{
    return [self _queryLookupUsersBlocked:YES];
}

+ (PFQuery*)queryLookupPulls
{
    PFQuery *lookupQuery = [self _queryInteraction:[PULPull parseClassName]];
    lookupQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    
    return lookupQuery;
}

#pragma mark - Private
+ (PFQuery*)_queryLookupUsersBlocked:(BOOL)blocked
{
    PULUser *acct = [PULUser currentUser];
    
    // lookup queries
    PFQuery *lookupQuery = [self _queryInteraction:@"FriendLookup"];
    [lookupQuery whereKey:@"isBlocked" equalTo:@(blocked)];
    if (blocked)
    {
        [lookupQuery whereKey:@"blockedBy" equalTo:acct];
    }
    [lookupQuery whereKey:@"isAccepted" equalTo:@YES];
    
    [lookupQuery includeKey:@"settings"];
    
    
    return lookupQuery;
}

+ (PFQuery*)_queryInteraction:(NSString*)tableName
{
    return [self _queryInteraction:tableName cachePolicy:kPFCachePolicyNetworkElseCache];
}

+ (PFQuery*)_queryInteraction:(NSString*)tableName cachePolicy:(PFCachePolicy)cachePolicy
{
    PULUser *acct = [PULUser currentUser];
    
    PFQuery *senderQuery = [PFQuery queryWithClassName:tableName];
    [senderQuery whereKey:kPULLookupSendingUserKey equalTo:acct];
    [senderQuery whereKey:kPULLookupReceivingUserKey notEqualTo:acct];
    
    PFQuery *recQuery = [PFQuery queryWithClassName:tableName];
    [recQuery whereKey:kPULLookupReceivingUserKey equalTo:acct];
    [recQuery whereKey:kPULLookupSendingUserKey notEqualTo:acct];
    
    PFQuery *lookupQuery = [PFQuery orQueryWithSubqueries:@[senderQuery, recQuery]];
    
    [lookupQuery includeKey:kPULLookupReceivingUserKey];
    [lookupQuery includeKey:kPULLookupSendingUserKey];
    
    return lookupQuery;
}


@end
