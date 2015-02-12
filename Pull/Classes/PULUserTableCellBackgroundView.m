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
    
//    if (pulling)
//    {
//        NSString *prefix = _left ? @"arrowsPurple" : @"arrowsRed";
//      
//        if (!_left)
//        {
//            // mirror arrows
//            CGAffineTransform t = CGAffineTransformIdentity;
//            t = CGAffineTransformMakeRotation(M_PI);
//            _arrowImageView.transform = t;
//        }
//        
//    }
    
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
                _accessoryImageViewContainer = [[PULUserImageView alloc] initWithFrame:view.frame];
                _accessoryImageViewContainer.hidden = YES;
                _accessoryImageViewContainer.borderColor = [UIColor whiteColor];
                
                _accessoryImageViewContainer.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
                _accessoryImageViewContainer.imageView.contentMode = UIViewContentModeScaleAspectFill;
                [_accessoryImageViewContainer addSubview:_accessoryImageViewContainer.imageView];
                _accessoryImageViewContainer.imageView.image = [UIImage imageNamed: !_left ? @"stop_icon" : @"pull_icon"];
                
                [self insertSubview:_accessoryImageViewContainer belowSubview:view];
            }
            
            _accessoryImageViewContainer.frame = _left ? _rightImageViewFrame : _leftImageViewFrame;
            
            
            _accessoryImageViewContainer.borderColor = [UIColor whiteColor];
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
    
    [super layoutSubviews];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    CGContextSetShadow(ref, CGSizeMake(0, 3), 5.0);
    
    UIColor *color = _bgColor ?: [UIColor whiteColor];
    CGContextSetFillColorWithColor(ref, color.CGColor);
    
    CGRect innerRect = CGRectInset(rect, 2, 4);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:innerRect cornerRadius:180];
    
    [path fill];
//    
//    if (_pulling)
//    {
//        UIColor *borderColor =  [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
//        
//        CGContextSetStrokeColorWithColor(ref, borderColor.CGColor);
//
//        
//        path.lineWidth = 4.0;
//        [path stroke];
//    }
}


@end
