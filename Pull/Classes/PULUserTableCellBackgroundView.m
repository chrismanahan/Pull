//
//  PULUserTableCellBackgroundView.m
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import "PULUserTableCellBackgroundView.h"

#import "PULUserImageView.h"

IB_DESIGNABLE

@interface PULUserTableCellBackgroundView ()

@property (nonatomic, strong) PULUserImageView *accessoryImageViewContainer;

@property (nonatomic) BOOL layedOutTwice;

@end

@implementation PULUserTableCellBackgroundView

- (void)setPulling:(BOOL)pulling
{
    _pulling = pulling;;
    
    _arrowImageView.hidden = !pulling;
    
    if (pulling)
    {
        NSString *prefix = _left ? @"arrowsRed" : @"arrowsPurple";
            NSMutableArray *images = [[NSMutableArray alloc] init];
            for (int i = 0; i <= 3; i++)
            {
                NSString *imageName = [NSString stringWithFormat:@"%@_%i", prefix, i];
                UIImage *img = [UIImage imageNamed:imageName];
                [images  addObject:img];
            }
            for (int i = 3; i >= 0; i--)
            {
                NSString *imageName = [NSString stringWithFormat:@"%@_%i", prefix, i];
                UIImage *img = [UIImage imageNamed:imageName];
                [images  addObject:img];
            }

            _arrowImageView.animationImages = images;
            _arrowImageView.animationDuration = .8;
            _arrowImageView.animationRepeatCount = 0;
            
            if (!_left)
            {
                // mirror arrows
                CGAffineTransform t = CGAffineTransformIdentity;
                t = CGAffineTransformMakeRotation(M_PI);
                _arrowImageView.transform = t;
            }
        
        [_arrowImageView startAnimating];
    }
    
    _accessoryImageViewContainer.hidden = !pulling;
}

#pragma mark - Layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // we wanna make sure the image views are lined up correctly
    for (PULUserImageView *view in self.subviews)
    {
        if ([view isKindOfClass:[PULUserImageView class]] && view != _accessoryImageViewContainer)
        {
            // resize
            CGSize size = view.frame.size;
            size.height = CGRectGetHeight(self.frame) - 8;
            size.width = size.height;
            
            // reposisition
            CGFloat xOffset = 0;
            CGFloat x = view.frame.origin.x;
                
            // left side
            x = CGRectGetMinX(self.frame) + xOffset;
            _leftImageViewFrame = CGRectMake(x, view.frame.origin.y, size.width, size.height);

            // right side
            x = CGRectGetMaxX(self.frame) - size.width - xOffset;
            _rightImageViewFrame = CGRectMake(x, view.frame.origin.y, size.width, size.height);
            
            if (_left)
            {
                _originalRect = _leftImageViewFrame;
            }
            else
            {
                _originalRect = _rightImageViewFrame;
            }

            view.frame = _originalRect;
            
            // move center
            CGPoint center = view.center;
            center.y = CGRectGetMidY(self.frame);
            view.center = center;
            
            if (!_accessoryImageViewContainer)
            {
                _accessoryImageViewContainer = [view copy];
                _accessoryImageViewContainer.hidden = YES;
                
                _accessoryImageViewContainer.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
                _accessoryImageViewContainer.imageView.contentMode = UIViewContentModeScaleAspectFit;
                [_accessoryImageViewContainer addSubview:_accessoryImageViewContainer.imageView];
                _accessoryImageViewContainer.imageView.image = [UIImage imageNamed: _left ? @"stopPlaceholder" : @"pullPlaceholder"];
                
                [self insertSubview:_accessoryImageViewContainer belowSubview:view];
            }
            
            _accessoryImageViewContainer.frame = _left ? _rightImageViewFrame : _leftImageViewFrame;
            
            UIColor *color = _left ? [UIColor redColor] : [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
            
            _accessoryImageViewContainer.borderColor = color;
            _accessoryImageViewContainer.backgroundColor = [UIColor clearColor];
            
            center = _accessoryImageViewContainer.center;
            center.y = CGRectGetMidY(self.frame);
            _accessoryImageViewContainer.center = center;
            
            [_accessoryImageViewContainer setNeedsLayout];
            [view setNeedsLayout];
            
            if (!_layedOutTwice)
            {
                _layedOutTwice = YES;
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setNeedsLayout];
                });
                
            }
            
            break;
        }
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetShadow(ref, CGSizeMake(0, 3), 5.0);
    
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    
    UIColor *borderColor;
    if (self.left)
    {
        borderColor = [UIColor redColor];
    }
    else
    {
        borderColor =  [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
    }
    
    
    CGContextSetStrokeColorWithColor(ref, borderColor.CGColor);
    
    CGRect innerRect = CGRectInset(rect, 2, 4);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:innerRect cornerRadius:180];
    
    [path fill];
    
    if (_pulling)
    {
        path.lineWidth = 4.0;
        [path stroke];
    }
}


@end
