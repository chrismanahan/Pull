
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

+ (UIView*)overlayOnView:(UIView*)view fromNib:(NSString*)nib offset:(NSInteger)offset pull:(PULPull*)pull
{
    PULPullOptionsOverlay *overlay = (PULPullOptionsOverlay*)[super overlayOnView:view fromNib:nib offset:offset];
    
    overlay.pull = pull;
    
    return overlay;
}

+ (void)overlayOnView:(UIView*)view withPull:(PULPull*)pull;
{
    // remove existing overlay if any
    [self removeOverlayFromView:view];
    
    // add nib to view
    [self overlayOnView:view fromNib:NSStringFromClass([self class]) offset:0 pull:pull];
}

- (void)setPull:(PULPull *)pull
{
    _pull = pull;
    // TODO: set expiration text label
//    _expirationLabel.text = [[NSString stringWithFormat:@"This pull wil end in %zd hours]
}

- (IBAction)ibEndNow:(id)sender
{
    [[PULAccount currentUser] cancelPull:_pull];
    
    [PULOverlayView removeOverlayFromView:self.superview];
}

- (IBAction)ibKeepActive:(id)sender
{
    [PULOverlayView removeOverlayFromView:self.superview];
}

@end
