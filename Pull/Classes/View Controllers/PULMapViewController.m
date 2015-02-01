//
//  PULMapViewController.m
//  Pull
//
//  Created by Chris Manahan on 1/31/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULMapViewController.h"

#import "PULAccount.h"

#import <MapKit/MapKit.h>

@interface PULMapViewController () <MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIButton *orientButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) id <NSObject> locationUpdateNotif;

@property (nonatomic, assign) BOOL isOriented;

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
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _mapView && [keyPath isEqualToString:@"userTrackingMode"])
    {
        if (_mapView.userTrackingMode == MKUserTrackingModeNone && _isOriented)
        {
            [self ibOrient:nil];
        }
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

- (IBAction)ibOrient:(id)sender
{
    _isOriented = !_isOriented;
    
    NSString *title;
    if (_isOriented)
    {
        title = @"Stop Map Orientation";
        [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    }
    else
    {
        title = @"Orient The Map";
        [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
    
    [_orientButton setTitle:title forState:UIControlStateNormal];
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
        
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, 60, 60)];
        lbl.font = [UIFont fontWithName:@"Avenir-Roman" size:40];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor colorWithRed:0.537 green:0.184 blue:1.000 alpha:1.000];
        lbl.text = [annotation title];
        [lbl sizeToFit];
        // adjust label center
        CGPoint center = lbl.center;
        CGFloat xOffset = abs(CGRectGetWidth(lbl.frame) - CGRectGetWidth(annotationView.frame));
        xOffset /= 2;
        center.x += xOffset;
        lbl.center = center;
        
        [annotationView addSubview:lbl];
        
        annotationView.centerOffset = CGPointMake(0, - annotationView.image.size.height / 2);
    
        return annotationView;
    }
    return nil;
}

@end
