//
//  PULLoginViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULLoginViewController.h"
#import "PULRequestLocationViewController.h"
#import "PULPullListViewController.h"

#import "PULSlideLeftSegue.h"

#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface PULLoginViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation PULLoginViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
    }
    return self;
}

#pragma mark - Actions
- (IBAction)ibPresentFacebookLogin:(id)sender;
{
    [[PULParseMiddleMan sharedInstance] loginWithFacebook:^(BOOL success, NSError * _Nullable error) {
        if (success)
        {
            // check if we already have location/notifcation permissions
            BOOL grantedPermissions = [[NSUserDefaults standardUserDefaults] boolForKey:@"DidGrantPermissions"];
            
            if (!grantedPermissions)
            {
                // show permission request vc
                UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULRequestLocationViewController class])];
                
                PULSlideLeftSegue *seg = [PULSlideLeftSegue segueWithIdentifier:@"RequestLocationSeg"
                                                                         source:self
                                                                    destination:vc
                                                                 performHandler:^{
                                                                     ;
                                                                 }];
                [seg perform];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DidGrantPermissions"];
            }
            else
            {
                UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullListViewController class])];
                
                [self presentViewController:vc animated:YES completion:^{
                    ;
                }];
            }
        }
        else
        {
            PULLog(@"failed to initialize: %@", error);
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                                 message:[NSString stringWithFormat:@"There was a problem authenticating: (%li) %@", (long)error.code, error.localizedDescription]
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles: nil];
            [errorAlert show];

        }
    }];
}

#pragma mark - scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / CGRectGetWidth(self.view.frame);
    _pageControl.currentPage = page;
}

@end
