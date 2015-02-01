//
//  PULUser.m
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUser.h"

#import "PULCache.h"

#import "PULConstants.h"

#import <UIKit/UIKit.h>

#import <Firebase/Firebase.h>
#import <CoreLocation/CoreLocation.h>

NSString * const kPULFriendUpdatedNotifcation      = @"kPULAccountFriendUpdatedNotifcation";

@interface PULUser ()

@property (nonatomic, strong) Firebase *fireRef;
@property (nonatomic) FirebaseHandle observerHandle;

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
//        [self startObservingLocationChanges];
    }
    
    return self;
}

- (void)stopObservingLocationChanges
{
    if (_observerHandle)
    {
        PULLog(@"stopping location observer for %@", self.fullName);
        [_fireRef removeObserverWithHandle:_observerHandle];
    }
}

- (void)startObservingLocationChanges
{
    PULLog(@"starting location observer for %@", self.fullName);
    
    _fireRef = [[[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:_uid] childByAppendingPath:@"location"];
    
    _observerHandle = [_fireRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        NSDictionary *loc = snapshot.value;
        
        if (![loc isKindOfClass:[NSNull class]])
        {
            PULLog(@"user (%@) updated location", self.fullName);
            
            double lat        = [loc[@"lat"] doubleValue];
            double lon        = [loc[@"lon"] doubleValue];
            double alt        = [loc[@"alt"] doubleValue];
            
            CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(lat, lon);
            _location = [[CLLocation alloc] initWithCoordinate:coords
                                                       altitude:alt
                                            horizontalAccuracy:kCLLocationAccuracyNearestTenMeters
                                              verticalAccuracy:kCLLocationAccuracyNearestTenMeters
                                                     timestamp:[NSDate dateWithTimeIntervalSinceNow:0]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPULFriendUpdatedNotifcation object:self];
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
                                   _image = [UIImage imageNamed:@"userPlaceholder.png"];
                               }
                               
                               // set cache
                               if (_image)
                               {
                                   [[PULCache sharedCache] setObject:_image forKey:cacheKey];
                               }
                               
                               PULLog(@"Updated user image");
                               [[NSNotificationCenter defaultCenter] postNotificationName:kPULFriendUpdatedNotifcation object:self];
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

- (NSString*)description
{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"%p", self], _uid,
                                                                 self.fullName, @{@"lat": @(_location.coordinate.latitude),
                                                                                  @"lon": @(_location.coordinate.longitude),
                                                                                  @"alt": @(_location.altitude)}] forKeys:@[@"user", @"uid", @"fullName", @"loc"]];
    
    return dict.description;
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

#pragma mark - Annotation protocol
- (CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

- (NSString*)title
{
    return self.firstName;
}

@end
