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

NSString * const kPULFriendBlockedSomeoneNotification = @"kPULFriendBlockedSomeoneNotification";
NSString * const kPULFriendEnabledAccountNotification = @"kPULFriendEnabledAccountNotification";

@interface PULUser ()

@property (nonatomic, strong) Firebase *fireRef;
@property (nonatomic) FirebaseHandle locationObserverHandle;
@property (nonatomic) FirebaseHandle blockObserverHandle;
@property (nonatomic) FirebaseHandle enableObserverHandle;

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

#pragma mark - observing account
- (void)startObservingAccount
{
    PULLog(@"startin account observers: %@" , self.uid);
    if (!self.settings.isDisabled)
    {
        PULLog(@"starting blocked observer for %@", self.uid);
        
        _fireRef = [[[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:_uid] childByAppendingPath:@"blocked"];
        _blockObserverHandle = [_fireRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            // check if this is me
            if (snapshot.exists)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPULFriendBlockedSomeoneNotification object:snapshot.key];
            }
        }];
    }
    
    PULLog(@"starting enable/disable observer for %@", self.uid);
    
    _fireRef = [[[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:_uid] childByAppendingPath:@"settings"];
    _enableObserverHandle = [_fireRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        // user reenabled their account
        PULLog(@"friend enabled or disabled account");
        [[NSNotificationCenter defaultCenter] postNotificationName:kPULFriendEnabledAccountNotification object:snapshot.key];
    }];
}

- (void)stopObservingAccount
{
    PULLog(@"stopping observer on user account: %@", self.uid);
    [_fireRef removeObserverWithHandle:_blockObserverHandle];
    [_fireRef removeObserverWithHandle:_enableObserverHandle];
}

#pragma mark - observing location
- (void)stopObservingLocationChanges
{
    if (_locationObserverHandle)
    {
        PULLog(@"stopping location observer for %@", self.uid);
        [_fireRef removeObserverWithHandle:_locationObserverHandle];
    }
}

- (void)startObservingLocationChanges
{
    PULLog(@"starting location observer for %@", self.uid);
    
    _fireRef = [[[[[Firebase alloc] initWithUrl:kPULFirebaseURL] childByAppendingPath:@"users"] childByAppendingPath:_uid] childByAppendingPath:@"location"];
    PULLog(@"\t%@", _fireRef);
    
    _locationObserverHandle = [_fireRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
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
    _settings = [[PULUserSettings alloc] initFromFirebase:dict[@"settings"]];
    
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
        CLSLog(@"loading image from cache");
        _image = cached;
        return cached;
    }
    
    // load image from firebase
    NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", self.fbId];
    
    CLSLog(@"Fetching image for user: %@", _uid);
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
                               
                               CLSLog(@"Updated user image");
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
             @"isPrivate": @(_isPrivate),
             @"settings": @{
                     @"isDisabled":@(_settings.isDisabled),
                     @"notification":@{
                             @"invite": @(_settings.notifyInvite),
                             @"accept": @(_settings.notifyAccept)
                             }
                     }};
    
}

#pragma mark - Annotation protocol
- (CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

- (NSString*)title
{
    NSString *fn = _firstName.length > 0 ? [_firstName substringToIndex:1] : @"";
    NSString *ln = _lastName.length > 0 ? [_lastName substringToIndex:1] : @"";
    NSString *initials = [NSString stringWithFormat:@"%@%@", fn, ln];
    return initials;
}

@end
