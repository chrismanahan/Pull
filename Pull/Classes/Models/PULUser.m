//
//  PULUser.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULCache.h"

#import <UIKit/UIKit.h>

#import <Firebase/Firebase.h>
#import <CoreLocation/CoreLocation.h>

@interface PULUser ()

@property (nonatomic, strong) Firebase *fireRef;

@end

@implementation PULUser

#pragma mark - Initialization
- (instancetype)initFromFirebaseData:(NSDictionary*)dictionary uid:(NSString*)uid
{
    NSParameterAssert(dictionary);
    
    if (self = [super init])
    {
        _uid = uid;
        [self p_loadPropertiesFromDictionary:dictionary];
        
        // TODO: observing user changes does not seem to be working
        [self startObservingChanges];
    }
    
    return self;
}

- (void)startObservingChanges
{
    [_fireRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *data = snapshot.value;
        
        [self p_loadPropertiesFromDictionary:data];
        
        if ([_delegate respondsToSelector:@selector(userDidRefresh:)])
        {
            [_delegate userDidRefresh:self];
        }
    }];
}

#pragma mark - Private
- (void)p_loadPropertiesFromDictionary:(NSDictionary*)dict
{
    _fbId        = dict[@"fbId"];
    _email       = dict[@"email"];
    _phoneNumber = dict[@"phoneNumber"];
    _firstName   = dict[@"firstName"];
    _lastName    = dict[@"lastName"];
    _isPrivate   = [dict[@"isPrivate"] boolValue];
    
    _deviceToken = dict[@"deviceToken"];
    
    NSDictionary *loc = dict[@"location"];
    double lat        = [loc[@"lat"] doubleValue];
    double lon        = [loc[@"lon"] doubleValue];
    double alt        = [loc[@"alt"] doubleValue];
    
    CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(lat, lon);
    _location = [[CLLocation alloc] initWithCoordinate:coords
                                              altitude:alt
                                    horizontalAccuracy:kCLLocationAccuracyNearestTenMeters
                                      verticalAccuracy:kCLLocationAccuracyNearestTenMeters
                                             timestamp:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    
}

#pragma mark - Properties
- (NSString*)fullName
{
    return [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
}

- (UIImage*)image
{
    if (_image)
    {
        return _image;
    }
    
    // check cache
    NSString *cacheKey = [NSString stringWithFormat:@"UserImage%@", _uid];
    UIImage *cached = [[PULCache sharedCache] objectForKey:cacheKey];
    if (cached)
    {
        PULLog(@"loading image from cache");
        _image = cached;
        return cached;
    }
    
    // load image from firebase
    NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", self.fbId];
    
    PULLog(@"Fetching image for user: %@", _uid);
    NSURL *url = [NSURL URLWithString:userImageURL];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               _image = [UIImage imageWithData:data];
                               
                               if (!_image)
                               {
                                   _image = [UIImage imageNamed:@"userPlaceholder.jpg"];
                               }
                               
                               // set cache
                               [[PULCache sharedCache] setObject:_image forKey:cacheKey];
                               
                               PULLog(@"Updated user image");
                               if ([_delegate respondsToSelector:@selector(userDidRefresh:)])
                               {
                                   [_delegate userDidRefresh:self];
                               }
                           }];
    return nil;
}

#pragma mark - Overrides
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PULUser class]])
    {
        PULUser *otherUser = object;
        
        if ([otherUser.uid isEqualToString:self.uid])
        {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Firebase Protocol
- (NSDictionary*)firebaseRepresentation
{
    return @{@"fbId": _fbId ?: @"",
             @"email": _email ?: @"",
             @"phoneNumber": _phoneNumber ?: @"",
             @"firstName": _firstName ?: @"",
             @"lastName": _lastName ?: @"",
             @"location":@{@"lat": @(_location.coordinate.latitude),
                      @"lon": @(_location.coordinate.longitude),
                      @"alt": @(_location.altitude)},
             @"isPrivate": @(_isPrivate)};
    
}

@end
