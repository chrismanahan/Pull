//
//  PULProfileViewController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULMenuViewController.h"

#import "PULUserImageView.h"

#import "PULAccount.h"

@interface PULMenuViewController ()

@property (strong, nonatomic) IBOutlet PULUserImageView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation PULMenuViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _populateUserInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_populateUserInfo)
                                                 name:kPULFriendUpdatedNotifcation
                                               object:[PULAccount currentUser]];
}

- (void)_populateUserInfo {
    _userImageView.imageView.image = [PULAccount currentUser].image;
    _nameLabel.text = [PULAccount currentUser].fullName;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
name:kPULFriendUpdatedNotifcation
                                                  object:[PULAccount currentUser]];
}


@end
