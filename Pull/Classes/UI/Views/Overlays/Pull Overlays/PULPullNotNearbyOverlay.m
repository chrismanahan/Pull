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

#import "PULConstants.h"

@interface PULPullNotNearbyOverlay ()
@property (strong, nonatomic) IBOutlet PULUserImageView *userImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;

@end

@implementation PULPullNotNearbyOverlay

- (void)setPull:(PULPull *)pull
{
    [super setPull:pull];
    
    PULUser *friend = [self.pull otherUser];
    
    _nameLabel.text = friend.fullName;
    _subTitleLabel.text = [NSString stringWithFormat:@"We will notify you when %@ is within %zd ft",  friend.firstName, kPULNearbyDistanceFeet];
    [_userImageView setImage:friend.image forObject:friend];
}
- (IBAction)ibDismiss:(id)sender
{
    [PULOverlayView removeOverlayFromView:self.superview];
}


@end
