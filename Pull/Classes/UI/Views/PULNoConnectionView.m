//
//  PULNoConnectionView.m
//  Pull
//
//  Created by admin on 2/13/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULNoConnectionView.h"

#import "PULConstants.h"

#import "Reachability.h"

NSString * const kPULConnectionRestoredNotification = @"kPULConnectionRestoredNotification";

NSString * const kPULConnectionLostNotification = @"kPULConnectionLostNotification;";

@interface PULNoConnectionView ()

@property (nonatomic, strong) Reachability *reachability;

@end

@implementation PULNoConnectionView

+ (instancetype)sharedInstance
{
    static PULNoConnectionView *view = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        view = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil][0];
    });
    
    return view;
}

+ (void)startMonitoringConnection
{
    [[self sharedInstance] initializeReachability];
}

- (void)initializeReachability
{
    
    _reachability = [Reachability reachabilityForInternetConnection];
    
    PULLog(@"starting reachability notifier");
    [_reachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:_reachability];
}

- (void)reachabilityChanged:(NSNotification*)note
{
    NetworkStatus netStatus = [_reachability currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:
        {
            PULLog(@"NETWORKCHECK: Not Connected");
            break;
        }
        case ReachableViaWWAN:
        {
            PULLog(@"NETWORKCHECK: Connected Via WWAN");
            break;
        }
        case ReachableViaWiFi:
        {
            PULLog(@"NETWORKCHECK: Connected Via WiFi");
            break;
        }
    }
    
    if ([_reachability isReachable])
    {
        if (self.superview)
        {
            PULLog(@"removing no connection view");
            [self removeFromSuperview];

            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPULConnectionRestoredNotification
                                                                object:self];
            
        }
    }
    else
    {
        if (!self.superview)
        {
            UIView *topView = [self topMostController].view;
            self.frame = topView.bounds;
            [topView addSubview:self];
            
            PULLog(@"adding no connection view");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPULConnectionLostNotification
                                                                object:self];
        }
    }
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
