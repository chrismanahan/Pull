//
//  PULVerticallyCenteredButton.m
//  Pull
//
//  Created by Development on 3/8/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULVerticallyCenteredButton.h"

@implementation PULVerticallyCenteredButton

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // get the size of the elements here for readability
    CGSize imageSize = self.imageView.frame.size;
    CGSize titleSize = self.titleLabel.frame.size;
    
    // get the height they will take up as a unit
    CGFloat totalHeight = (imageSize.height + titleSize.height + 6);
    
    // raise the image and push it right to center it
    self.imageEdgeInsets = UIEdgeInsetsMake(-(totalHeight - imageSize.height), 0.0, 0.0, - titleSize.width);
    
    // lower the text and push it left to center it
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (totalHeight - titleSize.height),0.0);
}
@end
