//
//  XCTestCase+Auth.m
//  Pull
//
//  Created by Development on 4/11/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "XCTestCase+Auth.h"

@implementation XCTestCase (Auth)

- (void)login:(void(^)())completion
{
    [FBSession openActiveSessionWithReadPermissions:@[@"email", @"public_profile", @"user_friends"]
                                       allowLoginUI:NO
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      if (!error)
                                      {
                                          PULLog(@"opened session");
                                          [PULAccount loginWithFacebookToken:session.accessTokenData.accessToken completion:^(PULAccount *account, NSError *error) {
                                              
                                              completion();
                                          }];
                                      }
                                      else
                                      {
                                          PULLog(@"%@", error.localizedDescription);
                                      }
                                  }];
    
}

@end
