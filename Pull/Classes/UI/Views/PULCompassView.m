 //
//  PULCompassView.m
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULCompassView.h"

#import "PULPull.h"
#import "PULUser.h"
#import "PULLocationUpdater.h"

#import "NZCircularImageView.h"

const CGFloat kPULCompassSmileyWinkDuration = 6;

@interface PULCompassView ()

@property (strong, nonatomic) IBOutlet NZCircularImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *overlayImageView;
@property (strong, nonatomic) IBOutlet UIImageView *compassImageView;

@end

@implementation PULCompassView

#pragma - View Life
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _imageView.borderColor = [UIColor whiteColor];
    _imageView.borderWidth = @(3);
}

#pragma mark - Public
- (void)setUserImageForPull:(PULPull*)pull
{
    // set user image
    [_imageView setImageWithResizeURL:[pull otherUser].imageUrlString];
    
    // determine if we need an overlay
    NSString *overlayImageName;
    switch (pull.status) {
        case PULPullStatusPending:
        {
            overlayImageName = [pull initiatedBy:[PULUser currentUser]] ? @"sent_request" : @"incoming_request";
            break;
        }
        case PULPullStatusPulled:
        {
            switch (pull.pullDistanceState) {
                case PULPullDistanceStateInaccurate:
                {
                    overlayImageName = @"low_accuracy";
                    break;
                }
                case PULPullDistanceStateFar:
                {
                    overlayImageName = @"not_nearby";
                    break;
                }
                case PULPullDistanceStateHere:
                {
                    overlayImageName = @"friend_here";
                    break;
                }
                case PULPullDistanceStateNearby:
                default:
                    break;
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
        [self _useCompass:NO];
    }
    else
    {
        _overlayImageView.hidden = YES;
        [self _useCompass:YES];
    }
}

- (void)showNoLocation;
{
    [self _useCompass:NO];
    _overlayImageView.hidden = YES;
    _imageView.backgroundColor = [UIColor whiteColor];
    _imageView.image = [UIImage imageNamed:@"smiley_sad_with_background"];
}

- (void)showBusy:(BOOL)busy;
{
    if (busy)
    {
        [self _useCompass:NO];
        _overlayImageView.hidden = YES;
        _imageView.backgroundColor = [UIColor whiteColor];
        _imageView.hidden = NO;
        _imageView.animationImages = @[[UIImage imageNamed:@"home_loading"],
                                       [UIImage imageNamed:@"home_loading2"],
                                       [UIImage imageNamed:@"home_loading3"],
                                       [UIImage imageNamed:@"home_loading4"]];
        _imageView.animationDuration = 0.5;
        [_imageView startAnimating];
    }
    else
    {
        [_imageView stopAnimating];
        _imageView.animationImages = nil;
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
    
    [self setNeedsLayout];
}

#pragma mark - Private
- (void)_displayNoActivePulls:(BOOL)display
{
    if (display)
    {
        [self _useCompass:NO];
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

- (void)_useCompass:(BOOL)useCompass
{
    if (useCompass)
    {
        [_compassImageView setImage:[UIImage imageNamed:@"compass"]];
        
        // start rotating compass
        static CGFloat lastRads = 0;
        [[PULLocationUpdater sharedUpdater] removeHeadingUpdateBlock];
        [[PULLocationUpdater sharedUpdater] setHeadingUpdateBlock:^(CLHeading *heading) {
            CGFloat rads = [[PULUser currentUser] angleWithHeading:heading
                                                             fromUser:[_pull otherUser]];
            
            if (rads >= lastRads + 0.1 || rads <= lastRads - 0.1)
            {
                [self _rotateCompassToRadians:rads];
                lastRads = rads;
            }
        }];
    }
    else
    {
        [[PULLocationUpdater sharedUpdater] removeHeadingUpdateBlock];
        
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
