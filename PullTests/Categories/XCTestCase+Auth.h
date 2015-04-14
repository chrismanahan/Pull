//
//  XCTestCase+Auth.h
//  Pull
//
//  Created by Development on 4/11/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "THObserversAndBinders.h"

#import "PULAccount.h"
#import "FireSync.h"

#import <FacebookSDK/FacebookSDK.h>

@interface XCTestCase (Auth)

- (void)login:(void(^)())completion;

@end
