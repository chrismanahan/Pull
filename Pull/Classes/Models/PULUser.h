//
//  PULUser.h
//  Pull
//
//  Created by Chris Manahan on 11/6/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PULFirebaseProtocol.h"

#import <MapKit/MapKit.h>

@class PULUser;
@class CLLocation;
@class UIImage;

/**
 *  Notifcation sent when a single user is updated. The object with the notif is the updated user
 */
extern NSString * const kPULFriendUpdatedNotifcation;

//@protocol PULUserDelegate <NSObject>
//
///**
// *  Called when something, usually location, is updated
// *
// *  @param user User
// */
//- (void)userDidRefresh:(PULUser*)user;
//
//@end

@interface PULUser : NSObject <PULFirebaseProtocol, MKAnnotation>

/*******************************
        Properties
 ******************************/
//@property (nonatomic, strong) id <PULUserDelegate> delegate;

@property (nonatomic, strong) NSString *uid;

@property (nonatomic, strong) NSString *fbId;

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *email;

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *fullName;

@property (nonatomic, strong) NSString *deviceToken;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, assign) BOOL isPrivate;

/*******************************
        Instance Methods
 ******************************/

/**
 *  Instantiates a new user from a dictionary retrieved from the user's endpoint on firebase
 *
 *  @param dictionary Dictionary of data
 *
 *  @return User
 */
- (instancetype)initFromFirebaseData:(NSDictionary*)dictionary uid:(NSString*)uid;

- (void)startObservingLocationChanges;
- (void)stopObservingLocationChanges;


@end
