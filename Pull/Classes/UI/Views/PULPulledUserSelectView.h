//
//  PULPulledUserSelectView.h
//  Pull
//
//  Created by Chris M on 8/22/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PULPulledUserSelectViewDelegate <NSObject>

- (void)didSelectPull:(PULPull*)pull atIndex:(NSUInteger)index;

@end

@interface PULPulledUserSelectView : UIView

/****************************************************
 Properties
 ****************************************************/

/**
 *  Currently selected pull. Can only be null if there are no pulls available
 */
@property (nonatomic, strong, readonly, nullable) PULPull *selectedPull;
/**
 *  Currently selected user. Can only be null if there are no pulls available
 */
@property (nonatomic, strong, readonly) PULUser *selectedUser;
/**
 *  Currently selected index. -1 if no pulls available
 */
@property (nonatomic, assign, readonly) NSInteger selectedIndex;
/**
 *  Max index that can be selected. -1 if no pulls available
 */
@property (nonatomic, assign, readonly) NSInteger maxIndex;

@property (nonatomic, weak) id <PULPulledUserSelectViewDelegate> delegate;

/****************************************************
 Instance Methods
 ****************************************************/

/**
 *  Gets a pull at a specific index
 *
 *  @param index Index to look up pull for
 *
 *  @return Pull or null
 */
- (nullable PULPull*)pullAtIndex:(NSUInteger)index;

/**
 *  Manually set the selected index. This is used to control the selection from outside the control
 *
 *  @param selectedIndex New index to be selected
 */
- (void)setSelectedIndex:(NSInteger)selectedIndex;

- (void)setSelectedPull:(PULPull * __nullable)selectedPull;

/**
 *  Reloads the view. Should be called when first displaying it. The view will manage itself and update as it detects changes in pulls
 */
- (void)reload;

@end

NS_ASSUME_NONNULL_END
