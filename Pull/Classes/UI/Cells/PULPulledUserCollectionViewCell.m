//
//  PULPulledUserCollectionViewCell.m
//  Pull
//
//  Created by admin on 8/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPulledUserCollectionViewCell.h"

#import "PULPull.h"
#import "PULUser.h"

#import "NZCircularImageView.h"

#import "CALayer+Animations.h"

@interface PULPulledUserCollectionViewCell ()

@property (strong, nonatomic) IBOutlet NZCircularImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *requestNotificationImageView;

@end

@implementation PULPulledUserCollectionViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _imageView.layer.masksToBounds = NO;
        self.layer.masksToBounds = NO;
    }
    
    return self;
}

- (void)setPull:(PULPull *)pull
{
    [_imageView setImageWithResizeURL:[pull otherUser].imageUrlString];
    _imageView.borderWidth = @(5);
    _imageView.borderColor = PUL_LightGray;
    _imageView.alpha = 1.0;
    
    if (pull.status == PULPullStatusPending && [pull.receivingUser isEqual:[PULUser currentUser]])
    {
        _requestNotificationImageView.hidden = NO;
    }
    else if (pull.status == PULPullStatusPending)
    {
        _imageView.alpha = 0.6;
        _requestNotificationImageView.hidden = YES;
    }
    else
    {
        _requestNotificationImageView.hidden = YES;
    }
}

- (void)setActive:(BOOL)active animated:(BOOL)animated
{
    if (active)
    {
        _imageView.borderColor = PUL_Purple;
        
        if (animated)
        {
            [_imageView.layer addPopAnimation];
        }
    }
    else
    {
        _imageView.borderColor = PUL_LightGray;
    }
}

@end
