//
//  PULCompassView.m
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULCompassView.h"

#import "NZCircularImageView.h"

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

- (void)setPull:(PULPull*)pull
{
    [_imageView setImageWithResizeURL:[pull otherUser].imageUrlString];
    
    _pull = pull;
    
    [[PULLocationUpdater sharedUpdater] removeHeadingUpdateBlock];
    
    if (_pull.status == PULPullStatusPending)
    {
        if ([_pull.sendingUser isEqual:[PULAccount currentUser]])
        {
            // waiting on response
            _overlayImageView.hidden = NO;
            [_overlayImageView setImage:[UIImage imageNamed:@"sent_request"]];
        }
        else
        {
            // waiting on us
            _overlayImageView.hidden = NO;
            [_overlayImageView setImage:[UIImage imageNamed:@"incoming_request"]];
        }
        
        [self _setCompassView:NO];
    }
    else if (_pull.status == PULPullStatusPulled && !_pull.nearby)
    {
        [self _setCompassView:NO];
        _overlayImageView.hidden = NO;
        [_overlayImageView setImage:[UIImage imageNamed:@"not_nearby"]];
    }
    else
    {
        [self _setCompassView:YES];
        _overlayImageView.hidden = YES;
        
//        static CGFloat lastRads = 0;
        [[PULLocationUpdater sharedUpdater] setHeadingUpdateBlock:^(CLHeading *heading) {
            CGFloat rads = [[PULAccount currentUser] angleWithHeading:heading
                                                             fromUser:[pull otherUser]];
            
//            if (rads >= lastRads + 0.005 || rads <= lastRads - 0.005)
//            {
                [self _rotateCompassToRadians:rads];
//                lastRads = rads;
//            }
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
