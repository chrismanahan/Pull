//
//  PULNotNearbyOverlay.m
//  Pull
//
//  Created by Chris M on 5/3/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPullNotNearbyOverlay.h"

#import "PULUserImageView.h"

#import "PULAccount.h"

@interface PULPullNotNearbyOverlay ()
@property (strong, nonatomic) IBOutlet PULUserImageView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *messengerButton;

@end

@implementation PULPullNotNearbyOverlay

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat corners = 4.0;
    _messengerButton.layer.cornerRadius = corners;
    
    // hide fb messenger button if it won't work
    NSURL *url = [NSURL URLWithString:@"fb-messenger://"];
    _messengerButton.hidden = ![[UIApplication sharedApplication] canOpenURL:url];
}

- (void)setPull:(PULPull *)pull
{
    [super setPull:pull];
    
    PULUser *friend = [self.pull otherUser:[PULAccount currentUser]];
    
    _nameLabel.text = friend.fullName;
    _subTitleLabel.text = [NSString stringWithFormat:@"We will notify you when %@ is within 1000 ft",  friend.firstName];
    [_userImageView setImage:friend.image forObject:friend];
}
- (IBAction)ibDismiss:(id)sender
{
    [PULOverlayView removeOverlayFromView:self.superview];
}

- (IBAction)ibMessenger:(id)sender
{
    
}


@end
