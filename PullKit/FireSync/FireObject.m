//
//  FireObject.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

#import "FireSync.h"

#import <objc/runtime.h>

NSString * const kFireObjectExceptionName = @"FireObjectException";

NSString * const FireObjectDidLoadNotification = @"FireObjectDidLoadNotification";
NSString * const FireObjectDidUpdateNotification = @"FireObjectDidUpdateNotification";

@interface FireObject ()

@property (nonatomic, readwrite, getter=isLoaded) BOOL loaded;

@property (nonatomic, strong) NSMutableDictionary *observers;

@end

@implementation FireObject

#pragma mark - Initialization
- (instancetype)initWithUid:(NSString*)uid;
{
    if (self = [super init])
    {
        _uid = uid;
        
        // if a cached object comes back, we want to return that instead of the new object so we don't create duplicate objects at different memaddrs
        FireObject *cached = [self load];
        
        if (cached)
        {
            return cached;
        }
    }
    
    return self;
}

- (instancetype)initEmptyWithUid:(NSString*)uid;
{
    if (self = [super init])
    {
        _uid = uid;
    }
    
    return self;
}

- (instancetype)initNew;
{
    return [super init];
}

#pragma mark - Subclass
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[FireObject class]])
    {
        return [self.uid isEqualToString:((FireObject*)object).uid];
    }
    return NO;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"(%@) %@", NSStringFromClass([self class]), _uid];
}

#pragma mark - Public
- (FireObject*)load
{
    return [[FireSync sharedSync] loadObject:self];
}

- (void)saveAll;
{
    [[FireSync sharedSync] saveObject:self];
}

- (void)saveKeys:(NSArray*)keys;
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:keys.count];
    NSDictionary *rep = [self firebaseRepresentation];
    
    for (NSString *key in keys)
    {
        dict[key] = rep[key];
    }
    
    [[FireSync sharedSync] saveKeyVals:dict forObject:self];
}

- (void)deleteObject;
{
    [[FireSync sharedSync] deleteObject:self];
}

- (NSArray*)allKeys
{
    unsigned int numProperties;
    objc_property_t *propertyArray = class_copyPropertyList([self class], &numProperties);
    NSMutableArray *propertyStringArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < numProperties; i++)
    {
        objc_property_t property = propertyArray[i];
        NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
        [propertyStringArray addObject:name];
    }
    
    return propertyStringArray;
}

- (BOOL)isObservingKeyPath:(NSString*)keyPath
{
    return _observers[keyPath] != nil;
}

- (void)observeKeyPath:(NSString*)keyPath block:(THObserverBlock)block;
{
    PULLog(@"starting observer on %@ for %@", keyPath, self);
    
    if (!_observers)
    {
        _observers = [[NSMutableDictionary alloc] init];
    }
    
    NSAssert(![self isObservingKeyPath:keyPath], @"observer already exists for key path");
    
    id obs = [THObserver observerForObject:self
                                   keyPath:keyPath
                                     block:block];
    
    _observers[keyPath] = obs;
}

- (void)observeKeyPaths:(NSArray <NSString*>*)keyPaths block:(THObserverBlock)block;
{
    for (NSString *key in keyPaths)
    {
        [self observeKeyPath:key block:block];
    }
}

- (void)stopObservingKeyPath:(NSString*)keyPath;
{
    if ([self isObservingKeyPath:keyPath])
    {
        PULLog(@"stopping observer on %@ for %@", keyPath, self);
        
        [_observers removeObjectForKey:keyPath];
    }
}

- (void)stopObservingKeyPaths:(NSArray <NSString*>*)keyPaths;
{
    for (NSString *key in keyPaths)
    {
        [self stopObservingKeyPath:key];
    }
}

- (void)stopObservingAllKeyPaths;
{
    PULLog(@"stopping observers on all key paths for %@", self);
    [_observers removeAllObjects];
}

#pragma mark - Fireable Protocol
- (NSString*)rootName
{
    NSString *reason = [NSString stringWithFormat:@"%@ must be implemented by a subclass", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:kFireObjectExceptionName
                                   reason:reason
                                 userInfo:nil];
    
}

- (NSDictionary*)firebaseRepresentation;
{
    NSString *reason = [NSString stringWithFormat:@"%@ must be implemented by a subclass", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:kFireObjectExceptionName
                                   reason:reason
                                 userInfo:nil];

}

- (void)loadFromFirebaseRepresentation:(NSDictionary*)repr;
{
    if (!self.loaded)
    {
        self.loaded = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FireObjectDidLoadNotification object:self];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FireObjectDidUpdateNotification object:self];
    }
}

@end
