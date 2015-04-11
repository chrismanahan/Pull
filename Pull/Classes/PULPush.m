//
//  PULPush.m
//  Pull
//
//  Created by Development on 11/28/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULPush.h"

#import "PULUser.h"

NSString * const kPULPushServerURL = @"http://chrismanahan.com/pull/push.php";

NSString * const kPULPushTypeSendFriendRequest   = @"sendFriendRequest";
NSString * const kPULPushTypeAcceptFriendRequest = @"acceptFriendRequest";
NSString * const kPULPushTypeSendPull            = @"sendPull";
NSString * const kPULPushTypeAcceptPull          = @"acceptPull";

@implementation PULPush

+ (void)sendPushType:(NSString*)pushType to:(PULUser*)toUser from:(PULUser*)fromUser;
{
    PULLog(@"sending push (%@) to %@", pushType, toUser.firstName);
    BOOL sendPush = YES;
    // check if other user wants this notifcation
    if ([pushType isEqualToString:kPULPushTypeAcceptPull])
    {
        sendPush = toUser.settings.notifyAccept;
    }
    else if ([pushType isEqualToString:kPULPushTypeSendPull])
    {
        sendPush = toUser.settings.notifyInvite;
    }
    
    if (sendPush)
    {
        NSString *deviceToken = toUser.deviceToken;
        
        NSString *urlString = [NSString stringWithFormat:@"%@?type=%@&name=%@&deviceToken=%@", kPULPushServerURL, pushType, fromUser.firstName, deviceToken];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        
        [NSURLConnection sendAsynchronousRequest:req
                                           queue:[NSOperationQueue currentQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   PULLog(@"sent push: %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
                               }];
    }
}

@end
