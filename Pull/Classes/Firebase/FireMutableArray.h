//
//  FireMutableArray.h
//  Pull
//
//  Created by admin on 4/9/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FireObject.h"

@class FireMutableArray;

typedef void(^FireArrayLoadedBlock)(FireMutableArray *objects);
typedef void(^FireArrayObjectChangedBlock)(FireMutableArray *array, FireObject *object);

extern NSString * const FireArrayObjectAddedNotification;
extern NSString * const FireArrayObjectRemovedNotification;
extern NSString * const FireArrayEmptyNotification;
extern NSString * const FireArrayNoLongerEmptyNotification;

@interface FireMutableArray : NSMutableArray <Fireable>

/**
 *  Object related to this array. This is the object that holds reference to this array
 */
@property (nonatomic, weak) FireObject *relatedObject;

/**
 *  Key that holds this array. 
 
 @discussion When saving to firebase, the full path of firebase is first derived from the relatedObject, and then appended this path. So for example, if your relatedObject had the root name users, the uid 1234 and path here was set to friends, your firebase url would be: foo.firebase.com/users/1234/friends
 */
@property (nonatomic, strong) NSString *path;

/**
 *  Flag indiciating if we should load the objects or not when placing in array. Defaults to NO
 */
@property (nonatomic, assign) BOOL emptyObjects;
/**
 *  Flag indicating if we should allow duplicates of objects. Defaults to NO
 */
@property (nonatomic, assign) BOOL allowDuplicates;

/**
 *  Similar to count, but only returns the count of objects that have been loaded
 */
@property (nonatomic, readonly) NSUInteger loadedCount;

/**
 *  Creates a copy of this array that only includes objects that have been loaded
 */
@property (nonatomic, readonly) FireMutableArray *loadedObjects;

@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

@property (nonatomic, readonly) BOOL hasLoadBlock;

- (instancetype)initForClass:(Class)fireClass
               relatedObject:(FireObject*)relatedObject
                        path:(NSString*)path
NS_DESIGNATED_INITIALIZER;

- (void)addAndSaveObject:(FireObject*)anObject;

- (void)removeAndSaveObject:(FireObject*)anObject;

- (void)registerLoadedBlock:(FireArrayLoadedBlock)block;

- (void)unregisterLoadedBlock;

- (void)registerForKeyChange:(NSString*)key onAllObjectsWithBlock:(FireArrayObjectChangedBlock)block;

- (void)unregisterForKeyChange:(NSString*)key;

- (void)unregisterForAllKeyChanges;

- (BOOL)isRegisteredForKeyChange:(NSString*)key;

@end
