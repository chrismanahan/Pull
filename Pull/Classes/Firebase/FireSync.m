//
//  FireSync.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireSync.h"

#import "FireObject.h"

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

#pragma mark - Public
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
        
        Firebase *ref = [self _fireRefForObject:object];
        
        // store in cache
        NSString *key = [self _cacheKeyForObject:object];
        NSMutableDictionary *objDict = [@{@"object": object, @"handler": @(0)} mutableCopy];
        _cachedObjects[key] = objDict;
        
        // start observing changes to this object. this also accounts for the initial load2
        [self _startObservingObject:object];
    }
    
    return nil;
}

- (void)_startObservingObject:(FireObject*)object
{
    // ensure we don't create a duplicate observer. that would get real messy
    [self _stopObservingObject:object];
    
    PULLog(@"starting observer for object: %@", object);
    Firebase *ref = [self _fireRefForObject:object];
    
    FirebaseHandle handle = [ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (![snapshot isKindOfClass:[NSNull class]])
        {
            NSDictionary *dict = snapshot.value;
            PULLog(@"Observed snapshot from firebase: %@", dict);
            
            [object loadFromFirebaseRepresentation:dict];

        }
        else
        {
            PULLog(@"ERROR OBSERVING FROM FIREBASE.\n\tRoot:\t%@\n\tUID:%@", object.rootName, object.uid);
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

#pragma mark - Private
- (Firebase*)firebase
{
    return [[Firebase alloc] initWithUrl:kPULFirebaseURL];
}

- (Firebase*)_fireRefForObject:(FireObject*)object
{
    NSString *root = object.rootName;
    NSString *uid = object.uid;
    
    Firebase *ref = [[[self firebase] childByAppendingPath:root] childByAppendingPath:uid];
    
    return ref;
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
