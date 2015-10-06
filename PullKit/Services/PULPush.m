//
//  PULPush.m
//  Pull
//
//  Created by Development on 11/28/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPush.h"

#import "PULUser.h"

@implementation PULPush

+ (void)sendPushType:(PULPushType)type to:(PULUser*)toUser from:(PULUser*)fromUser;
{
    PULLog(@"sending push of type: %zd", type);
    NSString *message;
    switch (type) {
        case PULPushTypeAcceptPull:
        {
            message = [NSString stringWithFormat:kPULPushFormattedMessageAcceptPull, fromUser.firstName];
            break;
        }
        case PULPushTypeSendPull:
        {
            message = [NSString stringWithFormat:kPULPushFormattedMessageSendPull, fromUser.firstName];
            break;
        }
        default:
            break;
    }
    
    if (message)
    {
        NSDictionary *data = @{@"alert": @"default",
                               @"sound": @"popcorn",
                               @"badge": @"increment"};
        PFPush *push = [[PFPush alloc] init];
        [push setChannel:[self _channelForUser:toUser]];
        [push setData:data];
        [push sendPushInBackground];
        PULLog(@"sent push");
    }
    else
    {
        PULLog(@"could not send push, not supported");
    }
}


+ (void)subscribeToPushNotifications:(PULUser*)user;
{
    NSString *channel = [self _channelForUser:user];
    PULLog(@"subscribing to channel: %@", channel);
    PFInstallation *install = [PFInstallation currentInstallation];
    [install setChannels:@[@"global", channel]];
    [install saveInBackground];
}

#pragma mark - Private
+ (NSString*)_channelForUser:(PULUser*)user
{
    NSAssert(user.username != nil, @"username cannot be nil");
    NSString *channel = [user.username stringByReplacingOccurrencesOfString:@":" withString:@""];
    return channel;
}

@end
