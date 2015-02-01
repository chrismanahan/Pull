//
//  PULUserTableCellBackgroundView.h
//  Pull
//
//  Created by Development on 10/15/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PULUserTableCellBackgroundView : UIView

@property (nonatomic, assign, getter=isPulling) BOOL pulling;

@property (nonatomic, assign) IBInspectable BOOL left;

@property (nonatomic, assign) CGRect rightImageViewFrame;
@property (nonatomic, assign) CGRect leftImageViewFrame;
@property (nonatomic, assign) CGRect originalRect;

@property (nonatomic, strong) IBOutlet UIImageView *arrowImageView;

@end
