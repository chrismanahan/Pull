//
//  PULUserCell.h
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PULUser;

@interface PULUserCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *userImageView;
@property (nonatomic, strong) IBOutlet UILabel *userDisplayNameLabel;

@end
