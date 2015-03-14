//
//  PULNoFriendsOverlay.m
//  Pull
//
//  Created by Development on 3/14/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULNoFriendsOverlay.h"

NSString * const PULNoFriendsOverlayButtonTappedSendInvite = @"PULNoFriendsOverlayButtonTappedSendInvite";
NSString * const PULNoFriendsOverlayButtonTappedCopyLink = @"PULNoFriendsOverlayButtonTappedCopyLink";

@interface PULNoFriendsOverlay ()

@property (strong, nonatomic) IBOutlet UIButton *cpyLinkButton;


@end

@implementation PULNoFriendsOverlay

#pragma mark - Layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat cornerRadius = 5.0;
    _cpyLinkButton.layer.cornerRadius = cornerRadius;
}

#pragma mark - Actions

- (IBAction)ibCopyLink:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:PULNoFriendsOverlayButtonTappedCopyLink object:nil];
    
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimation.duration = 0.15;
    theAnimation.autoreverses = YES;
    theAnimation.fromValue = @(1);
    theAnimation.toValue = @(1.05);
    [_cpyLinkButton.layer addAnimation:theAnimation forKey:@"animateScale"];
}

@end
