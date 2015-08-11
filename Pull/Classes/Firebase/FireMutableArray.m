//
//  FireMutableArray.m
//  Pull
//
//  Created by admin on 4/9/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireMutableArray.h"

#import "FireObject.h"

#import "FireSync.h"

NSString * const FireArrayObjectAddedNotification = @"FireArrayObjectAddedNotification";
NSString * const FireArrayObjectRemovedNotification = @"FireArrayObjectRemovedNotification";
NSString * const FireArrayEmptyNotification = @"FireArrayEmptyNotification";
NSString * const FireArrayNoLongerEmptyNotification = @"FireArrayNoLongerEmptyNotification";

@interface _FireKeyChange : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) FireArrayObjectChangedBlock block;
@property (nonatomic, strong) NSMutableArray *observers;

@end

@implementation _FireKeyChange

- (instancetype)initForKey:(NSString*)key block:(FireArrayObjectChangedBlock)block
{
    self = [super init];
    if (self) {
        
        _key = [key copy];
        _block = [block copy];
        _observers = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface FireMutableArray ()

@property (nonatomic, strong) Class fireClass;

@property (nonatomic, strong) NSMutableArray *backingStore;

@property (nonatomic, strong) NSMutableArray *observers;

@property (nonatomic, copy) FireArrayLoadedBlock loadedBlock;

@property (nonatomic, strong) NSMutableArray *keyChangeBlocks;

@end

@implementation FireMutableArray

#pragma mark - Initialization
- (instancetype)initForClass:(Class)fireClass relatedObject:(FireObject*)relatedObject path:(NSString*)path;
{
    if (self = [super init])
    {
        [self initializeForClass:fireClass relatedObject:relatedObject path:path];
    }
    return self;
}

- (void)initializeForClass:(Class)fireClass relatedObject:(FireObject*)relatedObject path:(NSString*)path;
{
    NSAssert([fireClass isSubclassOfClass:[FireObject class]], @"must use subclass of FireObject");
    
    _fireClass = fireClass;
    _relatedObject = relatedObject;
    _path = path;
    
    _backingStore = [[NSMutableArray alloc] init];
    _observers = [[NSMutableArray alloc] init];
    _keyChangeBlocks = [[NSMutableArray alloc] init];
}

#pragma mark - Management
- (void)addAndSaveObject:(FireObject*)anObject;
{
    NSAssert([anObject isKindOfClass:[FireObject class]], @"object must be a subclass of FireObject");
    
    if (![_backingStore containsObject:anObject] || _allowDuplicates)
    {
        [_backingStore addObject:anObject];
        
        [[FireSync sharedSync] addObject:anObject toArray:self forObject:_relatedObject];
        
        // check if we need to add an observer for this object
        [self _addObserversIfNeededForObject:anObject];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FireArrayObjectAddedNotification
                                                            object:self];
        
        if (_backingStore.count == 1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:FireArrayNoLongerEmptyNotification
                                                                object:self];
        }
    }
}

- (void)removeAndSaveObject:(FireObject*)anObject;
{
    NSAssert([anObject isKindOfClass:[FireObject class]], @"object must be a subclass of FireObject");
    [_backingStore removeObject:anObject];
    
    [[FireSync sharedSync] removeObject:anObject fromArray:self forObject:_relatedObject];
    
    // check if we need to remove this object from being observed
    [self _removeObserversIfNeededForObject:anObject];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FireArrayObjectRemovedNotification
                                                        object:self];
    
    if (_backingStore.count == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FireArrayEmptyNotification
                                                            object:self];
    }
}

#pragma mark - Block running
#pragma mark Loading
- (void)registerLoadedBlock:(FireArrayLoadedBlock)block;
{
    PULLog(@"registered loaded block to %@", NSStringFromClass([self class]));
    _loadedBlock = [block copy];
    
    if (self.isLoaded)
    {
        _loadedBlock(self);
    }
}

- (void)unregisterLoadedBlock;
{
    PULLog(@"unregisted loaded block from %@", NSStringFromClass([self class]));
    _loadedBlock = nil;
}

#pragma mark Keys
- (void)registerForKeyChange:(NSString*)key onAllObjectsWithBlock:(FireArrayObjectChangedBlock)block;
{
    _FireKeyChange *keyChange = [[_FireKeyChange alloc] initForKey:key block:block];
    
    for (FireObject *obj in _backingStore)
    {
        id obs = [THObserver observerForObject:obj keyPath:key block:^{
            keyChange.block(self, obj);
        }];
        
        [keyChange.observers addObject:@{obj.uid: obs}];
    }
    
    [_keyChangeBlocks addObject:keyChange];
}

- (void)unregisterForKeyChange:(NSString*)key;
{
    NSMutableIndexSet *indices = [[NSMutableIndexSet alloc] init];
    for (_FireKeyChange *change in _keyChangeBlocks)
    {
        if ([change.key isEqualToString:key])
        {
            [indices addIndex:[_keyChangeBlocks indexOfObject:change]];
        }
    }
    
    [_keyChangeBlocks removeObjectsAtIndexes:indices];
}

- (void)unregisterForAllKeyChanges;
{
    [_keyChangeBlocks removeAllObjects];
}

- (BOOL)isRegisteredForKeyChange:(NSString*)key;
{
    BOOL isRegistered = NO;
    
    for (_FireKeyChange *change in _keyChangeBlocks)
    {
        if ([change.key isEqualToString:key])
        {
            isRegistered = YES;
            break;
        }
    }
    
    return isRegistered;
}

#pragma mark - Fireable Protocol
- (NSDictionary*)firebaseRepresentation
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    for (FireObject *obj in _backingStore)
    {
        dict[obj.uid] = @(YES);
    }
    
    return (NSDictionary*)dict;
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    NSMutableArray *store = [[NSMutableArray alloc] init];
    if (repr)
    {
        [repr enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *uid = (NSString*)key;
            
            FireObject *fireObj;
            if (_emptyObjects)
            {
                fireObj = [[_fireClass alloc] initEmptyWithUid:uid];
            }
            else
            {
                fireObj = [[_fireClass alloc] initWithUid:uid];
                
                if (!fireObj.isLoaded)
                {
                    __block id obs = [THObserver observerForObject:fireObj keyPath:@"loaded" block:^{
                        [_observers removeObject:obs];
                        
                        if (_observers.count == 0 && _loadedBlock)
                        {
                            _loadedBlock(self);
                        }
                    }];
                    
                    [_observers addObject:obs];
                }
            }
            
            if (![store containsObject:fireObj] || _allowDuplicates)
            {
                [store addObject:fireObj];
                [self _addObserversIfNeededForObject:fireObj];
            }
        }];
    }
    
    _backingStore = [[NSMutableArray alloc] initWithArray:store];
    
    NSAssert(!(self.isLoaded && _observers.count != 0) , @"why do we have observers if we're not loaded?");
    
    if (_loadedBlock && ((!_emptyObjects && self.isLoaded) || (_backingStore.count == 0)))
    {
        _loadedBlock(self);
    }
    
}

- (NSString*)rootName
{
    return _path;
}

#pragma mark - Private
- (void)_addObserversIfNeededForObject:(FireObject*)anObject
{
    if (_keyChangeBlocks.count)
    {
        for (_FireKeyChange *change in _keyChangeBlocks)
        {
            id obs = [THObserver observerForObject:anObject keyPath:change.key block:^{
                change.block(self, anObject);
            }];
            
            [change.observers addObject:@{anObject.uid: obs}];
        }
    }
}

- (void)_removeObserversIfNeededForObject:(FireObject*)anObject
{
    if (_keyChangeBlocks.count)
    {
        for (_FireKeyChange *change in _keyChangeBlocks)
        {
            NSMutableIndexSet *indices = [[NSMutableIndexSet alloc] init];
            [change.observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *key = [obj allKeys][0];
                if ([key isEqualToString:anObject.uid])
                {
                    [indices addIndex:idx];
                }
            }];
            [change.observers removeObjectsAtIndexes:indices];
        }
    }
}

#pragma mark - Properties
- (BOOL)hasLoadBlock
{
    return (BOOL)_loadedBlock;
}

- (BOOL)isLoaded
{
    BOOL loaded = YES;
    
    if (_backingStore.count)
    {
        for (FireObject *obj in _backingStore)
        {
            if (obj.isLoaded)
            {
                loaded = YES;
            }
            else
            {
                loaded = NO;
                break;
            }
        }
    }
    
    return loaded;
}

- (NSUInteger)loadedCount
{
    return [self loadedObjects].count;
}

- (NSArray*)loadedObjects
{
    FireMutableArray *arr = [[FireMutableArray alloc] initForClass:_fireClass
                                                     relatedObject:_relatedObject
                                                              path:_path];
    for (FireObject *obj in _backingStore)
    {
        if (obj.isLoaded)
        {
            [arr addObject:obj];
        }
    }
    
    return arr;
}

#pragma mark -
#pragma mark NSArray

-(NSUInteger)count
{
    return [_backingStore count];
}

-(id)objectAtIndex:(NSUInteger)index
{
    return [_backingStore objectAtIndex:index];
}

#pragma mark NSMutableArray

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [self _addObserversIfNeededForObject:anObject];
    [_backingStore insertObject:anObject atIndex:index];
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    [self _removeObserversIfNeededForObject:_backingStore[index]];
    [_backingStore removeObjectAtIndex:index];
}

-(void)addObject:(id)anObject
{
    [_backingStore addObject:anObject];
    
    [self _addObserversIfNeededForObject:anObject];
}

- (void)removeAllObjects
{
    for (FireObject *obj in _backingStore)
    {
        [self _removeObserversIfNeededForObject:obj];
    }
    [_backingStore removeAllObjects];
}

-(void)removeLastObject
{
    [self _removeObserversIfNeededForObject:[_backingStore lastObject]];
    [_backingStore removeLastObject];
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [self _removeObserversIfNeededForObject:_backingStore[index]];
    [self _addObserversIfNeededForObject:anObject];
    
    [_backingStore replaceObjectAtIndex:index withObject:anObject];
}

@end
