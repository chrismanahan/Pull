//
//  PULUserImageView.h
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const PULImageUpdatedNotification;

@interface PULUserImageView : UIView <NSCopying>

@property (nonatomic, strong) IBOutlet UIImageView *imageView;

@property (nonatomic, assign, getter=isSelected) BOOL selected;

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) BOOL hasBorder;

@property (nonatomic, assign) BOOL hasShadow;

- (void)setImage:(UIImage*)image forObject:(id)obj;

@end
