//
//  FriendTest.m
//  Pull
//
//  Created by Chris M on 9/27/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <PullKit/PullKit.h>

@interface FriendTest : XCTestCase

@end

@implementation FriendTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGetFriends
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[PULParseMiddleMan sharedInstance] getFriendsInBackground:^(NSArray<PULUser *> * _Nullable users, NSError * _Nullable error) {
        
        
        
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
