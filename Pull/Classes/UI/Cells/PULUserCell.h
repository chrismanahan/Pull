//
//  PULUserCell.h
//  Pull
//
//  Created by Chris M on 4/18/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PULUser;
@class PULUserCell;

typedef NS_ENUM(NSInteger, PULUserCellAccessoryButtonType)
{
    PULUserCellAccessoryButtonTypeNone,
    PULUserCellAccessoryButtonTypeLight,
    PULUserCellAccessoryButtonTypeDark
};

@protocol PULUserCellDelegate <NSObject>

- (void)userCell:(PULUserCell*)cell accessoryButtonTappedForUser:(PULUser *)user;

@end

@interface PULUserCell : UITableViewCell

@property (nonatomic, strong) PULUser *user;

@property (nonatomic, assign) PULUserCellAccessoryButtonType accessoryButtonType;
@property (strong, nonatomic, nullable) IBOutlet UIButton *accessoryButton;

@property (nonatomic, weak, nullable) id <PULUserCellDelegate> delegate;


@end


NS_ASSUME_NONNULL_END