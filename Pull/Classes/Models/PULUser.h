//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULFirebaseProtocol.h"

@interface PULUser : NSObject <PULFirebaseProtocol>

@property (nonatomic, strong) NSString *uid;

@end
