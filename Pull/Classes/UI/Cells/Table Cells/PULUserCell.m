//
//  PULUserCell.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUserCell.h"

#import "PULAccount.h"

@interface PULUserCell ()

@property (nonatomic, strong) id userUpdatedObserver;

@end

@implementation PULUserCell

- (void)setUser:(PULUser *)user
{
    _userImageView.image = user.image;
    _userDisplayNameLabel.text = user.fullName;

    _user = user;
    
    if (_userUpdatedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_userUpdatedObserver];
        _userUpdatedObserver = nil;
    }
    
    // start observing updates from this user
    _userUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kPULFriendUpdatedNotifcation
                                                                             object:user
                                                                              queue:[NSOperationQueue currentQueue]
                                                                         usingBlock:^(NSNotification *note) {
                                                                             // set updated user
                                                                             self.user = [note object];
                                                                         }];
}

- (void)p_userUpdated
{
    
}

@end
