//
//  FireSync.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireSync.h"

#import "FireObject.h"
#import "FireMutableArray.h"

#import "PULConstants.h"

#import <Firebase/Firebase.h>

NSString * const kFireSyncExceptionName = @"FireSyncException";

@interface FireSync ()

/*!
 *  Dictionary of dictionaries. Holds the fireobjects that have been loaded along with the observer handler. See snippet below for structure
 
 @code
 {
    "key0": {   "object": obj
                "handler": @(handler)
            },
    "key1": {   "object": obj
                 "handler": @(handler)
            },
 ...
    "keyN-1": {   "object": obj
                    "handler": @(handler)
              }
 }
 @endcode
 */
@property (nonatomic, strong) NSMutableDictionary *cachedObjects;

@end

@implementation FireSync

+ (instancetype)sharedSync;
{
    static FireSync *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[FireSync alloc] init];
        shared.cachedObjects = [[NSMutableDictionary alloc] init];
    });
    
    return shared;
}

#pragma mark - Loading
- (FireObject*)loadObject:(FireObject*)object;
{
    FireThrow(object.uid != nil, @"object uid cannot be nil");
    
    FireObject *cached = [self _getObjectFromCache:object];
    
    if (cached)
    {
        return cached;
    }
    else
    {
        PULLog(@"loading object from firebase %@ - %@", object.rootName, object.uid);
        
        // store in cache
        NSString *key = [self _cacheKeyForObject:object];
        NSMutableDictionary *objDict = [@{@"object": object, @"handler": @(0)} mutableCopy];
        _cachedObjects[key] = objDict;
        
        // start observing changes to this object. this also accounts for the initial load2
        [self _startObservingObject:object];
    }
    
    return nil;
}

#pragma mark - Saving
- (void)saveObject:(FireObject*)object;
{
    Firebase *ref = [self _fireRefForObject:object];
    [ref updateChildValues:object.firebaseRepresentation];
}

- (void)saveKeyVals:(NSDictionary*)keyVals forObject:(FireObject*)object;
{
    Firebase *ref = [self _fireRefForObject:object];
    
    // we need to make sure any instance of NSDate is converted to a timestamp
    NSMutableSet *flaggedKeys = [[NSMutableSet alloc] initWithCapacity:keyVals.count];
    [keyVals enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDate class]])
        {
            [flaggedKeys addObject:(NSString*)key];
        }
    }];
    
    if (flaggedKeys.count > 0)
    {
        NSMutableDictionary *kvs = [keyVals mutableCopy];
        
        for (NSString *key in flaggedKeys)
        {
            NSDate *date = keyVals[key];
            NSInteger timestamp = [date timeIntervalSince1970];
            kvs[key] = @(timestamp);
        }
        
        keyVals = [[NSDictionary alloc] initWithDictionary:kvs];
    }
    
    [ref updateChildValues:keyVals];
}

- (void)addObject:(FireObject*)object toArray:(FireMutableArray*)array forObject:(FireObject*)parentObject;
{
    PULLog(@"adding object (%@) to %@'s array (%@)", object, parentObject, array.rootName);
    Firebase *ref = [[self _fireRefForObject:parentObject] childByAppendingPath:array.rootName];
    
    [ref updateChildValues:@{object.uid: @(YES)}];
}

#pragma mark - Deleting
- (void)deleteObject:(FireObject*)object;
{
    [self _stopObservingObject:object];
    
    Firebase *ref = [self _fireRefForObject:object];
    
    [ref removeValue];
}

- (void)removeObject:(FireObject*)object fromArray:(FireMutableArray*)array forObject:(FireObject*)parentObject;
{
    PULLog(@"removing object (%@) from %@'s array (%@)", object, parentObject, array.rootName);
    Firebase *ref = [self _fireRefForObject:parentObject];
    ref = [[ref childByAppendingPath:array.rootName] childByAppendingPath:object.uid];
    
    [ref removeValue];
}

#pragma mark - Auth
- (void)loginToProvider:(NSString*)provider accessToken:(NSString*)token completion:(void(^)(NSError *error, FAuthData *authData))completion;
{
    Firebase *ref = [self firebase];
    [ref authWithOAuthProvider:provider
                         token:token
           withCompletionBlock:^(NSError *error, FAuthData *authData) {
               if (error)
               {
                   PULLog(@"ERROR logging in to provider (%@): %@", provider, error);
               }
               
               if (completion)
               {
                   completion(error, authData);
               }
           }];
}

- (void)unauth;
{
    Firebase *ref = [self firebase];
    [ref unauth];
}

#pragma mark - Properties
- (BOOL)isAuthed
{
    return [self firebase].authData != nil;
}

#pragma mark - Private
- (Firebase*)firebase
{
    return [[Firebase alloc] initWithUrl:kPULFirebaseURL];
}

- (Firebase*)_fireRefForObject:(FireObject*)object
{
    NSString *root = object.rootName;
    NSString *uid = object.uid;
    
    Firebase *ref = [[self firebase] childByAppendingPath:root];
    
    // if object does not have a uid, it is new and needs one
    if (!uid)
    {
        ref = [ref childByAutoId];
        object.uid = ref.key;
    }
    else
    {
        ref = [ref childByAppendingPath:uid];
    }
    
    return ref;
}

- (void)_startObservingObject:(FireObject*)object
{
    // ensure we don't create a duplicate observer. that would get real messy
    [self _stopObservingObject:object];
    
    PULLog(@"starting observer for object: %@", object);
    Firebase *ref = [self _fireRefForObject:object];
    
    FirebaseHandle handle = [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (![snapshot.value isKindOfClass:[NSNull class]])
        {
            NSDictionary *dict = snapshot.value;
            PULLog(@"Observed snapshot from firebase: %@", snapshot.key);
            
            [object loadFromFirebaseRepresentation:dict];
            
        }
    }];
    
    // add handle to cache
    NSString *key = [self _cacheKeyForObject:object];
    _cachedObjects[key][@"handler"] = @(handle);
}

- (void)_stopObservingObject:(FireObject*)object
{
    NSString *key = [self _cacheKeyForObject:object];
    FireThrow(_cachedObjects[key] != nil, @"object not found in cache");
    
    FirebaseHandle handle = [_cachedObjects[key][@"handler"] integerValue];
    if (handle != 0)
    {
        PULLog(@"removing observer handler for obj: %@", object);
        Firebase *ref = [self _fireRefForObject:_cachedObjects[key][@"object"]];
        [ref removeObserverWithHandle:handle];
    }
}


/*!
 *  Attempts to load a fireobject from the cache. If there is a hit, this loads up
 *
 *  @param object <#object description#>
 *
 *  @return <#return value description#>
 */
- (FireObject*)_getObjectFromCache:(FireObject*)object
{
    NSString *key = [self _cacheKeyForObject:object];
    
    FireObject *cachedObj;
    NSDictionary *cachedDict = [_cachedObjects objectForKey:key];
    if (cachedDict)
    {
        cachedObj = cachedDict[@"object"];
        PULLog(@"loading object from cache (%@)", key);

    }
    
    return cachedObj;
}

/*!
 *  Key for cache dictionary for given object
 *
 *  @param object Object to make key for
 *
 *  @return Key
 */
- (NSString*)_cacheKeyForObject:(FireObject*)object
{
    NSString *root = object.rootName;
    NSString *uid = object.uid;
    NSString *key = [NSString stringWithFormat:@"%@-%@", root, uid];
    return key;
}

- (BOOL)_returnTypeIsPrimitive:(const char*)type
{
    
    if (strcmp(type, "c") == 0 || strcmp(type, "i") == 0 || strcmp(type, "s") == 0 ||
        strcmp(type, "l") == 0 || strcmp(type, "q") == 0 || strcmp(type, "C") == 0 ||
        strcmp(type, "I") == 0 || strcmp(type, "S") == 0 || strcmp(type, "L") == 0 ||
        strcmp(type, "Q") == 0 || strcmp(type, "f") == 0 || strcmp(type, "d") == 0 ||
        strcmp(type, "B") == 0)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)_returnTypeIsDouble:(const char*)type
{
    if (strcmp(type, "f") == 0 || strcmp(type, "d") == 0)
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - c funcs

/*!
 *  Throws an exception (or a fireball) if the assertion fails.
 *
 *  @param assertion Assertion to check
 *  @param reason    Reason for failure
 */
void FireThrow(BOOL assertion, NSString *reason)
{
    if (!assertion)
    {
        @throw [NSException exceptionWithName:kFireSyncExceptionName
                                       reason:reason
                                     userInfo:nil];
    }
}

@end
