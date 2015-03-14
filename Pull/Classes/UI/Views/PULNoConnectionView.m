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

NSString * const PULConnectionRestoredNotification = @"kPULConnectionRestoredNotification";

NSString * const PULConnectionLostNotification = @"kPULConnectionLostNotification;";

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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULConnectionRestoredNotification
                                                            object:self];
        
        
    }
    else
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PULConnectionLostNotification
                                                            object:self];
        
    }
}

@end
