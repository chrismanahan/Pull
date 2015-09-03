//
//  PULCompassView.m
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULCompassView.h"

#import "NZCircularImageView.h"

const CGFloat kPULCompassSmileyWinkDuration = 6;

@interface PULCompassView ()

@property (strong, nonatomic) IBOutlet NZCircularImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *overlayImageView;
@property (strong, nonatomic) IBOutlet UIImageView *compassImageView;

@end

@implementation PULCompassView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _imageView.borderColor = [UIColor whiteColor];
    _imageView.borderWidth = @(3);
}

- (void)_displayNoActivePulls:(BOOL)display
{
    if (display)
    {
        [self _setCompassView:NO];
        _overlayImageView.hidden = YES;
        _imageView.backgroundColor = [UIColor whiteColor];
        
        _imageView.animationImages = @[[UIImage imageNamed:@"smiley_smile_with_background"],
                                       [UIImage imageNamed:@"smiley_wink_with_background"]];
        _imageView.animationDuration = kPULCompassSmileyWinkDuration;
        [_imageView startAnimating];
    }
    else
    {
        [_imageView stopAnimating];
        _imageView.animationImages = nil;
    }
}

- (void)setUserImageForPull:(PULPull*)pull
{
    // set user image
    [_imageView setImageWithResizeURL:[pull otherUser].imageUrlString];
    
    // determine if we need an overlay
    NSString *overlayImageName;
    switch (pull.status) {
        case PULPullStatusPending:
        {
            overlayImageName = [pull initiatedBy:[PULAccount currentUser]] ? @"sent_request" : @"incoming_request";
            break;
        }
        case PULPullStatusPulled:
        {
            // either gonna be not nearby, none, or nearby
            if (pull.isHere)
            {
                overlayImageName = @"friend_here";
            }
            else if (!pull.isNearby)
            {
                overlayImageName = @"not_nearby";
            }
            
            if (![pull isAccurate])
            {
                overlayImageName = @"low_accuracy";
            }
            
            break;
        }
        case PULPullStatusExpired:
        case PULPullStatusNone:
        default:
            break;
    }
    
    if (overlayImageName)
    {
        _overlayImageView.hidden = NO;
        [_overlayImageView setImage:[UIImage imageNamed:overlayImageName]];
    }
    else
    {
        _overlayImageView.hidden = YES;
    }
    
}

- (void)setPull:(PULPull*)pull
{
    _pull = pull;
    
    if (!_pull)
    {
        [self _displayNoActivePulls:YES];
        return;
    }
    
    [self _displayNoActivePulls:NO];

    // set user image
    [self setUserImageForPull:_pull];
    
    // remove previous heading update block
    [[PULLocationUpdater sharedUpdater] removeHeadingUpdateBlock];
    
    BOOL showCompass = _pull.isNearby && !_pull.isHere && [_pull isAccurate];
    [self _setCompassView:showCompass];
    
    if (showCompass)
    {
        // start rotating compass
        static CGFloat lastRads = 0;
        [[PULLocationUpdater sharedUpdater] setHeadingUpdateBlock:^(CLHeading *heading) {
            CGFloat rads = [[PULAccount currentUser] angleWithHeading:heading
                                                             fromUser:[pull otherUser]];
            
            if (rads >= lastRads + 0.01 || rads <= lastRads - 0.01)
            {
                [self _rotateCompassToRadians:rads];
                lastRads = rads;
            }
        }];
    }
    
    [self setNeedsLayout];
}

- (void)_setCompassView:(BOOL)isCompass
{
    if (isCompass)
    {
        [_compassImageView setImage:[UIImage imageNamed:@"compass"]];
    }
    else
    {
        _compassImageView.transform = CGAffineTransformIdentity;
        [_compassImageView setImage:[UIImage imageNamed:@"circle_purple"]];
    }
}

- (void)_rotateCompassToRadians:(CGFloat)rads
{
    CGSize offset = CGSizeMake(_imageView.center.x - _compassImageView.center.x, _imageView.center.y - _compassImageView.center.y);
    
    CGAffineTransform tr = CGAffineTransformIdentity;
    tr = CGAffineTransformConcat(tr,CGAffineTransformMakeTranslation(-offset.width, -offset.height));
    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeRotation(rads));
    tr = CGAffineTransformConcat(tr, CGAffineTransformMakeTranslation(offset.width, offset.height) );

    [_compassImageView setTransform:tr];
}

@end
