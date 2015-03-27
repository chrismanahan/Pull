//
//  PULPull.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPull.h"

#import "PULUser.h"

@implementation PULPull

- (NSString*)rootName
{
    return @"pulls";
}

- (NSDictionary*)firebaseRepresentation
{
    return nil;
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    self.sendingUser = [[PULUser alloc] initWithUid:repr[@"sendingUser"]];
    self.receivingUser = [[PULUser alloc] initWithUid:repr[@"receivingUser"]];
    
    self.status = [repr[@"status"] integerValue];
    self.expiration = [NSDate dateWithTimeIntervalSince1970:[repr[@"expiration"] integerValue]];
}


@end
