//
//  FireSync.h
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FireObject;
@class FAuthData;

@interface FireSync : NSObject

+ (instancetype)sharedSync;

/*!
 *  Load up an object from firebase. If the object already exists in cache, this method returns it. Otherwise, the new object is loaded and cached
 *
 *  @param object Object to load
 *
 *  @return Cached fireobject or nil
 */
- (FireObject*)loadObject:(FireObject*)object;

/*!
 *  Saves an entire object to firebase
 *
 *  @param object <#object description#>
 */
- (void)saveObject:(FireObject*)object;

- (void)saveKeyVals:(NSDictionary*)keyVals forObject:(FireObject*)object;

- (void)loginToProvider:(NSString*)provider accessToken:(NSString*)token completion:(void(^)(NSError *error, FAuthData *authData))completion;

@end
