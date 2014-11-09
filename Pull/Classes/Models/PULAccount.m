//
//  PULAccount.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULAccount.h"

@implementation PULAccount

#pragma mark - Initialization
+ (PULAccount*)currentUser;
{
    static PULAccount *acct = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acct = [[PULAccount alloc] init];
    });
    
    return acct;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _friendManager = [[PULFriendManager alloc] init];
        _pullManager   = [[PULPullManager alloc] init];
        
        _friendManager.delegate = self;
        _pullManager.delegate   = self;
    }
    return self;
}

#pragma mark - Friend Manager Delegate
- (void)friendManagerDidReorganize:(PULFriendManager*)pullManager
{
    
}

- (void)friendManager:(PULFriendManager*)pullManager didSendFriendRequestToUser:(PULUser*)user
{
    
}

- (void)friendManager:(PULFriendManager*)pullManager didAcceptFriendRequestFromUser:(PULUser*)user
{
    
}

- (void)friendManager:(PULFriendManager*)pullManager unfriendUser:(PULUser*)user
{
    
}

#pragma mark - Pull Manager Delegate
- (void)pullManagerDidLoadPulls:(NSArray*)pulls
{
    
}

- (void)pullManagerDidReceivePull:(PULPull*)pull
{
    
}

- (void)pullManagerDidSendPull:(PULPull*)pull
{
    
}

- (void)pullManagerDidRemovePull
{
    
}

- (void)pullManagerDidDetectPullStatusChange:(PULPull*)pull
{
    
}

#pragma mark - Location Updater Delegate
- (void)locationUpdater:(PULLocationUpdater*)updater didUpdateLocation:(CLLocation*)location;
{
    
}

@end
