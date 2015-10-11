//
//  PULLoginViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULLoginViewController.h"
#import "PULRequestLocationViewController.h"
#import "PULPullListViewController.h"

#import "PULSlideLeftSegue.h"

#import "PULInviteService.h"

#import "PULParseMiddleMan.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface PULLoginViewController () <UIScrollViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

/** invite wall **/
@property (strong, nonatomic) IBOutlet UIScrollView *inviteWallScrollView;

@property (strong, nonatomic) IBOutlet UIView *inviteWallCodeView;
@property (strong, nonatomic) IBOutlet UITextField *inviteWallCodeTextField;
@property (strong, nonatomic) IBOutlet UIButton *inviteWallCodeRedeemButton;
@property (strong, nonatomic) IBOutlet UILabel *inviteWallCodeEnterTextLabel;

@property (strong, nonatomic) IBOutlet UIView *inviteWallEmailView;
@property (strong, nonatomic) IBOutlet UITextField *inviteWallEmailTextField;
@property (strong, nonatomic) IBOutlet UIButton *inviteWallEmailSubmitButton;

@property (strong, nonatomic) IBOutlet UIView *inviteWallThanksView;

@end

@implementation PULLoginViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      NSDictionary* userInfo = [note userInfo];
                                                      
                                                      // get the size of the keyboard
                                                      CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
                                                      
                                                      CGRect viewFrame = _inviteWallScrollView.frame;
                                                      viewFrame.size.height -= (keyboardSize.height);
                                                      
                                                      [UIView beginAnimations:nil context:NULL];
                                                      [UIView setAnimationBeginsFromCurrentState:YES];
                                                      [self.inviteWallScrollView setFrame:viewFrame];
                                                      [UIView commitAnimations];
//                                                      keyboardIsShown = YES;
                                                  }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isEqual:_inviteWallCodeTextField])
    {
        if (textField.text.length > 0)
        {
            
        }
    }
            
    return YES;
}

#pragma mark - Actions
- (IBAction)ibRedeemInvite:(id)sender
{
    [_inviteWallCodeTextField resignFirstResponder];
    
    NSString *code = _inviteWallCodeTextField.text;
    
    if (code && code.length > 0)
    {
        PULInviteService *inviteService = [PULInviteService sharedInstance];
        [inviteService redeemInviteCode:code completion:^(BOOL success) {
            if (success)
            {
                _inviteWallScrollView.hidden = YES;
            }
            else
            {
                [[[UIAlertView alloc] initWithTitle:@"Error Redeeming Code"
                                            message:@"Your invite code could not be redeemed. If this contintues to be a problem, contact support@getpulled.com with your invite code"
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles: nil] show];
            }
        }];
    }
}

- (IBAction)ibPresentFacebookLogin:(id)sender;
{

    [[PULParseMiddleMan sharedInstance] loginWithFacebook:^(BOOL success, NSError * _Nullable error) {
        if (success)
        {
            // check if we already have location/notifcation permissions
            BOOL grantedPermissions = [[NSUserDefaults standardUserDefaults] boolForKey:@"DidGrantPermissions"];
            
            if (!grantedPermissions)
            {
                // show permission request vc
                UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULRequestLocationViewController class])];
                
                PULSlideLeftSegue *seg = [PULSlideLeftSegue segueWithIdentifier:@"RequestLocationSeg"
                                                                         source:self
                                                                    destination:vc
                                                                 performHandler:^{
                                                                     ;
                                                                 }];
                [seg perform];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DidGrantPermissions"];
            }
            else
            {
                UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullListViewController class])];
                
                [self presentViewController:vc animated:YES completion:^{
                    ;
                }];
            }
        }
        else
        {
            PULLog(@"failed to initialize: %@", error);
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                                 message:[NSString stringWithFormat:@"There was a problem authenticating: (%li) %@", (long)error.code, error.localizedDescription]
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles: nil];
            [errorAlert show];

        }
    }];
}

#pragma mark - scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / CGRectGetWidth(self.view.frame);
    _pageControl.currentPage = page;
}

@end
