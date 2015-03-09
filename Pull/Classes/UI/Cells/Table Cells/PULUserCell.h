//
//  PULUserCell.h
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PULUserImageView.h"

@class PULUser;
@class PULUserTableCellBackgroundView;
@class PULUserCell;

typedef NS_ENUM(NSInteger, PULUserCellType)
{
    PULUserCellTypeNone,
    PULUserCellTypeNearby,
    PULUserCellTypeWaiting,
    PULUserCellTypePending,
    PULUserCellTypePulled
};

@protocol PULUserCellDelegate <NSObject>

- (void)userCellDidBeginPulling:(PULUserCell*)cell;
- (void)userCellDidAbortPulling:(PULUserCell*)cell;
- (void)userCellDidCompletePulling:(PULUserCell*)cell;
- (void)userCellDidDeclinePull:(PULUserCell*)cell;
- (void)userCellDidAcceptPull:(PULUserCell*)cell;
- (void)userCellDidCancelPull:(PULUserCell*)cell;

@end

@interface PULUserCell : UITableViewCell <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet PULUserImageView *userImageViewContainer;
@property (nonatomic, strong) IBOutlet UILabel *userDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *userDistanceLabel;
@property (nonatomic, strong) IBOutlet UIView *bgView;
@property (strong, nonatomic) IBOutlet UIImageView *accessoryImageView;

@property (nonatomic) PULUserCellType type;

@property (nonatomic, strong) PULUser *user;

@property (nonatomic, weak) id <PULUserCellDelegate> delegate;

@end
