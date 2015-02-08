//
//  PULSettingsViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULSettingsViewController.h"

#import "PULAccount.h"

@interface PULSettingsViewController ()

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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat scrollViewHeight = 0.0f;
    for (UIView* view in _scrollView.subviews)
    {
        CGFloat maxY = CGRectGetMinY(view.frame) + CGRectGetHeight(view.frame);
        if (maxY > scrollViewHeight)
        {
            scrollViewHeight = maxY;
        }
    }
    
    [_scrollView setContentSize:(CGSizeMake(CGRectGetWidth(_scrollView.frame), scrollViewHeight))];
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
        [[PULAccount currentUser] saveUser];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
