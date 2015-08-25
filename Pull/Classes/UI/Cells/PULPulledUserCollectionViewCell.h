//
//  PULPulledUserCollectionViewCell.h
//  Pull
//
//  Created by admin on 8/25/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PULPulledUserCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) PULPull *pull;

- (void)setActive:(BOOL)active animated:(BOOL)animated;

@end
