//
//  PULUserSettings.h
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FireObject.h"

@interface PULUserSettings : NSObject <Fireable>

@property (nonatomic, assign) BOOL notifyInvite;
@property (nonatomic, assign) BOOL notifyAccept;
@property (nonatomic, assign) BOOL notifyDeparture;
@property (nonatomic, assign) BOOL notifyArrival;

@property (nonatomic, assign, getter=isDisabled) BOOL disabled;

@property (nonatomic, assign) BOOL resolveAddress;

- (instancetype)initFromFirebase:(NSDictionary*)dict;

+ (instancetype)defaultSettings;

@end
