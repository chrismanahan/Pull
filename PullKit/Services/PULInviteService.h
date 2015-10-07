//
//  PULInviteService.h
//  Pull
//
//  Created by Chris M on 5/4/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^PULInviteCompleteBlock)(BOOL success);

@interface PULInviteService : NSObject

@property (nonatomic, assign, readonly) BOOL canSendInvites;
@property (nonatomic, assign, readonly) NSInteger invitesRemaining;

+ (instancetype)sharedInstance;

- (void)initialize;

- (void)sendInviteToEmail:(NSString*)email completion:(PULInviteCompleteBlock)completion;

- (void)redeemInviteCode:(NSString*)code completion:(PULInviteCompleteBlock)completion;

@end

NS_ASSUME_NONNULL_END