//
//  PULInviteService.h
//  Pull
//
//  Created by Chris M on 5/4/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^PULInviteCompleteBlock)(BOOL success, NSInteger remaining);

@interface PULInviteService : NSObject

- (void)sendInviteToEmail:(NSString*)email completion:(PULInviteCompleteBlock)completion;

@end
