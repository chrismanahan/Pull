//
//  PULSettingsViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULSettingsViewController.h"
#import "PULLoginViewController.h"

#import "PULAccount.h"

#import "PULLoadingIndicator.h"

#import "PULSlideUnwindSegue.h"
#import "PULReverseModal.h"

@interface PULSettingsViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UISwitch *notifInviteSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *notifAcceptSwitch;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, assign) BOOL dirty;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation PULSettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PULUserSettings *settings = [PULAccount currentUser].settings;
    [_notifAcceptSwitch setOn:settings.notifyAccept];
    [_notifInviteSwitch setOn:settings.notifyInvite];
    
}


- (void)viewDidLoad
{
    // set version label
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
   
    _versionLabel.text = [NSString stringWithFormat:@"Version %@ (%@)", appVersion, buildNumber];
}

//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    CGFloat scrollViewHeight = 0.0f;
//    for (UIView* view in _scrollView.subviews)
//    {
//        CGFloat maxY = CGRectGetMinY(view.frame) + CGRectGetHeight(view.frame);
//        if (maxY > scrollViewHeight)
//        {
//            scrollViewHeight = maxY;
//        }
//    }
//    
//    [_scrollView setContentSize:(CGSizeMake(CGRectGetWidth(_scrollView.frame), scrollViewHeight))];
//}

#pragma mark - navigation
- (IBAction)unwindFromViewController:(UIStoryboardSegue *)sender {
}

#pragma mark - actions
- (IBAction)ibInvite:(id)sender
{
    _dirty = YES;
    
     [PULAccount currentUser].settings.notifyInvite = _notifInviteSwitch.isOn;
}

- (IBAction)ibAccept:(id)sender
{
    _dirty = YES;
    
    [PULAccount currentUser].settings.notifyAccept = _notifAcceptSwitch.isOn;
}

- (IBAction)ibDone:(id)sender
{
    if (_dirty)
    {
        [[PULAccount currentUser] saveKeys:@"settings"];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)ibLogout:(id)sender
{
    [[PULAccount currentUser] logout];
 
    UIViewController *login = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULLoginViewController class])];
    
    PULReverseModal *seg = [PULReverseModal segueWithIdentifier:@"LoginSeg"
                                                         source:self
                                                    destination:login
                                                 performHandler:^{
                                                     ;
                                                 }];
    
    [seg perform];
}

- (IBAction)ibDisableAccount:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disable Account"
                                message:@"Are you sure you want to disable your account? Your existing pulls will be stopped and your friends won't see you anymore. Your account will be enabled again next time you log in"
                               delegate:self
                      cancelButtonTitle:@"No!"
                                          otherButtonTitles:@"I'm sure", nil];
    alert.tag = 400;
    [alert show];
}

#pragma mark - alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        PULLoadingIndicator *ai = [PULLoadingIndicator indicatorOnView:self.view];
        ai.title = @"Disabling";
        [ai show];
        // disable account
//        [[PULAccount currentUser].pullManager unpullEveryone];
        [PULAccount currentUser].settings.disabled = YES;
        [[PULAccount currentUser] saveAll];
        [ai hide];
        [self ibLogout:nil];

    }
}

@end
