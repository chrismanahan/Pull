//
//  PULPush.m
//  Pull
//
//  Created by Development on 11/28/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPush.h"

#import "PULUser.h"

#import "PULLocalPush.h"

@implementation PULPush

+ (void)sendPushType:(PULPushType)type to:(PULUser*)toUser from:(PULUser*)fromUser;
{
    // we can send this to a background thread since it's not urgent
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PULLog(@"sending push of type: %zd", type);
        NSString *message;
        BOOL canSend = YES;
        BOOL isLocal = NO;
        
         // fetch other user's settings if needed
        [toUser.userSettings fetchIfNeeded];
        
        switch (type) {
            case PULPushTypeAcceptPull:
            {
                canSend = toUser.userSettings.notifyAccept;
                message = [NSString stringWithFormat:kPULPushFormattedMessageAcceptPull, fromUser.firstName];
                break;
            }
            case PULPushTypeSendPull:
            {
                canSend = toUser.userSettings.notifyInvite;
                message = [NSString stringWithFormat:kPULPushFormattedMessageSendPull, fromUser.firstName];
                break;
            }
            case PULPushTypeLocalFriendNearby:
            {
                isLocal = YES;
                canSend = toUser.userSettings.notifyNearby;
                message = [NSString stringWithFormat:@"%@ is nearby!", fromUser.firstName];
                break;
            }
            case PULPushTypeLocalFriendGone:
            {
                isLocal = YES;
                canSend = toUser.userSettings.notifyGone;
                message = [NSString stringWithFormat:@"%@ is no longer nearby", fromUser.firstName];
                break;
            }
            default:
                break;
        }
        
        if (message && canSend)
        {
            if (isLocal)
            {
                [PULLocalPush sendLocalPushWithMessage:message];
            }
            else
            {
                NSDictionary *data = @{@"alert": message,
                                       @"sound": @"default",
                                       @"badge": @"increment"};
                PFPush *push = [[PFPush alloc] init];
                [push setChannel:[self _channelForUser:toUser]];
                [push setData:data];
                [push sendPushInBackground];
                PULLog(@"sent push");
            }
        }
        else if (!canSend)
        {
            PULLog(@"\tuser does no want this type of notif");
        }
        else
        {
            PULLog(@"\tcould not send push, not supported");
        }
    });
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
