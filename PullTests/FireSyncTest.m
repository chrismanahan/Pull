//
//  FireSyncTest.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "PULAccount.h"

@interface FireSyncTest : XCTestCase

@property (nonatomic, strong) XCTestExpectation *ex;

@end

@implementation FireSyncTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadAccount
{
    self.ex = [self expectationWithDescription:@"acct"];
    PULAccount *acct = [[PULAccount alloc] initWithUid:@"facebook:10152578194302952"];
    
    [acct addObserver:self forKeyPath:@"allFriends" options:0 context:NULL];
    [acct addObserver:self forKeyPath:@"pulls" options:0 context:NULL];
    
    [self waitForExpectationsWithTimeout:1000 handler:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"observed change: %@ - %@ - %@", keyPath, object, change);
    
    NSLog(@"\tval: %@", [object performSelector:NSSelectorFromString(keyPath)]);
}

@end
