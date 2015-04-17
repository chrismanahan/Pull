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

@interface FireMutableArray ()

@property (nonatomic, strong) Class fireClass;

@property (nonatomic, strong) NSMutableArray *backingStore;

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
}

#pragma mark - Management
- (void)addAndSaveObject:(FireObject*)anObject;
{
    NSAssert([anObject isKindOfClass:[FireObject class]], @"object must be a subclass of FireObject");
    
    if (![_backingStore containsObject:anObject] || _allowDuplicates)
    {
        [_backingStore addObject:anObject];
        
        [[FireSync sharedSync] addObject:anObject toArray:self forObject:_relatedObject];
    }
}

- (void)removeAndSaveObject:(FireObject*)anObject;
{
    NSAssert([anObject isKindOfClass:[FireObject class]], @"object must be a subclass of FireObject");
    [_backingStore removeObject:anObject];
    
    [[FireSync sharedSync] removeObject:anObject fromArray:self forObject:_relatedObject];
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
    NSMutableArray *store = [[NSMutableArray alloc] initWithCapacity:repr.count];
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
        }
        
        if (![store containsObject:fireObj] || _allowDuplicates)
        {
            [store addObject:fireObj];
        }
    }];
    
    _backingStore = [[NSMutableArray alloc] initWithArray:store];
}

- (NSString*)rootName
{
    return _path;
}

#pragma mark - Properties
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
        if (obj.hasLoaded)
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
    [_backingStore insertObject:anObject atIndex:index];
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    [_backingStore removeObjectAtIndex:index];
}

-(void)addObject:(id)anObject
{
    [_backingStore addObject:anObject];
}

-(void)removeLastObject
{
    [_backingStore removeLastObject];
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [_backingStore replaceObjectAtIndex:index withObject:anObject];
}

@end
