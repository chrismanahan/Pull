
//  FriendingTests.m
//  Pull
//
//  Created by Chris M on 9/27/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface FriendingTests : XCTestCase

@end

@implementation FriendingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)delayTestSeconds:(CGFloat)seconds
{
    __block BOOL waitingForBlock = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        waitingForBlock = NO;
    });
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)testGetFriends
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[PULParseMiddleMan sharedInstance] getFriendsInBackground:^(NSArray<PULUser *> * _Nullable users, NSError * _Nullable error) {
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

- (void)testBlockFriend
{
    PULParseMiddleMan *parse = [PULParseMiddleMan sharedInstance];
    [parse getFriendsInBackground:^(NSArray<PULUser *> * _Nullable users, NSError * _Nullable error) {
        
        PULUser *user = users[0];
        [parse blockUser:user];
    }];
    
    [self delayTestSeconds:1];
}

- (void)testUnblockFriend
{
    PULParseMiddleMan *parse = [PULParseMiddleMan sharedInstance];
    [parse getBlockedUsersInBackground:^(NSArray<PULUser *> * _Nullable users, NSError * _Nullable error) {
        
        PULUser *user = users[0];
        [parse unblockUser:user];
    }];
    
    [self delayTestSeconds:1];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
