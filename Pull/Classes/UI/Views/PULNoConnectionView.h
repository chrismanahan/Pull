//
//  PULNoConnectionView.h
//  Pull
//
//  Created by admin on 2/13/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kPULConnectionRestoredNotification;
extern NSString * const kPULConnectionLostNotification;

@interface PULNoConnectionView : UIView

+ (void)startMonitoringConnection;

@end
