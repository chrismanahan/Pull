//
//  PULPull.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPull.h"

#import "PULUser.h"

#import "PULConstants.h"

#import <Firebase/Firebase.h>

@interface PULPull ()

@property (nonatomic, strong) Firebase *fireRef;

@property (nonatomic, assign) FirebaseHandle statusObserverHandle;

@end

@implementation PULPull

#pragma mark - Initialization
- (instancetype)initNewPullBetweenSender:(PULUser*)sendingUser receiver:(PULUser*)receivingUser;
{
    return [self initExistingPullWithSender:sendingUser receiver:receivingUser status:PULPullStatusPending expiration:nil];
}

- (instancetype)initExistingPullWithSender:(PULUser*)sendingUser receiver:(PULUser*)receivingUser status:(PULPullStatus)status expiration:(NSDate*)expiration
{
    NSParameterAssert(sendingUser);
    NSParameterAssert(receivingUser);
    
    if (self = [self init])
    {
        _sendingUser   = sendingUser;
        _receivingUser = receivingUser;
        _status        = status;
        _expiration    = expiration;
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    }
    return self;
}

#pragma mark - Public
- (BOOL)containsUser:(PULUser*)user;
{
    NSParameterAssert(user);
    
    if ([_sendingUser isEqual:user] ||
        [_receivingUser isEqual:user])
    {
        return YES;
    }
    
    return NO;
}

- (void)startObservingStatus;
{
    // set path to firebase if it hasn't been already
    if (![_fireRef.key isEqualToString:_uid])
    {
        _fireRef = [[_fireRef childByAppendingPath:@"pulls"] childByAppendingPath:_uid];
    }
    
    if (_statusObserverHandle)
    {
        [self stopObservingStatus];
    }
    
    _statusObserverHandle = [_fireRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        // pull changed, check status
        NSDictionary *data = snapshot.value;
        
        _status = (PULPullStatus)[data[@"status"] integerValue];
        
        if ([_delegate respondsToSelector:@selector(pull:didUpdateStatus:)])
        {
            [_delegate pull:self didUpdateStatus:_status];
        }
    }];
}

- (void)stopObservingStatus;
{
    [_fireRef removeObserverWithHandle:_statusObserverHandle];
    
    _statusObserverHandle = 0;
}

#pragma mark - Firebase Protocol
- (NSDictionary*)firebaseRepresentation
{
    NSInteger seconds = 0;
    if (_expiration)
    {
        seconds = [_expiration timeIntervalSince1970];
    }
    
    return @{@"sendingUser": _sendingUser.uid,
             @"receivingUser": _receivingUser.uid,
             @"expiration": @(seconds),
             @"status": @(_status)};
}

@end
