//
//  PULPullListViewController.h
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PULCompassView;
@class PULPulledUserDataSource;

@interface PULPullListViewController : UIViewController <UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>


@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet PULCompassView *compassView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIView *dialogContainer;
@property (strong, nonatomic) IBOutlet UIButton *dialogAcceptButton;
@property (strong, nonatomic) IBOutlet UIButton *dialogDeclineButton;
@property (strong, nonatomic) IBOutlet UILabel *dialogMessageLabel;
@property (strong, nonatomic) IBOutlet UIButton *dialogCancelButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *dialogLabelBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *compassUserImageViewTopConstraint;
@property (strong, nonatomic) IBOutlet UIImageView *cutoutImageView;
@property (strong, nonatomic) IBOutlet UIImageView *moreNotificationImageViewRight;
@property (strong, nonatomic) IBOutlet UIImageView *moreNotificationImageViewLeft;
@property (strong, nonatomic) IBOutlet UIView *moreNotificationContainerRight;
@property (strong, nonatomic) IBOutlet UIView *moreNotificationContainerLeft;
@property (strong, nonatomic) IBOutlet UIButton *pullTimeButton;
@property (strong, nonatomic) IBOutlet UIButton *addPullButton;

@property (strong, nonatomic) IBOutlet UILabel *debug_accuracyLabel;
@property (strong, nonatomic) IBOutlet UILabel *debug_acctAccuracyLabel;

@property (nonatomic, strong) PULPull *displayedPull;
@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, strong) NSMutableArray *observers;

@property (nonatomic, strong) PULPulledUserDataSource *pulledUserDatasource;

@end
