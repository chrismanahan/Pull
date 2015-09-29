//
//  PULUserSettings.h
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+Subclass.h"

NS_ASSUME_NONNULL_BEGIN

@interface PULUserSettings : PFObject <PFSubclassing>

/*****************************
 Properties
 *****************************/

@property (nonatomic, assign) BOOL notifyInvite;
@property (nonatomic, assign) BOOL notifyAccept;
@property (nonatomic, assign) BOOL notifyNearby;
@property (nonatomic, assign) BOOL notifyGone;

/*****************************
 Class Methods
 *****************************/

+ (instancetype)defaultSettings;

+ (NSString*)parseClassName;

@end

NS_ASSUME_NONNULL_END
