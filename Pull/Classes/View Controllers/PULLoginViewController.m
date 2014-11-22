//
//  PULLoginViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULLoginViewController.h"

#import "PULAccount.h"

#import "PULConstants.h"

#import "PULPullListViewController.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>

@interface PULLoginViewController ()

@property (nonatomic, strong) Firebase *fireRef;

@end

@implementation PULLoginViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
    }
    return self;
}

#pragma mark - Actions
- (IBAction)ibPresentFacebookLogin:(id)sender;
{
    PULLog(@"presenting facebook login");
    [FBSession openActiveSessionWithReadPermissions:@[@"email", @"public_profile", @"user_friends"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      PULLog(@"opened active session");
                                      if (error)
                                      {
                                          [PULError handleError:error];
                                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                                                               message:[NSString stringWithFormat:@"There was a problem authenticating: (%li) %@", error.code, error.localizedDescription]
                                                                                              delegate:nil
                                                                                     cancelButtonTitle:@"Ok"
                                                                                     otherButtonTitles: nil];
                                          [errorAlert show];
                                      }
                                      else
                                      {
                                          NSString *accessToken = session.accessTokenData.accessToken;
                                          [[PULAccount currentUser] loginWithFacebookToken:accessToken completion:^(PULAccount *account, NSError *error) {
                                              UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullListViewController class])];
                                              
                                              [self presentViewController:vc animated:YES completion:^{
                                                  ;
                                              }];
                                          }];
                                      }
                                  }];
}

@end
