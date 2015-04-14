//
//  AccountTests.m
//  Pull
//
//  Created by Development on 4/11/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "XCTestCase+Auth.h"

@interface AccountTests : XCTestCase

@property (nonatomic, strong) NSMutableArray *observers;

@end

@implementation AccountTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _observers = [[NSMutableArray alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadAccount
{
    XCTestExpectation *ex = [self expectationWithDescription:@"acct"];
    
    [self login:^{
        [[PULAccount currentUser] addNewFriendsFromFacebook];
        THObserver *obs = [THObserver observerForObject:[PULAccount currentUser] keyPath:@"friends" oldAndNewBlock:^(id oldValue, id newValue) {
            PULLog(@"loaded all friends");
//            for (PULUser *user in [PULAccount currentUser].friends)
//            {
//                THObserver *obs1 = [THObserver observerForObject:user keyPath:@"loaded" oldAndNewBlock:^(id oldValue, id newValue) {
//                    PULLog(@"loaded");
//                }]; // end first name observer
//                
//                [_observers addObject:obs1];
//            }
            [ex fulfill];
        }];
        [_observers addObject:obs];
    }];
    
    [self waitForExpectationsWithTimeout:1000 handler:nil];
    
}

- (void)testUnblockUser
{
    XCTestExpectation *ex = [self expectationWithDescription:@"acct"];
    
    [self login:^{
        // begin login
        THObserver *obs0 = [THObserver observerForObject:[PULAccount currentUser] keyPath:@"blocked" oldAndNewBlock:^(id oldValue, id newValue) {
            // begin friends observer
            PULLog(@"loaded all blocked users");
            
            PULAccount *acct = [PULAccount currentUser];
            
            for (PULUser *user in acct.blocked)
            {
                THObserver *obs1 = [THObserver observerForObject:user keyPath:@"firstName" oldAndNewBlock:^(id oldValue, id newValue) {
                    // begin first name observer
                    if ([newValue isEqualToString:@"Chris"])
                    {
                        [acct unblockUser:user];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [ex fulfill];
                        });
                    }
                }]; // end first name observer
                
                [_observers addObject:obs1];
            }
            
            
        }]; // end friends observer
        
        [_observers addObject:obs0];
    }]; // end login
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testBlockUser
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
                        [acct blockUser:user];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [ex fulfill];
                        });
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
