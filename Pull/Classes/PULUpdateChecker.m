//
//  PULUpdateChecker.m
//  Pull
//
//  Created by Chris Manahan on 2/21/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULUpdateChecker.h"

#import <UIKit/UIKit.h>

NSString * const kPULUpdateDeclinedKey = @"UpdateDeclinedKey";

@interface PULUpdateChecker () <UIAlertViewDelegate>

@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *updateVersion;
@property (nonatomic) BOOL mandatory;

@end

@implementation PULUpdateChecker

+ (void)checkForUpdate;
{
    static PULUpdateChecker *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[PULUpdateChecker alloc] init];
    });
    
    [shared _checkForUpdate];
}

#pragma mark - private
- (void)_checkForUpdate
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    NSURL *url = [NSURL URLWithString:kPULAppUpdateURL];
    NSURLRequest *req = [NSURLRequest requestWithURL:url
                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:0.0];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError && data)
                               {
                                   NSDictionary *updateDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                   
                                   _updateVersion    = updateDict[@"version"];
                                   _mandatory        = [updateDict[@"mandatory"] boolValue];
                                   NSString *message = updateDict[@"updateMessage"];
                                   _downloadUrl      = updateDict[@"downloadUrl"];
                                   
                                   
                                   // check if we ignored this update
                                   NSString *key = [self _updateDefaultsKeyForVersion:_updateVersion];
                                   BOOL declinedUpdate = [[NSUserDefaults standardUserDefaults] boolForKey:key];
                                   
                                   if ([self _needsUpdateFrom:appVersion to:_updateVersion] && !declinedUpdate)
                                   {
                                       UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Update Available"
                                                                                        message:message
                                                                                       delegate:self
                                                                              cancelButtonTitle:_mandatory ? nil : @"Not now"
                                                                              otherButtonTitles:@"Update!", nil];
                                       if (!_mandatory)
                                       {
                                           [alert addButtonWithTitle:@"Ignore this update"];
                                       }
                                       
                                       [alert show];
                                   }
                                   
                               }
                           }];
}

- (BOOL)_needsUpdateFrom:(NSString*)currentVersion to:(NSString*)newVersion
{
    NSString *strippedCurrent = [currentVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *strippedNew = [newVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    strippedCurrent = [self _string:strippedCurrent byPaddingEndWithZeroToLength:MAX(strippedCurrent.length, strippedNew.length)];
    strippedNew     = [self _string:strippedNew byPaddingEndWithZeroToLength:MAX(strippedCurrent.length, strippedNew.length)];
    
    int current = [strippedCurrent intValue];
    int new = [strippedNew intValue];
    
    return new > current;
}

- (NSString*)_string:(NSString*)string byPaddingEndWithZeroToLength:(NSInteger)length
{
    NSMutableString *newString = [string mutableCopy];
    int numZeros = length - string.length;
    if (numZeros)
    {
        for (int i = 0; i < numZeros; i++)
        {
            [newString appendString:@"0"];
        }
    }
    
    return (NSString*)newString;
}

- (NSString*)_updateDefaultsKeyForVersion:(NSString*)version
{
    return [NSString stringWithFormat:@"%@-%@", kPULUpdateDeclinedKey, version];
}

#pragma mark - alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 || _mandatory)
    {
        // update
        NSURL *url = [NSURL URLWithString:_downloadUrl];
        [[UIApplication sharedApplication] openURL:url];
    }
    else if (buttonIndex == 2)
    {
        // ignore
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[self _updateDefaultsKeyForVersion:_updateVersion]];
    }
}

@end
