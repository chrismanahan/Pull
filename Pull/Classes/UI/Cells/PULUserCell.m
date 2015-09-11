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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_accessoryButton)
    {
        _accessoryButton.layer.cornerRadius = 5;
        
        switch (_accessoryButtonType) {
            case PULUserCellAccessoryButtonTypeLight:
            {
                _accessoryButton.backgroundColor = [UIColor whiteColor];
                UIColor *textColor = PUL_Purple;
                [_accessoryButton setTitleColor:textColor forState:UIControlStateNormal];
                break;
            }
            case PULUserCellAccessoryButtonTypeDark:
            {
                _accessoryButton.backgroundColor = PUL_DarkPurple;
                UIColor *textColor = PUL_LightGray;
                [_accessoryButton setTitleColor:textColor forState:UIControlStateNormal];
                break;
            }
            case PULUserCellAccessoryButtonTypeNone:
            default:
            {
                _accessoryButton.hidden = YES;
                break;
            }
        }
    }
}

#pragma mark - Actions
- (IBAction)ibAccessoryTapped:(id)sender
{
    if ([_delegate respondsToSelector:@selector(userCell:accessoryButtonTappedForUser:)])
    {
        [_delegate userCell:self accessoryButtonTappedForUser:_user];
    }
}

#pragma mark - Properties
- (void)setUser:(PULUser *)user
{
    _user = user;
    
    [_userImageView setImageWithResizeURL:_user.imageUrlString];
    _nameLabel.text = _user.fullName;
}

@end
