//
//  FireSyncTest.m
//  Pull
//
//  Created by Chris Manahan on 3/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XCTestCase+Auth.h"

@interface PullingTests : XCTestCase

@property (nonatomic, strong) NSMutableArray *observers;

@end

@implementation PullingTests

- (void)setUp
{
    [super setUp];
    
    _observers = [[NSMutableArray alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAcceptPull
{
    XCTestExpectation *ex = [self expectationWithDescription:@"pulls"];
    
    [self login:^{  // begin login
        PULAccount *acct = [PULAccount currentUser];
        
        THObserver *obs0 = [THObserver observerForObject:acct keyPath:@"pulls" oldAndNewBlock:^(id oldValue, id newValue) {
            // begin obs1
            if ([newValue count])
            {   // begin if
                for (PULPull *pull in newValue)
                {   // begin for
                    THObserver *obs = [THObserver observerForObject:pull
                                                            keyPath:@"loaded"
                                                     oldAndNewBlock:^(id oldValue, id newValue) {
                                                         if (![pull initiatedBy:acct])
                                                         {  // begin if
                                                             [acct acceptPull:pull];
                                                             
                                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                                 [ex fulfill];
                                                             });
                                                         }  // end if
                                                     }];
                    
                    [_observers addObject:obs];
                }   // end for
            }   // end if
        }]; // end obs0
        [_observers addObject:obs0];
    }]; // end login
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCancelAllPulls
{
    XCTestExpectation *ex = [self expectationWithDescription:@"pulls"];
    
    [self login:^{
        // begin login
        static BOOL obsd = NO;
        PULAccount *acct = [PULAccount currentUser];
        THObserver *obs0 = [THObserver observerForObject:acct keyPath:@"pulls" oldAndNewBlock:^(id oldValue, id newValue) {
            // begin pulls observer
            if (!obsd)
            {
                obsd = YES;
                
                
                for (PULPull *pull in acct.pulls)
                {
                    [acct cancelPull:pull];
                }
                
                // TODO: need to figure out a clean way to be notified when the pull's other user (currently nil here) has a change in it's pulls
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [ex fulfill];
                });
            }
        }]; // end friends observer
        
        [_observers addObject:obs0];
    }]; // end login
    
    [self waitForExpectationsWithTimeout:50 handler:nil];
}

- (void)testSendPull
{
    XCTestExpectation *ex = [self expectationWithDescription:@"acct"];
    
    [self login:^{
        // begin login
        THObserver *obs0 = [THObserver observerForObject:[PULAccount currentUser] keyPath:@"friends" oldAndNewBlock:^(id oldValue, id newValue) {
            // begin friends observer
            PULLog(@"loaded all friends");
            
            PULAccount *acct = [PULAccount currentUser];
            
            PULUser *friend;
            for (PULUser *user in acct.friends)
            {
                THObserver *obs1 = [THObserver observerForObject:user keyPath:@"firstName" oldAndNewBlock:^(id oldValue, id newValue) {
                    // begin first name observer
                    if ([newValue isEqualToString:@"Chris"])
                    {
                        [acct sendPullToUser:user duration:kPullDurationDay];
                        [ex fulfill];
                    }
                }]; // end first name observer
                
                [_observers addObject:obs1];
            }
           
            
        }]; // end friends observer
        
        [_observers addObject:obs0];
    }]; // end login
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
