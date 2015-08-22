//
//  PULProfileViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULMenuViewController.h"

#import "PULUserImageView.h"

#import "PULInviteViewController.h"

#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>

@interface PULMenuViewController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet PULUserImageView *userImageView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) UIActivityViewController *shareActivityViewController;
@property (strong, nonatomic) IBOutlet UILabel *inviteLabel;
@property (strong, nonatomic) IBOutlet UIButton *inviteButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *inviteButtonCenter;
@property (strong, nonatomic) IBOutlet UIButton *inviteButtonRight;

@end

@implementation PULMenuViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _populateUserInfo];
    
    [self.view insertSubview:[UIView pullVisualEffectViewWithFrame:self.view.bounds] atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // determine how many invite buttons should be shown
   if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasSentInviteKey"])
   {
       NSInteger remaining = [[NSUserDefaults standardUserDefaults] integerForKey:@"InvitesRemainingKey"];
       if (remaining < 3)
       {
           _inviteButtonRight.hidden = YES;
       }
       if (remaining < 2)
       {
           _inviteButtonCenter.hidden = YES;
       }
       if (remaining < 1)
       {
           _inviteButtonLeft.hidden = YES;
       }
       
       if (remaining != 0)
       {
           NSString *friendStr = @"friends";
           if (remaining == 1)
           {
               friendStr = @"friend";
           }
           _inviteLabel.text = [NSString stringWithFormat:@"You can invite %zd %@ to pull", remaining, friendStr];
       }
       else
       {
           _inviteLabel.text = @"You have sent all of your invites";
       }
   }
}

- (void)_populateUserInfo {
    [_userImageView setImage:[PULAccount currentUser].image forObject:[PULAccount currentUser].image];
    _backgroundImageView.image = [PULAccount currentUser].image;
    _nameLabel.text = [PULAccount currentUser].fullName;
    
    if (!_backgroundImageView.image)
    {
        [[NSNotificationCenter defaultCenter] addObserverForName:PULImageUpdatedNotification
                                                          object:[PULAccount currentUser]
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          _backgroundImageView.image = [[note object] image];
                                                      }];
    }
}

#pragma mark - actions
- (IBAction)ibContact:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Report an Issue", @"Make a Suggestion", @"Partner with Us", nil];
    
    [sheet showInView:self.view];
    
}

- (IBAction)ibShare:(id)sender
{
    NSString *shareMessage = [NSString stringWithFormat:@"Pull me on pull! %@", kPULAppDownloadURL];
    _shareActivityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage] applicationActivities:nil];
    [self presentViewController:_shareActivityViewController animated:YES completion:nil];
}

- (IBAction)ibRate:(id)sender
{
    NSURL *url = [NSURL URLWithString:kPULAppDownloadURL];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)ibInvite:(id)sender
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULInviteViewController class])];
    
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - action sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {
            [self _showReportMail];
            break;
        }
        case 1:
        {
            [self _showSuggestionMail];
            break;
        }
        case 2:
        {
            [self _showPartnerMail];
            break;
        }
        case 3:
        {
            // cancel
            break;
        }
        default:
            break;
    }
}

#pragma mark - mail delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - private
- (void)_showReportMail
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    // get some device info
    UIDevice *dev = [UIDevice currentDevice];
    NSString *model = machineName();
    NSString *version = dev.systemVersion;
    
    NSString *body = [NSString stringWithFormat:@"\n\n\n\n-----------------\nDevice Information\n \
                      OS version: %@\n\
                      Model: %@\n\
                      Version: %@\n\
                      Build: %@\n\
                      -----------------", version, model, appVersion, buildNumber];
    
    [self _showMailWithSubject:@"Report Issue" to:kPULAppReportIssueEmail body:body];
}

- (void)_showSuggestionMail
{
    [self _showMailWithSubject:@"Make Suggestion" to:kPULAppSuggestionEmail body:nil];
}

- (void)_showPartnerMail
{
    [self _showMailWithSubject:@"Become Partner" to:kPULAppPartnerEmail body:nil];
}

- (void)_showMailWithSubject:(NSString*)subject to:(NSString*)to body:(NSString*)body
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        [mail setSubject:subject];
        [mail setToRecipients:@[to]];
        
        if (body)
        {
            [mail setMessageBody:body isHTML:NO];
        }
        
        mail.mailComposeDelegate = self;
        
        [self presentViewController:mail animated:YES completion:nil];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Woops"
                                    message:@"Email needs to be set up on your phone to do this"
                                   delegate:self
                          cancelButtonTitle:@"ok" otherButtonTitles: nil]show];
    }
}

NSString* machineName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}


@end
