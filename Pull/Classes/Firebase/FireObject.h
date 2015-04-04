//
//  FireObject.h
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*****************************************
 Protocol
 *****************************************/

/*!
 *  Any object that is stored in firebase must conform to Fireable protocol. This is the bridge between your obj-c models and your firebase models
 */
@protocol Fireable <NSObject>

@required
/*!
 *  Name of root firebase base
 */
@property (nonatomic, readonly, strong) NSString *rootName;

/*!
 *  Dictionary representation of object to be stored in firebase
 *
 *  @return Dictionary
 */
- (NSDictionary*)firebaseRepresentation;

/*!
 *  Loads the properties of the object from a dictionary received from firebase.
 
 @note Be sure to validate a key exists before loading a property, because a partial dictionary representation could be passed to this method
 *
 *  @param repr Firebase representaiton as a dictionary
 */
- (void)loadFromFirebaseRepresentation:(NSDictionary*)repr;

@end

/*****************************************
 Interface
 *****************************************/

/*!
 *  A model that is stored in firebase
 */
@interface FireObject : NSObject <Fireable>

/*****************************************
 Properties
 *****************************************/

/*!
 *  UID of object
 */
@property (nonatomic, copy) NSString *uid;

/*****************************************
 Instance Methods
 *****************************************/

/*!
 *  Initializes a new object and loads up it's variable from firebase
 *
 *  @param uid UID of object
 *
 *  @return Instance
 */
- (instancetype)initWithUid:(NSString*)uid;

/*!
 *  Initializes a new object without loading from firebase. This is good to use for arrays where loading more than just the reference to the object is unnecesary. If data is needed at a later time, call -load
 *
 *  @param uid UID of object
 *
 *  @return Instance
 */
- (instancetype)initEmptyWithUid:(NSString*)uid;

/*!
 *  Initializes a new fire object that does not exist in firebase. Once all properties of the object are set, call save to send the data to firebase.
 *
 *  @return Instance
 */
- (instancetype)initNew;

/*!
 *  Loads an object's data from firebase or retrieves it from the cache
 *
 *  @return Cached object if already cached
 */
- (FireObject*)load;

/*!
 *  Saves a whole object to firebase. This can only be used when the user has permission to save all parts of the object.
 */
- (void)saveAll;

/*!
 *  Saves an object's specific keys to firebase. The keys array should reflect the firebase keys, not the object's property names.
 *
 *  @param keys Array of keys to save to firebase
 */
- (void)saveKeys:(NSArray*)keys;

@end
