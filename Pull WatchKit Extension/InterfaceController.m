//
//  InterfaceController.m
//  Pull WatchKit Extension
//
//  Created by admin on 8/14/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "InterfaceController.h"

#import "MMWormHole.h"

@interface InterfaceController()

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *nameLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *angleLabel;
@property (nonatomic, strong) MMWormhole *wormhole;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.pull"
                                                     optionalDirectory:@"wormhole"];
    
    static int count = 0;
    [_wormhole listenForMessageWithIdentifier:@"com.pull-llc.watch-data"
                                     listener:^(__nullable id messageObject) {
                                         if (messageObject[@"angle"] && messageObject[@"friendName"])
                                         {
                                             CGFloat angle = [messageObject[@"angle"] doubleValue];
                                             NSString *name = messageObject[@"friendName"];
                                             
                                             _nameLabel.text = name;
                                             _angleLabel.text = [NSString stringWithFormat:@"%.4f", angle];
                                         }
                                     }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



