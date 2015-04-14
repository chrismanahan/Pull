//
//  PULUserCell.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULUserCardCell.h"

#import "PULAccount.h"

#import "PULConstants.h"

@interface PULUserCardCell ()

@property (nonatomic, strong) id userUpdatedObserver;

@property (nonatomic, strong) id accountLocationUpdatedObserver;

@property (nonatomic, strong) PULUser *user;

@end

@implementation PULUserCardCell

- (void)setPull:(PULPull *)pull
{
    _pull = pull;
    
    // get other user that is involved in this pull
    _user = [pull otherUser:[PULAccount currentUser]];
    
    _accountLocationUpdatedObserver = [THObserver observerForObject:[PULAccount currentUser]
                                                            keyPath:@"location"
                                                             target:self
                                                             action:@selector(loadUI)];
    
    _userUpdatedObserver = [THObserver observerForObject:_user
                                                 keyPath:@"location"
                                                  target:self
                                                  action:@selector(loadUI)];
}

#pragma mark - public
- (void)loadUI;
{
    NSAssert(_pull && _user, @"Pull and user of cell must be set before loading UI");
    
    switch (_pull.status) {
        case PULPullStatusPending:
        {
            // who sent the pull?
            if ([_pull initiatedBy:[PULAccount currentUser]])
            {
                // we sent this pull
                _accessoryLabel.text = @"Pending...";
            }
            else
            {
                // the other user sent this pull
                if (_pull.duration != kPullDurationAlways)
                {
                    _accessoryLabel.text = [NSString stringWithFormat:@"Would like to pull you for %i hours", _pull.durationHours];
                }
                else
                {
                    _accessoryLabel.text = @"Would like to always be pulled with you";
                }
            }
            break;
        }
        case PULPullStatusPulled:
        {
            // is the user nearby?
            CGFloat distance = [_user.location distanceFromLocation:[PULAccount currentUser].location];
            
            if (distance <= kPULNearbyDistance)
            {
                CGFloat convertedDistance = METERS_TO_FEET(distance);
                _accessoryLabel.text = [NSString stringWithFormat:@"%.2f Feet", convertedDistance];
                
            }
            else
            {
                _accessoryLabel.text = @"Not nearby";
            }
            
            // title for duration button
            NSString *durationTitle;
            if (_pull.duration == kPullDurationAlways)
            {
                durationTitle = @"Always";
            }
            else
            {
                durationTitle = [NSString stringWithFormat:@"%zd hours", _pull.durationHours];
            }
            
            [_durationButton setTitle:durationTitle forState:UIControlStateNormal];
            
            break;
        }
        case PULPullStatusExpired:
        case PULPullStatusNone:
        {
            break;
        }
    }
    
    // basic user info
    _nameLabel.text = _user.fullName;
    
    
}


#pragma mark - Actions
- (IBAction)ibDecline:(id)sender
{
    [[PULAccount currentUser] cancelPull:_pull];
}

- (IBAction)ibAccept:(id)sender
{
    [[PULAccount currentUser] acceptPull:_pull];
}
- (IBAction)ibCancel:(id)sender
{
    [[PULAccount currentUser] cancelPull:_pull];
}

@end
