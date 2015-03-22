//
//  PULMapViewController.m
//  Pull
//
//  Created by Chris Manahan on 1/31/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULMapViewController.h"

#import "PULAccount.h"

#import "PULUserImageView.h"
#import "PULUserScrollView.h"

#import <MapKit/MapKit.h>

@interface PULMapViewController () <MKMapViewDelegate, UIAlertViewDelegate, PULUserScrollViewDataSource>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *mapTopConstraint;
@property (strong, nonatomic) id <NSObject> locationUpdateNotif;

@property (nonatomic, strong) IBOutlet PULUserScrollView *userScrollView;
@property (nonatomic, strong) IBOutlet UIButton *userLocationButton;

@end

@implementation PULMapViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _mapView.delegate = self;
    
    [_mapView showAnnotations:@[_user] animated:YES];
    
    
    _locationUpdateNotif = [[NSNotificationCenter defaultCenter] addObserverForName:kPULFriendUpdatedNotifcation
                                                      object:_user
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [_mapView removeAnnotation:_user];
                                                      [_mapView addAnnotation:_user];
                                                  }];
    
    [_mapView addObserver:self forKeyPath:@"userTrackingMode" options:NSKeyValueObservingOptionNew context:NULL];

    _nameLabel.text = _user.fullName;
    
    if (_user.settings.resolveAddress)
    {
        _addressLabel.text = _user.address;
        [_user addObserver:self
                forKeyPath:@"address"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];
    }
    else
    {
        _mapTopConstraint.constant = -CGRectGetHeight(_addressLabel.frame);
        [self.view layoutSubviews];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [_userScrollView reload];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _user && [keyPath isEqualToString:@"address"])
    {
        _addressLabel.text = _user.address;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_locationUpdateNotif];
}

#pragma mark - actions
- (IBAction)ibClose:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)ibDirections:(id)sender
{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Directions"
                                                    message:@"Open your friend's current address using..."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Apple Maps", nil];
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([app canOpenURL:[self _googleMapUrl]])
    {
        [alert addButtonWithTitle:@"Google Maps"];
    }
    
    if ([app canOpenURL:[self _wazeUrl]])
    {
        [alert addButtonWithTitle:@"Waze"];
    }
    
    [alert show];
}

- (NSURL*)_appleMapUrl
{
    NSString *friendCoords = [NSString stringWithFormat:@"%.7f,%.7f", _user.location.coordinate.latitude, _user.location.coordinate.longitude];
    
    NSString *urlString = [NSString stringWithFormat:@"http://maps.apple.com?daddr=%@", friendCoords];
    //    NSString *urlString = [NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", myCoords, friendCoords];
    return [NSURL URLWithString:urlString];
}


- (NSURL*)_googleMapUrl
{
    NSString *friendCoords = [NSString stringWithFormat:@"%.7f,%.7f", _user.location.coordinate.latitude, _user.location.coordinate.longitude];
    
    NSString *urlString = [NSString stringWithFormat:@"comgooglemaps://?daddr=%@", friendCoords];
//    NSString *urlString = [NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", myCoords, friendCoords];
    return [NSURL URLWithString:urlString];
}

- (NSURL*)_wazeUrl
{
    NSString *friendCoords = [NSString stringWithFormat:@"%.7f,%.7f", _user.location.coordinate.latitude, _user.location.coordinate.longitude];
    
    NSString *urlString = [NSString stringWithFormat:@"waze://?ll=%@&navigate=yes", friendCoords];
    return [NSURL URLWithString:urlString];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([title isEqualToString:@"Apple Maps"])
    {
        [app openURL:[self _appleMapUrl]];
    }
    else if ([title isEqualToString:@"Waze"])
    {
     [app openURL:[self _wazeUrl]];
    }
    else if ([title isEqualToString:@"Google Maps"])
    {
     [app openURL:[self _googleMapUrl]];
    }
}

#pragma mark MKMapView delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapview viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    static NSString* AnnotationIdentifier = @"AnnotationIdentifier";
    MKAnnotationView *annotationView = [mapview dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    if(annotationView)
    {
        return annotationView;
    }
    else
    {
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                         reuseIdentifier:AnnotationIdentifier];
        annotationView.image = [UIImage imageNamed:@"map_pin"];
        annotationView.contentMode = UIViewContentModeScaleAspectFit;
        annotationView.canShowCallout = NO;
        
//        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, 60, 60)];
//        lbl.font = [UIFont fontWithName:@"Avenir-Black" size:30];
//        lbl.textAlignment = NSTextAlignmentCenter;
//        lbl.textColor = [UIColor whiteColor];
//        lbl.text = [annotation title];
//        [lbl sizeToFit];
        PULUserImageView *imageView = [[PULUserImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.hasBorder = NO;
        imageView.imageView.image = ((PULUser*)annotation).image;

        // adjust label center
        CGPoint center = imageView.center;
        CGFloat xOffset = abs(CGRectGetWidth(imageView.frame) - CGRectGetWidth(annotationView.frame));
        xOffset /= 2;
        center.x += xOffset;
        
        CGFloat yOffset = abs(CGRectGetHeight(imageView.frame) - CGRectGetHeight(annotationView.frame));
        yOffset /= 4;
        center.y += yOffset + 1;
        
        imageView.center = center;
        
        [annotationView addSubview:imageView];
        
        annotationView.centerOffset = CGPointMake(0, - annotationView.image.size.height / 2);
    
        return annotationView;
    }
    return nil;
}

#pragma mark - User scroll view data source
- (NSInteger)numberOfUsersInUserScrollView:(PULUserScrollView *)userScrollView
{
    return [PULAccount currentUser].friendManager.pulledFriends.count;
}

- (PULUser*)userForIndex:(NSInteger)index isActive:(BOOL*)active userScrollView:(PULUserScrollView *)userScrollView
{
    NSInteger i = [PULAccount currentUser].friendManager.pulledFriends.count - index - 1;
    
    PULUser *user = [PULAccount currentUser].friendManager.pulledFriends[i];
    
    *active = user == _user;
    
    return user;
}

- (UIEdgeInsets)insetsForUserScrollView:(PULUserScrollView *)userScrollView
{
    return UIEdgeInsetsMake(0, 0, 0, CGRectGetWidth(_userLocationButton.frame) + kPULUserScrollViewPadding);
}

- (CGSize)cellSizeForUserScrollView:(PULUserScrollView *)userScrollView
{
    return CGRectInset(_userLocationButton.frame, kPULUserScrollViewPadding / 4, kPULUserScrollViewPadding / 4).size;
}

@end
