
//
//  PULPullOptionsOverlay.m
//  Pull
//
//  Created by Chris M on 4/30/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPullOptionsOverlay.h"

#import "PULAccount.h"

@interface PULPullOptionsOverlay ()

@property (strong, nonatomic) IBOutlet UILabel *expirationLabel;
@property (strong, nonatomic) IBOutlet UIButton *endNowButton;
@property (strong, nonatomic) IBOutlet UIButton *keepActiveButton;

@end

@implementation PULPullOptionsOverlay

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat corners = 4.0;
    _endNowButton.layer.cornerRadius = corners;
    _keepActiveButton.layer.cornerRadius = corners;
}


- (void)setPull:(PULPull *)pull
{
    [super setPull:pull];
    // TODO: set expiration text label
//    _expirationLabel.text = [[NSString stringWithFormat:@"This pull wil end in %zd hours]
}

- (IBAction)ibEndNow:(id)sender
{
    [[PULAccount currentUser] cancelPull:self.pull];
    
    [PULOverlayView removeOverlayFromView:self.superview];
}

- (IBAction)ibKeepActive:(id)sender
{
    [PULOverlayView removeOverlayFromView:self.superview];
}

@end
