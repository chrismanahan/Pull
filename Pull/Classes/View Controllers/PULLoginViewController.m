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

#import "PULLoadingIndicator.h"
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

@property (strong, nonatomic) IBOutlet UIView *inviteCodeTextContainer;
@property (strong, nonatomic) IBOutlet UIView *inviteEmailTextContainer;

@property (strong, nonatomic) IBOutlet UIView *inviteWallEmailView;
@property (strong, nonatomic) IBOutlet UITextField *inviteWallEmailTextField;
@property (strong, nonatomic) IBOutlet UIButton *inviteWallEmailSubmitButton;
@property (strong, nonatomic) IBOutlet UILabel *inviteWallEmailTopLabel;

@property (nonatomic, strong) UIView *selectedTextContainer;
@property (nonatomic, assign) CGRect originalContainerFrame;

@property (strong, nonatomic) IBOutlet UIView *inviteWallThanksView;

@property (nonatomic, strong) PULLoadingIndicator *ai;

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
    static BOOL keyboardShowing = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      NSDictionary* userInfo = [note userInfo];
                                                      
                                                      if (!keyboardShowing)
                                                      {
                                                          // get the size of the keyboard
                                                          CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
                                                          
                                                          _originalContainerFrame = _selectedTextContainer.frame;
                                                          
                                                          CGFloat y = CGRectGetMinY(keyboardRect) - CGRectGetHeight(keyboardRect) - CGRectGetHeight(_selectedTextContainer.frame)- 8;
                                                          CGRect textFrame = CGRectMake(8, y, CGRectGetWidth(_selectedTextContainer.frame), CGRectGetHeight(_selectedTextContainer.frame));
                                                          
                                                          [UIView animateWithDuration:0.3 animations:^{
                                                              _selectedTextContainer.frame = textFrame;
                                                              
                                                              if ([_selectedTextContainer isEqual:_inviteCodeTextContainer])
                                                              {
                                                                  _inviteWallCodeEnterTextLabel.alpha = 0.6;
                                                              }
                                                              else
                                                              {
                                                                  _inviteWallEmailTopLabel.alpha = 0.6;
                                                              }
                                                              
                                                              [self.view setNeedsUpdateConstraints];
                                                          }];
                                                          
                                                          keyboardShowing = YES;
                                                      }
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [UIView animateWithDuration:0.3 animations:^{
                                                          if (keyboardShowing)
                                                          {
                                                              _selectedTextContainer.frame = _originalContainerFrame;
                                                              
                                                              if ([_selectedTextContainer isEqual:_inviteCodeTextContainer])
                                                              {
                                                                  _inviteWallCodeEnterTextLabel.alpha = 1;
                                                              }
                                                              else
                                                              {
                                                                  _inviteWallEmailTopLabel.alpha = 1;
                                                              }
                                                              
                                                              keyboardShowing = NO;
                                                          }
                                                      }];
                                                      
                                                  }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField isEqual:_inviteWallCodeTextField])
    {
        if ((textField.text.length >= 1 && string.length > 0) || (textField.text.length == 0 && string.length > 2))
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:_inviteWallCodeTextField])
    {
        _selectedTextContainer = _inviteCodeTextContainer;
    }
    else
    {
        _selectedTextContainer = _inviteEmailTextContainer;
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
    if (_inviteWallEmailTextField.isFirstResponder)
    {
        [_inviteWallEmailTextField resignFirstResponder];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_inviteWallScrollView scrollRectToVisible:_inviteWallCodeView.frame animated:YES];
        });
    }
    else
    {
        [_inviteWallScrollView scrollRectToVisible:_inviteWallCodeView.frame animated:YES];
    }
}

- (IBAction)ibRedeemInvite:(id)sender
{
    [_inviteWallCodeTextField resignFirstResponder];
    
    NSString *code = _inviteWallCodeTextField.text;
    
    if (code && code.length > 0)
    {
        _ai = [PULLoadingIndicator indicatorOnView:self.view];
        [_ai show];
        PULInviteService *inviteService = [PULInviteService sharedInstance];
        [inviteService redeemInviteCode:code completion:^(BOOL success) {
            [_ai hide];
            if (success)
            {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RedeemedInvite"];
                
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     CGRect frame = _inviteWallScrollView.frame;
                                     frame.origin.x -= CGRectGetWidth(frame);
                                     _inviteWallScrollView.frame = frame;
                                 } completion:^(BOOL finished) {
                                     _inviteWallScrollView.hidden = YES;
                                 }];
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
    _ai = [PULLoadingIndicator indicatorOnView:self.view];
    [_ai show];
    
    [[PULParseMiddleMan sharedInstance] loginWithFacebook:^(BOOL success, NSError * _Nullable error) {
        [_ai hide];
        
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
