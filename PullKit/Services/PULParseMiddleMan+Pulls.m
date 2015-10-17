//
//  PULParseMiddleMan+Pulls.m
//  Pull
//
//  Created by Chris M on 10/17/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULParseMiddleMan+Pulls.h"

#import "PFQuery+PullQueries.h"
#import "PFACL+Users.h"

#import "NSDate+Utilities.h"

#import "PULPush.h"
#import "PULPull.h"
#import "PULUser.h"

#import "Amplitude.h"

@interface PULParseMiddleMan ()

- (void)_runBlockInBackground:(void(^)())block;
- (void)_runBlockOnMainQueue:(void(^)())block;

@end

@implementation PULParseMiddleMan (Pulls)

#pragma mark - Getting pulls
- (void)getPullsInBackground:(nullable PULPullsBlock)completion
{
    [self getPullsInBackground:completion ignoreCache:NO];
}

- (void)getPullsInBackground:(nullable PULPullsBlock)completion ignoreCache:(BOOL)ignoreCache;
{
    if ([self.cache cachedPulls] && !ignoreCache)
    {
        completion([self.cache cachedPullsOrdered], nil);
    }
    
    [self _runBlockInBackground:^{
        PFQuery *query  = [PFQuery queryLookupPulls];
        NSError *err;
        NSMutableArray *objs = [[query findObjects:&err] mutableCopy];
        NSMutableIndexSet *flaggedIndexes = [[NSMutableIndexSet alloc] init];
        
        for (PULPull *pull in objs)
        {
            PULUser *otherUser = [pull otherUser];
            [otherUser.location fetchIfNeeded];
            
            if ([pull.expiration isInPast] && pull.duration != kPullDurationAlways)
            {
                [flaggedIndexes addIndex:[objs indexOfObject:pull]];
            }
            else
            {
                // need to explicity set this user
                if ([pull.sendingUser isEqual:otherUser])
                {
                    pull.receivingUser = [PULUser currentUser];
                }
                else
                {
                    pull.sendingUser = [PULUser currentUser];
                }
            }
        }
        
        // remove expired pulls and delete
        NSArray *flaggedPulls = [objs objectsAtIndexes:flaggedIndexes];
        [objs removeObjectsAtIndexes:flaggedIndexes];
        
        if (flaggedPulls.count > 0)
        {
            for (PULPull *pull in flaggedPulls)
            {
                [self deletePull:pull];
            }
        }
        
        // set these pulls into the cache
        [self.cache setPulls:objs];
        
        // run completion
        [self _runBlockOnMainQueue:^{
            completion(objs, err);
        }];
    }];
    
}

#pragma mark - Pulls
- (void)sendPullToUser:(PULUser*)user duration:(NSTimeInterval)duration completion:(nullable PULStatusBlock)completion
{
    [self.cache resetPullSorting];
    [self getPullsInBackground:^(NSArray<PULPull *> * _Nullable pulls, NSError * _Nullable error) {
        if (error)
        {
            [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventSendPull
                       withEventProperties:@{@"duration": @(duration / 60 / 60),
                                             @"success": @NO}];
            
            completion(NO, error);
            return;
        }
        
        if (pulls)
        {
            for (PULPull *pull in pulls)
            {
                if ([pull containsUser:user])
                {
                    // pull already exists with this user
                    [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventSendPull
                               withEventProperties:@{@"duration": @(duration / 60 / 60),
                                                     @"success": @NO,
                                                     @"error": @"Already Existed"}];
                    completion(NO, nil);
                    return;
                }
            }
        }
        
        [self _runBlockInBackground:^{
            // create new pull
            PULPull *pull = [PULPull object];
            pull.sendingUser = [PULUser currentUser];
            pull.receivingUser = user;
            pull.status = PULPullStatusPending;
            pull.duration = duration;
            pull.together = NO;
            pull.nearby = NO;
            pull.ACL = [PFACL ACLWithUser:[PULUser currentUser] and:user];
            
            BOOL success = [pull save];
            
            [self _runBlockOnMainQueue:^{
                //send push to other user
                [PULPush sendPushType:PULPushTypeSendPull to:user from:[PULUser currentUser]];
                [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventSendPull
                           withEventProperties:@{@"duration": @(duration / 60 / 60),
                                                 @"success": @YES}];
                completion(success, nil);;
            }];
        }];
    } ignoreCache:YES];
}

- (void)acceptPull:(PULPull*)pull
{
    NSAssert([pull.receivingUser isEqual:[PULUser currentUser]], @"can only accept a pull if we're the receiver");
    [self _runBlockInBackground:^{
        [self.cache resetPullSorting];
        pull.status = PULPullStatusPulled;
        pull.expiration = [NSDate dateWithTimeIntervalSinceNow:pull.duration];
        [pull save];
        
        [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventAcceptPull
                   withEventProperties:@{@"duration": @(pull.duration / 60 / 60)}];
        
        //send push to other user
        [PULPush sendPushType:PULPushTypeAcceptPull to:[pull otherUser] from:[PULUser currentUser]];
    }];
}

- (void)deletePull:(PULPull*)pull
{
    [self.cache resetPullSorting];
    [[Amplitude instance] logEvent:kAnalyticsAmplitudeEventDeclinePull
               withEventProperties:@{@"duration": @(pull.duration / 60 / 60)}];
    
    // remove from cache
    [self.cache removePull:pull];
    
    // delete from parse
    [pull deleteEventually];
}

- (void)deleteAllPullsCompletion:(void(^)())completion
{
    [self.cache resetPullSorting];
    [PFObject deleteAllInBackground:[self.cache cachedPulls] block:^(BOOL succeeded, NSError * _Nullable error) {
        [self.cache setPulls:nil];
        completion();
    }];
}



@end
