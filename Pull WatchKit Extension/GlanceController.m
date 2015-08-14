//
//  GlanceController.m
//  Pull WatchKit Extension
//
//  Created by admin on 8/14/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "GlanceController.h"

#import "PULAccount.h"

@interface GlanceController()

@property (strong, nonatomic) IBOutlet WKInterfaceImage *compassImage;

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *nameLabel;

@end


@implementation GlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    NSLog(@"awake glance");
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    NSLog(@"activate glance");
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    
    NSLog(@"activate glance");
}

@end



