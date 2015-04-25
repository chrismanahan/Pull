//
//  PULInviteViewController.m
//  Pull
//
//  Created by Chris M on 4/24/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULInviteViewController.h"

@interface PULInviteViewController () <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrollViewTopConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *inviteButtonBottomConstraint;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UIButton *inviteButton;
@property (strong, nonatomic) IBOutlet UIImageView *ticketImageView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic) CGRect keyboardFrame;

@property (nonatomic) BOOL buttonIsShowing;

@end

@implementation PULInviteViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      CGRect endFrame = [[note userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
                                                      _keyboardFrame = endFrame;
                                                      
                                                      _inviteButtonBottomConstraint.constant = endFrame.size.height;
                                                      if (!_buttonIsShowing)
                                                      {
                                                          _inviteButtonBottomConstraint.constant -= CGRectGetHeight(_inviteButton.frame);
                                                      }
                                                      
                                                      
                                                      
                                                      _scrollViewTopConstraint.constant = -CGRectGetHeight(_ticketImageView.frame);
                                                      PULLog(@"top: %.2f", _scrollViewTopConstraint.constant);
           
                                                      [UIView animateWithDuration:0.2 animations:^{
                                                          [self.view layoutIfNeeded];
                                                      }];
                                                          
                                                      
                                                  }];

}

#pragma mark - Actions
- (IBAction)ibInvite:(id)sender
{
    // TODO: implement invitations
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)ibBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // pretty loose email regex
    NSString *pattern = @".*@.*\\.";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSUInteger matches = [regex numberOfMatchesInString:textField.text options:0 range:NSMakeRange(0, textField.text.length)];
    if (matches > 0 && _inviteButtonBottomConstraint.constant != 0)
    {
        _inviteButtonBottomConstraint.constant = _keyboardFrame.size.height;
        _buttonIsShowing = YES;
        [UIView animateWithDuration:0.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    else if (matches == 0 && _inviteButtonBottomConstraint.constant == _keyboardFrame.size.height)
    {
        _inviteButtonBottomConstraint.constant = _keyboardFrame.size.height - CGRectGetHeight(_inviteButton.frame);
        _buttonIsShowing = NO;
        [UIView animateWithDuration:0.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    
    return YES;
}

@end
