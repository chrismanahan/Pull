//
//  PULProfileViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULMenuViewController.h"

#import "PULInviteViewController.h"

#import "NZCircularImageView.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

#import "PULUser.h"

#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>
#import "PULInviteService.h"

@interface PULMenuViewController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet NZCircularImageView *userImageView;

@property (nonatomic, strong) UIActivityViewController *shareActivityViewController;

@property (nonatomic, strong) IBOutlet UIButton *inviteButton1;
@property (nonatomic, strong) IBOutlet UIButton *inviteButton2;
@property (nonatomic, strong) IBOutlet UIButton *inviteButton3;
@property (nonatomic, strong) IBOutlet UILabel *inviteLabel;

@end

@implementation PULMenuViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // configure invite UI
    PULInviteService *invites = [PULInviteService sharedInstance];
    _inviteButton3.hidden = invites.invitesRemaining < 3;
    _inviteButton1.hidden = invites.invitesRemaining < 2;
    _inviteButton2.hidden = invites.invitesRemaining < 1;
    _inviteLabel.hidden = !invites.canSendInvites;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _populateUserInfo];
}

- (void)_populateUserInfo {
    NSString *imageUrl = [PULUser currentUser].imageUrlString;
    [_userImageView setImageWithResizeURL:imageUrl];
    // TODO: SET BACKGROUND IMAGE VIEW DYNAMICALLY IN MENU VIEW
    [_backgroundImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    _nameLabel.text = [PULUser currentUser].fullName;
    
}

#pragma mark - actions
- (IBAction)ibContact:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Report an Issue", @"Make a Suggestion", @"Partner with Us", @"Invite a Friend", nil];
    
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
            [self _showInviteMail];
            break;
        }
        case 4:
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

- (void)_showInviteMail
{
    [self _showMailWithSubject:@"Invite Friend" to:kPULAppPartnerEmail body:nil];
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
