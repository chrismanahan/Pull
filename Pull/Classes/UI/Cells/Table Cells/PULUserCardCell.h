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
@class PULPull;

@interface PULUserCardCell : UITableViewCell <UIScrollViewDelegate>

/**
 *  Round image view container for the user's image
 */
@property (nonatomic, strong) IBOutlet PULUserImageView *userImageViewContainer;
/**
 *  Label for user's full name
 */
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
/**
 *  Label directly beneath user's name label.
 */
@property (nonatomic, strong) IBOutlet UILabel *accessoryLabel;
/**
 *  Button to open facebook messenger with user
 */
@property (nonatomic, strong) IBOutlet UIButton *messengerButton;
/**
 *  Button to decline a requested pull
 */
@property (nonatomic, strong) IBOutlet UIButton *declineButton;
/**
 *  Button to accept a requested pull
 */
@property (nonatomic, strong) IBOutlet UIButton *acceptButton;
/**
 *  Button to cancel a pending pull
 */
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
/**
 *  Button that displays the duration of a pull
 */
@property (nonatomic, strong) IBOutlet UIButton *durationButton;
/**
 *  Accent line on left of cell
 */
@property (strong, nonatomic) IBOutlet UIView *accentLine;

/**
 *  Pull associated with this cell
 */
@property (nonatomic, strong) PULPull *pull;

/**
 *  Asserts that pull is both set. Loads the UI of the cell depending on the state of the pull with the associated other user
 */
- (void)loadUI;

@end
