//
//  FireObject.h
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

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

/************************************************************************************************************************************
 ************************************************************************************************************************************
 ************************************************************************************************************************************/

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

- (instancetype)initWithUid:(NSString*)uid;

- (instancetype)initNew;

- (void)load;

@end
