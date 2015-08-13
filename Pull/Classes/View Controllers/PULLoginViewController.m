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

#import "PULAccount.h"

#import "PULConstants.h"

#import <Firebase/Firebase.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface PULLoginViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *movieViewContainer;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *learnMoreButton;

//@property (nonatomic, strong) AVQueuePlayer *moviePlayer;
@property (nonatomic, strong) AVPlayer *moviePlayer;

@end

@implementation PULLoginViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    NSDictionary *strokeAttributes = @{
                                       NSStrokeWidthAttributeName: @(-1),
                                       NSStrokeColorAttributeName:[UIColor blackColor],
                                       NSForegroundColorAttributeName:[UIColor whiteColor]
                                       };
    // stroke subtitle label
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:_subtitleLabel.text
                                                                attributes:strokeAttributes];
    _subtitleLabel.attributedText = title;
//
//    // stroke learn more button
//    title = [[NSAttributedString alloc] initWithString:_learnMoreButton.titleLabel.text attributes:strokeAttributes];
//    [_learnMoreButton setAttributedTitle:title forState:UIControlStateNormal];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
//    NSMutableArray *vidItems = [[NSMutableArray alloc] init];
//    for (int i = 0; i < 5; i++)
//    {
//        NSString *fileName = [NSString stringWithFormat:@"intro%i", i];
//        NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mov"];
//        NSURL *movieUrl = [NSURL fileURLWithPath:path];
//        
//        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:movieUrl];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(playerItemDidReachEnd:)
//                                                     name:AVPlayerItemDidPlayToEndTimeNotification
//                                                   object:item];
//        
//        [vidItems addObject:item];
//        
//        
//    }
    
//    _moviePlayer = [AVQueuePlayer queuePlayerWithItems:vidItems];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"intro2" ofType:@"mov"];
    NSURL *movieUrl = [NSURL fileURLWithPath:path];
//    _moviePlayer = [AVPlayer playerWithURL:movieUrl];
//    _moviePlayer.muted = YES;
//    
//    _moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                                      selector:@selector(playerItemDidReachEnd:)
//                                                          name:AVPlayerItemDidPlayToEndTimeNotification
//                                                        object:[_moviePlayer currentItem]];
//
//    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_moviePlayer];
//
//    layer.frame = self.view.bounds;
//    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    
//    [_movieViewContainer.layer addSublayer:layer];

}

- (void)viewWillAppear:(BOOL)animated
{
//    [_moviePlayer play];
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [_moviePlayer pause];
}

#pragma mark - avplayer notifications
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    
//    [_moviePlayer advanceToNextItem];
//    
//    if (_moviePlayer.items.count == 1)
//    {
//        for (int i = 0; i < 5; i++)
//        {
//            NSString *fileName = [NSString stringWithFormat:@"intro%i", i];
//            NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mov"];
//            NSURL *movieUrl = [NSURL fileURLWithPath:path];
//            
//            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:movieUrl];
//            
//            [[NSNotificationCenter defaultCenter] addObserver:self
//                                                     selector:@selector(playerItemDidReachEnd:)
//                                                         name:AVPlayerItemDidPlayToEndTimeNotification
//                                                       object:item];
//            
//            [_moviePlayer insertItem:item afterItem:[[_moviePlayer items] lastObject]];
//        }
//    }
}

#pragma mark - Actions
- (IBAction)ibPresentFacebookLogin:(id)sender;
{
    PULLog(@"presenting facebook login");
    
    NSArray *permissions = @[@"email", @"public_profile", @"user_friends"];
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    login.loginBehavior = FBSDKLoginBehaviorSystemAccount;
    [login logInWithReadPermissions:permissions
                            handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                if (error)
                                {
                                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                                                         message:[NSString stringWithFormat:@"There was a problem authenticating: (%li) %@", (long)error.code, error.localizedDescription]
                                                                                        delegate:nil
                                                                               cancelButtonTitle:@"Ok"
                                                                               otherButtonTitles: nil];
                                    [errorAlert show];
                                }
                                else if (result.isCancelled)
                                {
                                    // login canceled, can't do anything
                                    ;
                                }
                                else
                                {
                                    NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:result.token];
                                    
                                    [[NSUserDefaults standardUserDefaults] setObject:tokenData forKey:@"FBToken"];
                                    [PULAccount loginWithFacebookToken:result.token completion:nil];
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
                            }];
}

- (IBAction)ibLearnMore:(id)sender
{
    [_scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.view.frame), 0) animated:YES];
}

#pragma mark - scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x / CGRectGetWidth(self.view.frame);
    _pageControl.currentPage = page;
}

@end
