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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BOOL redeemed = [[NSUserDefaults standardUserDefaults] boolForKey:@"RedeemedInvite"];
    _inviteWallScrollView.hidden = redeemed;
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

// TODO: this isn't called if the user pastes the code in
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isEqual:_inviteWallCodeTextField])
    {
        if (textField.text.length >= 1 && string.length > 0)
        {
            _inviteWallCodeRedeemButton.enabled = YES;
        }
        else if (textField.text.length == 1 && string.length == 0)
        {
            _inviteWallCodeRedeemButton.enabled = NO;
        }
    }
    else if ([textField isEqual:_inviteWallEmailTextField])
    {
        _inviteWallEmailSubmitButton.enabled = [self _validateEmail:textField.text];
    }
        
    return YES;
}

- (BOOL)_validateEmail:(NSString*)email;
{
    NSString *pattern = @"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    if ([regex numberOfMatchesInString:email options:0 range:NSMakeRange(0, email.length)])
    {
        return YES;
    }
    return NO;
}

#pragma mark - Actions
- (IBAction)ibInviteTapHere:(id)sender
{
    [_inviteWallScrollView scrollRectToVisible:_inviteWallEmailView.frame animated:YES];
}

- (IBAction)ibInviteBack:(id)sender
{
    [_inviteWallScrollView scrollRectToVisible:_inviteWallCodeView.frame animated:YES];
}

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
                // TODO: slide invite wall to the left 
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RedeemedInvite"];
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

- (IBAction)ibInviteRequestEmail:(id)sender;
{
    PFObject *obj = [PFObject objectWithClassName:@"InviteRequest"];
    obj[@"email"] = _inviteWallEmailTextField.text;
    obj[@"isInvited"] = @(NO);
    
    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:NO];
    [acl setPublicWriteAccess:NO];
    obj.ACL = acl;
    
    [obj saveInBackground];
    
    [_inviteWallScrollView scrollRectToVisible:_inviteWallThanksView.frame animated:YES];
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
