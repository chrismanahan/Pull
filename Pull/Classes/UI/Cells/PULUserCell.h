//
//  PULUserCell.h
//  Pull
//
//  Created by Chris M on 4/18/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PULUser;

typedef NS_ENUM(NSInteger, PULUserCellAccessoryButtonType)
{
    PULUserCellAccessoryButtonTypeNone,
    PULUserCellAccessoryButtonTypeLight,
    PULUserCellAccessoryButtonTypeDark
};

@interface PULUserCell : UITableViewCell

@property (nonatomic, strong) PULUser *user;

@property (nonatomic, assign) PULUserCellAccessoryButtonType accessoryButtonType;
@property (strong, nonatomic) IBOutlet UIButton *accessoryButton;


@end
