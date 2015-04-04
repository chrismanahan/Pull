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
        FireObject *cached = [self load];
        
        if (cached)
        {
            return cached;
        }
    }
    
    return self;
}

- (instancetype)initEmptyWithUid:(NSString*)uid;
{
    if (self = [super init])
    {
        _uid = uid;
    }
    
    return self;
}

- (instancetype)initNew;
{
    return [super init];
}

#pragma mark - Subclass
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[FireObject class]])
    {
        return [self.uid isEqualToString:((FireObject*)object).uid];
    }
    return NO;
}

#pragma mark - Public
- (FireObject*)load
{
    return [[FireSync sharedSync] loadObject:self];
}

- (void)saveAll;
{
    [[FireSync sharedSync] saveObject:self];
}

- (void)saveKeys:(NSArray*)keys;
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys)
    {
        dict[key] = self.firebaseRepresentation[key];
    }
    
    [[FireSync sharedSync] saveKeyVals:dict forObject:self];
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
