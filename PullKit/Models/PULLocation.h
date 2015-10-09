//
//  PULLocation.h
//  Pull
//
//  Created by Chris Manahan on 9/23/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import <Parkour/parkour.h>
#import <Parse/Parse.h>

#import "PFObject+Subclass.h"

@class PULUser;

/*!
 *  PULLocation represents all the location information as it relates to a single user
 */
@interface PULLocation : PFObject <PFSubclassing>

/*****************************
 Properties
 *****************************/
@property (nonatomic, strong) PFGeoPoint *coordinate;
/*!
 *  Altitude
 */
@property (nonatomic) CGFloat alt;
/*!
 *  Location accuracy
 */
@property (nonatomic) CGFloat accuracy;
/*!
 *  Course of direction
 */
@property (nonatomic) CLLocationDirection course;
/*!
 *  Current moving speed
 */
@property (nonatomic) CLLocationSpeed speed;
/*!
 *  Most recent type of movment
 */
@property (nonatomic) PKMotionType movementType;
/*!
 *  Best guess of most recent position
 */
@property (nonatomic) PKPositionType positionType;

#pragma mark - Calculated properties

/*!
 *  CLLocation object of lat/lon and accuracy
 */
@property (nonatomic, strong, readonly) CLLocation *location;

@property (nonatomic, getter=isLowAccuracy, readonly) BOOL lowAccuracy;

/*****************************
 Instance Methods
 *****************************/

- (CGFloat)distanceInMeters:(PULLocation*)location;

/*****************************
 Class Methods
 *****************************/
+ (NSString*)parseClassName;

@end
