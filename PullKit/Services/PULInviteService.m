//
//  PULInviteService.m
//  Pull
//
//  Created by Chris M on 5/4/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULInviteService.h"
#import "PULUser.h"

NSString * const kPULInviteServiceUrl = @"http://getpulled.com/Invite/invite.php";

typedef void(^PULConnectionBlock)(NSDictionary *jsonData, NSError *error);

@implementation PULInviteService

- (void)sendInviteToEmail:(NSString*)email completion:(PULInviteCompleteBlock)completion;
{
    PULLog(@"sending invite to: %@", email);
    NSDictionary *params = @{@"action": @"invite",
                             @"email": email,
                             @"from": [PULUser currentUser].username
                             };
    
    PULLog(@"sending params");
    
    [self runWithParameters:params
                 completion:^(NSDictionary *jsonData, NSError *error) {
                     if (jsonData)
                     {
                         PULLog(@"received json: %@", jsonData);
                         BOOL success = [jsonData[@"success"] boolValue];
                         NSInteger remaining = [jsonData[@"invitesRemaining"] integerValue];
                         
                         completion(success, remaining);
                     }
                     else
                     {
                         PULLog(@"no json from invite service");
                     }
                 }];
}

- (void)runWithParameters:(NSDictionary*)params completion:(PULConnectionBlock)completion;
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

@end
