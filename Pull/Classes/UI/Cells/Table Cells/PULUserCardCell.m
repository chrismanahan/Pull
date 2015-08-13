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

#import "PULPullOptionsOverlay.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerSharer+Internal.h>

@import QuartzCore;

@interface PULUserCardCell ()

@property (nonatomic, strong) id userUpdatedObserver;

@property (nonatomic, strong) id accountLocationUpdatedObserver;

@property (nonatomic, strong) PULUser *user;

@property (strong, nonatomic) IBOutlet UIView *bottomButtonContainer;
@property (weak, nonatomic) IBOutlet UIView *mainContainer;

@end

@implementation PULUserCardCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _mainContainer.layer.shadowOffset = CGSizeMake(0, 1);
    _mainContainer.layer.shadowRadius = 2.0;
    _mainContainer.layer.shadowOpacity = 1.0;
    _mainContainer.layer.masksToBounds = NO;
}

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
            _durationButton.hidden = YES;
            // who sent the pull?
            if ([_pull initiatedBy:[PULAccount currentUser]])
            {
                // we sent this pull
                _accessoryLabel.text = @"Pending...";
                _accentLine.backgroundColor = [UIColor colorWithWhite:0.721 alpha:1.000];
                
                _cancelButton.hidden = NO;
                _bottomButtonContainer.hidden = YES;
                _durationButton.hidden = YES;
            }
            else
            {
                // the other user sent this pull
                if (_pull.duration != kPullDurationAlways)
                {
                    _accessoryLabel.text = [NSString stringWithFormat:@"Would like to pull you for %li hours", (long)_pull.durationHours];
                }
                else
                {
                    _accessoryLabel.text = @"Would like to always be pulled with you";
                }
                
                _accentLine.backgroundColor = PUL_Purple;
                
                _bottomButtonContainer.hidden = NO;
                _cancelButton.hidden = YES;
            }
            break;
        }
        case PULPullStatusPulled:
        {
            _cancelButton.hidden = YES;
            _bottomButtonContainer.hidden = YES;
            _durationButton.hidden = NO;
            // is the user nearby?
            CGFloat distance = [_user.location distanceFromLocation:[PULAccount currentUser].location];
            
            if (distance <= kPULNearbyDistance)
            {
                CGFloat convertedDistance = METERS_TO_FEET(distance);
                _accessoryLabel.text = [NSString stringWithFormat:@"%.2f Feet", convertedDistance];
                _accentLine.backgroundColor = PUL_Blue;
                
            }
            else
            {
                _accessoryLabel.text = @"Not nearby";
                _accentLine.backgroundColor = [UIColor redColor];
            }
            
            // title for duration button
            NSString *durationTitle;
            NSString *durationButtonName;
            if (_pull.duration == kPullDurationAlways)
            {
                durationTitle = @"Always";
                durationButtonName = @"star_icon";
            }
            else
            {
                durationTitle = [NSString stringWithFormat:@"%zd hours", _pull.durationHours];
                durationButtonName = @"clock_icon";
            }
            
            [_durationButton setImage:[UIImage imageNamed:durationButtonName] forState:UIControlStateNormal];
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
    
    [_userImageViewContainer setImage:_user.image forObject:_user];
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

- (IBAction)ibOptions:(id)sender
{
    UIView *v = self;
    while (v && ![v isKindOfClass:[UITableView class]])
    {
        v = v.superview;
    }
    v = v.superview;
    
    [PULPullOptionsOverlay overlayOnView:v withPull:_pull];
}

@end
