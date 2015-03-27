//
//  FireObject.m
//  Pull
//
//  Created by Chris Manahan on 3/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "FireObject.h"

#import "FireSync.h"

NSString * const kFireObjectExceptionName = @"FireObjectException";

@implementation FireObject

#pragma mark - Initialization
- (instancetype)initWithUid:(NSString*)uid;
{
    if (self = [super init])
    {
        _uid = uid;
        
        // if a cached object comes back, we want to return that instead of the new object so we don't create duplicate objects at different memaddrs
        FireObject *cached = [[FireSync sharedSync] loadObject:self];
        
        if (cached)
        {
            return cached;
        }
    }
    
    return self;
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
    NSString *reason = [NSString stringWithFormat:@"%@ must be implemented by a subclass", NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:kFireObjectExceptionName
                                   reason:reason
                                 userInfo:nil];
}

@end
