//
//  PULFriendFinder.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULFriendFinder.h"

#import "PULConstants.h"

#import "PULUserOld.h"

#import <Firebase/Firebase.h>

@implementation PULFriendFinder

+ (void)findUserByPhone:(NSString*)phone completion:(PULFriendFinderUserBlock)completion
{
    [self p_findUserWithKey:phone completion:completion];
}

+ (void)findUserByEmail:(NSString*)email completion:(PULFriendFinderUserBlock)completion
{
    [self p_findUserWithKey:email completion:completion];
}

+ (void)findUserByFullName:(NSString*)fullName completion:(PULFriendFinderUserBlock)completion
{
    [self p_findUserWithKey:fullName completion:completion];
}

#pragma mark - Private
+ (void)p_findUserWithKey:(NSString*)key completion:(PULFriendFinderUserBlock)completion
{
    PULLog(@"Looking for user matching: %@", key);
    
    Firebase *ref = [[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"userLookup"] childByAppendingPath:key];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (snapshot)
        {
            if ([snapshot.value isKindOfClass:[NSString class]])
            {
                // we have a single user matching
                NSString *userId = snapshot.value;
                PULLog(@"Found user with user id: %@", userId);
                [self p_userFromUid:userId completion:^(PULUserOld *user) {
                    completion(@[user]);
                }];
            }
            else if ([snapshot.value isKindOfClass:[NSDictionary class]])
            {
                // we have a list of uids
                NSDictionary *userIds = snapshot.value;
                NSMutableArray *userArray = [[NSMutableArray alloc] initWithCapacity:userIds.count];
                __block NSInteger count = userIds.count;
                [userIds enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSString *uid = key;
                    [self p_userFromUid:uid completion:^(PULUserOld *user) {
                        [userArray addObject:user];
                        
                        // if we have all the users, call completion block
                        if (--count == 0)
                        {
                            completion(userArray);
                        }
                    }];
                }];
            }
        }
        else
        {
            completion(nil);
        }
    }];
}

+ (void)p_userFromUid:(NSString*)uid completion:(void(^)(PULUserOld *user))completion
{
    Firebase *ref = [[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:uid];
    
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot)
        {
            NSDictionary *data = snapshot.value;
            
            if (data)
            {
                PULUserOld *user = [[PULUserOld alloc] initFromFirebaseData:data uid:snapshot.key];
                
                completion(user);
            }
            else
            {
                completion(nil);
            }
        }
        else
        {
            completion(nil);
        }
    }];
}

@end
