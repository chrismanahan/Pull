//
//  PULError.h
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PULError : NSObject

/**
 *  Checks if there is an error, and notifies the delegate if there is
 *
 *  @param error Error
 *
 *  @return Yes if error, No if error is nil
 */
+ (BOOL)handleError:(NSError*)error target:(id)target selector:(SEL)selector object:(id)arg;

+ (BOOL)handleError:(NSError*)error;

@end
