//
//  PULNoConnectionView.h
//  Pull
//
//  Created by admin on 2/13/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULOverlayView.h"

extern NSString * const PULConnectionRestoredNotification;
extern NSString * const PULConnectionLostNotification;

@interface PULNoConnectionView : PULOverlayView

+ (void)startMonitoringConnection;

@end
