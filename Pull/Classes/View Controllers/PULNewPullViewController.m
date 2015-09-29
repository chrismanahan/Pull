//
//  PULNewPullViewController.m
//  Pull
//
//  Created by Chris M on 4/19/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULNewPullViewController.h"

#import "PULReverseModal.h"

#import "NZCircularImageView.h"

#import "PULPullListViewController.h"

@interface PULNewPullViewController () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet NZCircularImageView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) IBOutlet UIButton *select1HourButton;
@property (strong, nonatomic) IBOutlet UIButton *select12HourButton;
@property (strong, nonatomic) IBOutlet UIButton *select24HourButton;
@property (strong, nonatomic) IBOutlet UIButton *selectAlwaysButton;

@property (strong, nonatomic) IBOutlet UILabel *disclaimerLabel;
@property (strong, nonatomic) IBOutlet UITextView *captionTextView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendInviteBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrollViewTopConstraint;
@property (strong, nonatomic) IBOutlet UIButton *sendInviteButton;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic) NSTimeInterval requestedDuration;

@end

@implementation PULNewPullViewController

#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _captionTextView.layer.cornerRadius = 5.0;
    _disclaimerLabel.text = [NSString stringWithFormat:@"%@ will only see you when you are within %zd ft", _user.firstName, kPULDistanceNearbyFeet];
    
    _nameLabel.text = _user.fullName;
    [_userImageView setImageWithResizeURL:_user.imageUrlString];
}

- (void)viewDidLoad
{
    // setting the tags for each button as the duration associated
    _selectAlwaysButton.tag = kPullDurationAlways;
    _select1HourButton.tag = kPullDurationHour;
    _select12HourButton.tag = kPullDurationHalfDay;
    _select24HourButton.tag = kPullDurationDay;
    
    _userImageView.borderWidth = @(5);
    _userImageView.borderColor = [UIColor whiteColor];
    _sendInviteButton.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      CGRect endFrame = [[note userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
                                                      
//                                                      if (_sendInviteBottomConstraint.constant <= 0 || _sendInviteBottomConstraint.constant < endFrame.size.height)
//                                                      {
                                                          _sendInviteBottomConstraint.constant = endFrame.size.height;
                                                      if (_scrollViewTopConstraint.constant == 0)
                                                      {
                                                          _scrollViewTopConstraint.constant = -(CGRectGetMinY(_scrollView.frame) - CGRectGetMinY(_userImageView.frame));
                                                      }
                                                      
                                                          if (_sendInviteButton.hidden)
                                                          {
                                                              _sendInviteBottomConstraint.constant -= CGRectGetHeight(_sendInviteButton.frame);
                                                          }
                                                      
                                                          [UIView animateWithDuration:0.2 animations:^{
                                                              [self.view layoutIfNeeded];
                                                              
                                                              CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
                                                              [_scrollView setContentOffset:bottomOffset];
                                                          } completion:^(BOOL finished) {
                                                              
                                                          }];
//                                                      }
                                                      
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      if (_sendInviteButton.hidden)
                                                      {
                                                          _sendInviteBottomConstraint.constant = -CGRectGetHeight(_sendInviteButton.frame);
                                                      }
                                                      else
                                                      {
                                                          _sendInviteBottomConstraint.constant = 0;
                                                      }
                                                      
                                                      _scrollViewTopConstraint.constant = 0;
                                                      
                                                      [UIView animateWithDuration:0.2 animations:^{
                                                          [self.view layoutIfNeeded];
                                                      }];
                                                  }];
}
#pragma mark - Actions
- (IBAction)ibSelectButton:(id)sender
{
    [self _showSendButton];
    [self _selectButton:sender];
    
    _requestedDuration = [sender tag];
}

- (IBAction)ibSendInvite:(id)sender
{
    // send pull
    // TODO: SEND PULL TO SELECTED USER
//    [[PULUser currentUser] sendPullToUser:_user duration:_requestedDuration caption:_captionTextView.text];
    
    // dismiss vc
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Private
- (void)_showSendButton
{
    if (_sendInviteBottomConstraint.constant != 0.0)
    {
        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
        
        _sendInviteButton.hidden = NO;
        
        _sendInviteBottomConstraint.constant = 0.0;
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)_deselectAllButtons
{
    _select12HourButton.backgroundColor = [UIColor whiteColor];
    _select1HourButton.backgroundColor = [UIColor whiteColor];
    _select24HourButton.backgroundColor = [UIColor whiteColor];
    _selectAlwaysButton.backgroundColor = [UIColor whiteColor];
    
    UIColor *purple = PUL_Purple;
    [_select12HourButton setTitleColor:purple forState:UIControlStateNormal];
    [_select1HourButton setTitleColor:purple forState:UIControlStateNormal];
    [_select24HourButton setTitleColor:purple forState:UIControlStateNormal];
    [_selectAlwaysButton setTitleColor:purple forState:UIControlStateNormal];
}

- (void)_selectButton:(UIButton*)button
{
    [self _deselectAllButtons];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = PUL_DarkPurple;
}

@end
