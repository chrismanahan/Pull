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

@property (nonatomic, assign) BOOL dirty;

@end

@implementation PULSettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    PULUserSettings *settings = [PULAccount currentUser].settings;
    [_notifAcceptSwitch setOn:settings.notifyAccept];
    [_notifInviteSwitch setOn:settings.notifyInvite];
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
