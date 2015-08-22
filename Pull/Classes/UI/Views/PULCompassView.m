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
@property (strong, nonatomic) IBOutlet UIImageView *compassImageView;

@end

@implementation PULCompassView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self addSubview:[[NSBundle mainBundle] loadNibNamed:@"PULCompassView"
                                                         owner:self
                                                     options:nil][0]];
        
        
    }
    return self;
}

- (void)setPull:(PULPull*)pull
{
    [_imageView setImageWithResizeURL:[pull otherUser].imageUrlString];
    
    _pull = pull;
    
    [[PULLocationUpdater sharedUpdater] removeHeadingUpdateBlock];
    
    static CGFloat lastRads = 0;
    [[PULLocationUpdater sharedUpdater] setHeadingUpdateBlock:^(CLHeading *heading) {
        CGFloat rads = [[PULAccount currentUser] angleWithHeading:heading
                                                         fromUser:[pull otherUser]];
        
        if (rads >= lastRads + 0.005 || rads <= lastRads - 0.005)
        {
            [self _rotateCompassToRadians:rads];
            lastRads = rads;
        }
    }];
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
