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
}

#pragma mark - Layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // we wanna make sure the image views are lined up correctly
    for (PULUserImageView *view in self.subviews)
    {
        if ([view isKindOfClass:[PULUserImageView class]])
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
            
            [view setNeedsLayout];
            
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
