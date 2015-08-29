//
//  PULUserCell.m
//  Pull
//
//  Created by Chris M on 4/18/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserCell.h" 

#import "NZCircularImageView.h"

#import "PULUser.h"

@interface PULUserCell ()


@property (strong, nonatomic) IBOutlet NZCircularImageView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation PULUserCell

#pragma mark - Properties
- (void)setUser:(PULUser *)user
{
    _user = user;
    
    [_userImageView setImageWithResizeURL:_user.imageUrlString];
    _nameLabel.text = _user.fullName;
}

@end
