//
//  PULFirebaseProtocol.h
//  Pull
//
//  Created by Development on 11/8/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PULFirebaseProtocol <NSObject>

@required
/**
 *  Converts object to dictionary representation to be store in firebase
 *
 *  @return Dictionary
 */
- (NSDictionary*)firebaseRepresentation;

@end
