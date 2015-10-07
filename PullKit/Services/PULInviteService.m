//
//  PULInviteService.m
//  Pull
//
//  Created by Chris M on 5/4/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULInviteService.h"
#import "PULUser.h"

NSString * const kPULInviteServiceUrl = @"http://chrismanahan.com/getpulled.com/public_html/Invite/invite.php";//@"http://getpulled.com/Invite/invite.php";

typedef void(^PULConnectionBlock)(NSDictionary *jsonData, NSError *error);

@implementation PULInviteService

+ (instancetype)sharedInstance;
{
    static PULInviteService *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[PULInviteService alloc] init];
    });
    return shared;
}

- (void)sendInviteToEmail:(NSString*)email completion:(PULInviteCompleteBlock)completion;
{
    // create code to send
    NSString *code = [self _createInvite];
    
    PULLog(@"sending invite to: %@", email);
    NSDictionary *params = @{@"action": @"invite",
                             @"email": email,
                             @"from": [PULUser currentUser].fullName,
                             @"code": code
                             };
    
    PULLog(@"sending params");
    
    [self _runWithParameters:params
                 completion:^(NSDictionary *jsonData, NSError *error) {
                     if (jsonData)
                     {
                         PULLog(@"received json: %@", jsonData);
                         BOOL success = [jsonData[@"success"] boolValue];
                         if (success)
                         {
                             _invitesRemaining--;
                             if (_invitesRemaining == 0)
                             {
                                 _canSendInvites = NO;
                             }
                         }
                         
                         completion(success);
                     }
                     else
                     {
                         completion(NO);
                         PULLog(@"no json from invite service");
                     }
                 }];
}

- (void)redeemInviteCode:(NSString*)code completion:(PULInviteCompleteBlock)completion;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PFQuery *query = [PFQuery queryWithClassName:@"InviteLookup"];
        [query whereKey:@"code" equalTo:code];
        PFObject *obj = [query getFirstObject];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (obj)
            {
                // success, check if redeemed
                BOOL redeemed = [obj[@"isRedeemed"] boolValue];
                if (redeemed)
                {
                    completion(NO);
                }
                else
                {
                    obj[@"isRedeemed"] = @(YES);
                    [obj saveInBackground];
                    completion(YES);
                }
            }
            else
            {
                completion(NO);
            }
        });
    });
}

- (void)initialize;
{
    // determine if we can send invites
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PFQuery *query = [PFQuery queryWithClassName:@"InviteLookup"];
        [query whereKey:@"fromUser" equalTo:[PULUser currentUser]];
        
        NSArray *objs = [query findObjects];
        
        _canSendInvites = objs != nil || objs.count < 3;
        _invitesRemaining = 3 - objs.count;
    });
    
}

#pragma mark - Private
- (void)_runWithParameters:(NSDictionary*)params completion:(PULConnectionBlock)completion;
{
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@?", kPULInviteServiceUrl];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *args = [[NSString stringWithFormat:@"%@=%@&", key, obj] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [urlString appendString:args];
    }];
    

    // truncate the extra ampersand
    [urlString deleteCharactersInRange:NSMakeRange(urlString.length - 1, 1)];
    PULLog(@"url: %@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSDictionary *dict;
                               if (data)
                               {
                                   dict = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:nil];
                               }
                               completion(dict, connectionError);
                               
                           }];
}

- (NSString*)_createInvite;
{
    PFObject *obj = [PFObject objectWithClassName:@"InviteLookup"];
    obj[@"fromUser"] = [PULUser currentUser];
    obj[@"isRedeemed"] = @(NO);
    obj[@"code"] = [self _generateCode];
    [obj saveInBackground];
    
    return obj[@"code"];
}

-(NSString *)_generateCode
{
    NSInteger rand = arc4random() % 999999999;
    return [NSString stringWithFormat:@"%02x", (int)rand];
}
@end
