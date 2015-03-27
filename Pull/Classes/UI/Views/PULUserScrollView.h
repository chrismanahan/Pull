//
//  PULUserScrollView.h
//  Pull
//
//  Created by Development on 3/21/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const NSInteger kPULUserScrollViewPadding;

@class PULUserScrollView;
@class PULUserOld;

@protocol PULUserScrollViewDataSource <NSObject>

@required
- (NSInteger)numberOfUsersInUserScrollView:(PULUserScrollView*)userScrollView;
- (PULUserOld*)userForIndex:(NSInteger)index isActive:(BOOL*)active userScrollView:(PULUserScrollView*)userScrollView;
- (CGSize)cellSizeForUserScrollView:(PULUserScrollView*)userScrollView;

@optional
- (UIEdgeInsets)insetsForUserScrollView:(PULUserScrollView*)userScrollView;

@end

@interface PULUserScrollView : UIScrollView

@property (nonatomic, weak) IBOutlet id <PULUserScrollViewDataSource> dataSource;

@property (nonatomic, readonly) NSInteger maxNumberOfVisibleCells;
@property (nonatomic, readonly) CGSize cellSize;

- (void)reload;

@end
