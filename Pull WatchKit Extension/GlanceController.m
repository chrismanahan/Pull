//
//  GlanceController.m
//  Pull WatchKit Extension
//
//  Created by admin on 8/14/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "GlanceController.h"

@interface GlanceController()

@property (strong, nonatomic) IBOutlet WKInterfaceImage *compassImage;

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *nameLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *degreeLabel;

@end


@implementation GlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    // find nearest pulled user
//    NSArray *pullsNearby = [PULAccount currentUser].pullsPulledNearby;
//    if (pullsNearby.count > 0)
//    {
//        PULPull *pull = pullsNearby[0];
//        PULUser *friend = [pull otherUser:[PULAccount currentUser]];
//        
//        _nameLabel.text = friend.firstName;
        
        
        
//        [[PULLocationUpdater sharedUpdater] startUpdatingHeadingWithBlock:^(CLHeading *heading) {
//            // update direction of arrow
//            CGFloat degrees = [self p_calculateAngleBetween:[PULAccount currentUser].location.coordinate
//                                                        and:friend.location.coordinate];
//            
//            CGFloat rads = (degrees - heading.trueHeading) * M_PI / 180;
//            
//            _degreeLabel.text = [NSString stringWithFormat:@"%.4f", rads];
//        }];
    
    
//    }
//    else
//    {
//        _nameLabel.text = @"No Nearby Pulls";
//    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    
}

-(CGFloat) p_calculateAngleBetween:(CLLocationCoordinate2D)coords0 and:(CLLocationCoordinate2D)coords1 {
    double myLat = coords0.latitude;
    double myLon = coords0.longitude;
    double yourLat = coords1.latitude;
    double yourLon = coords1.longitude;
    double dx = fabs(myLon - yourLon);
    double dy = fabs(myLat - yourLat);
    
    double ø;
    
    // determine which quadrant we're in relative to other user
    if (dy < 0.0001 && myLon > yourLon) // horizontal right
    {
        return 270;
    }
    else if (dy < 0.0001 && myLon < yourLon) // horizontal left
    {
        return 90;
    }
    else if (dx < 0.0001 && myLat > yourLat) // vertical top
    {
        return 180;
    }
    else if (dx < 0.0001 && myLat < yourLat) // vertical bottom
    {
        return 0;
    }
    else if (myLat > yourLat && myLon > yourLon) // quadrant 1
    {
        ø = atan2(dy, dx);
        return 270 - RADIANS_TO_DEGREES(ø);
    }
    else if (myLat < yourLat && myLon > yourLon) // quad 2
    {
        ø = atan2(dx, dy);
        return 360 - RADIANS_TO_DEGREES(ø);
    }
    else if (myLat < yourLat && myLon < yourLon) // quad 3
    {
        ø = atan2(dx, dy);
    }
    else if (myLat > yourLat && myLon < yourLon) // quad 4
    {
        ø = atan2(dy, dx);
        return 90 + RADIANS_TO_DEGREES(ø);
    }
    return RADIANS_TO_DEGREES( ø);
}

@end



