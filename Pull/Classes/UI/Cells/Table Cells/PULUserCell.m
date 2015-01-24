//
//  PULUserCell.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUserCell.h"

#import "PULAccount.h"

#import "PULConstants.h"

@interface PULUserCell ()

@property (nonatomic, strong) id userUpdatedObserver;

@property (nonatomic, strong) id accountLocationUpdatedObserver;

@end

@implementation PULUserCell

- (void)setUser:(PULUser *)user
{
    // set ui
    _userImageView.image = user.image;
    _userDisplayNameLabel.text = user.fullName;
    
    if (_userDistanceLabel)
    {
        CGFloat distance = [[PULAccount currentUser].location distanceFromLocation:user.location];
        
        [self p_updateDistanceLabel:distance];
    }

    _user = user;
    
    // subscribe to notifications
    if (_userUpdatedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_userUpdatedObserver];
        _userUpdatedObserver = nil;
    }
    if (_accountLocationUpdatedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_accountLocationUpdatedObserver];
        _accountLocationUpdatedObserver = nil;
    }
    
    // start observing updates from this user
    _userUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kPULFriendUpdatedNotifcation
                                                                             object:user
                                                                              queue:[NSOperationQueue currentQueue]
                                                                         usingBlock:^(NSNotification *note) {
                                                                             // set updated user
                                                                             self.user = [note object];
                                                                         }];
    
    if (_userDistanceLabel)
    {
        _accountLocationUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kPULAccountDidUpdateLocationNotification
                                                                                          object:nil
                                                                                           queue:[NSOperationQueue mainQueue]
                                                                                      usingBlock:^(NSNotification *note) {
                                                                                          // update distance label
                                                                                          
                                                                                          CLLocation *loc = [note object];
                                                 
                                                                                          CGFloat distance = [loc distanceFromLocation:_user.location];
                                                                                          
                                                                                          [self p_updateDistanceLabel:distance];
                                                                                          
                                                                                      }];
    }
}

- (void)p_updateDistanceLabel:(CGFloat)distance
{
    CGFloat convertedDistance;
    NSString *unit, *formatString;
    // TODO: localize distance
    if (distance < kPULDistanceUnitCutoff)
    {
        // distance as ft
        convertedDistance = METERS_TO_FEET(distance);
        unit = @"ft";
        formatString = @"%i %@";
    }
    else
    {
        // distance as miles
        convertedDistance = METERS_TO_MILES(distance);
        unit = @"miles";
        formatString = @"%.2f %@";
    }
    
    NSString *string = [NSString stringWithFormat:@"%.2f %@", convertedDistance, unit];
    
    _userDistanceLabel.text = string;
}

@end
