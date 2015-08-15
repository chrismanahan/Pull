//
//  PULUserSettings.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUserSettings.h"

// TODO: make constants for default values
@implementation PULUserSettings

+ (instancetype)defaultSettings;
{
    PULUserSettings *settings = [[PULUserSettings alloc] init];
    
    settings.notifyAccept = YES;
    settings.notifyInvite = YES;
    settings.notifyNearby = YES;
    settings.disabled = YES;
    settings.resolveAddress = YES;
    
    return settings;
}

#pragma mark - Fireable Protocol
- (NSString*)rootName
{
    return @"settings";
}

- (NSDictionary*)firebaseRepresentation
{
    return @{
             @"disabled": @(_disabled),
             @"resolveAddress": @(_resolveAddress),
             @"notification":@{
                     @"accept": @(_notifyAccept),
                     @"invite": @(_notifyInvite),
                     @"nearby": @(_notifyNearby)
                     }
             };
}

- (void)loadFromFirebaseRepresentation:(NSDictionary *)repr
{
    self.notifyInvite    = [repr[@"notification"][@"invite"] boolValue];
    self.notifyAccept    = [repr[@"notification"][@"accept"] boolValue];
    self.notifyNearby = [repr[@"notification"][@"nearby"] boolValue];

    self.disabled        = [repr[@"disabled"] boolValue];

    self.resolveAddress  = [repr[@"resolveAddress"] boolValue];
}

@end
