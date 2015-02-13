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
    
    _reachability = [Reachability reachabilityWithHostName:@"google.com"];
    
    PULLog(@"starting reachability notifier");
    [_reachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:_reachability];
}

- (void)reachabilityChanged:(NSNotification*)note
{
    if ([_reachability isReachable])
    {
        PULLog(@"reachable now");
        
        if (self.superview)
        {
            [self removeFromSuperview];
        }
    }
    else
    {
        PULLog(@"unreachable");
        if (!self.superview)
        {
            [[self topMostController].view addSubview:self];
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
