//
//  PULLoginViewController.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULLoginViewController.h"

#import "PULAccount.h"

#import "PULConstants.h"

#import "PULPullListViewController.h"

#import <Firebase/Firebase.h>
#import <FacebookSDK/FacebookSDK.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface PULLoginViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) Firebase *fireRef;
@property (strong, nonatomic) IBOutlet UIView *movieViewContainer;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *learnMoreButton;

@property (nonatomic, strong) AVQueuePlayer *moviePlayer;

@end

@implementation PULLoginViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _fireRef = [[Firebase alloc] initWithUrl:kPULFirebaseURL];
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
    
    NSMutableArray *vidItems = [[NSMutableArray alloc] init];
    for (int i = 0; i < 5; i++)
    {
        NSString *fileName = [NSString stringWithFormat:@"intro%i", i];
        NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mov"];
        NSURL *movieUrl = [NSURL fileURLWithPath:path];
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:movieUrl];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:item];
        
        [vidItems addObject:item];
        
        
    }
    
    _moviePlayer = [AVQueuePlayer queuePlayerWithItems:vidItems];
    _moviePlayer.muted = YES;
    
    _moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_moviePlayer];

    layer.frame = self.view.bounds;
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [_movieViewContainer.layer addSublayer:layer];
    
//    [_moviePlayer play];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_moviePlayer play];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_moviePlayer pause];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];

    [_moviePlayer advanceToNextItem];
    
    if (_moviePlayer.items.count == 1)
    {
        for (int i = 0; i < 5; i++)
        {
            NSString *fileName = [NSString stringWithFormat:@"intro%i", i];
            NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mov"];
            NSURL *movieUrl = [NSURL fileURLWithPath:path];
            
            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:movieUrl];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:item];
            
            [_moviePlayer insertItem:item afterItem:[[_moviePlayer items] lastObject]];
        }
    }
}

#pragma mark - Actions
- (IBAction)ibPresentFacebookLogin:(id)sender;
{
    PULLog(@"presenting facebook login");
    
    NSArray *permissions = @[@"email", @"public_profile", @"user_friends"];
    
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      PULLog(@"opened active session");
                                      if (error)
                                      {
                                          [PULError handleError:error];
                                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                                                               message:[NSString stringWithFormat:@"There was a problem authenticating: (%li) %@", error.code, error.localizedDescription]
                                                                                              delegate:nil  
                                                                                     cancelButtonTitle:@"Ok"
                                                                                     otherButtonTitles: nil];
                                          [errorAlert show];
                                      }
                                      else
                                      {
                                          NSString *accessToken = session.accessTokenData.accessToken;
                                          
                                          if (!accessToken)
                                          {
                                          }
                                          [[PULAccount currentUser] loginWithFacebookToken:accessToken completion:^(PULAccount *account, NSError *error) {
                                              if (!error)
                                              {
                                                  UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:NSStringFromClass([PULPullListViewController class])];
                                                  
                                                  [self presentViewController:vc animated:YES completion:^{
                                                      ;
                                                  }];
                                              }
                                              else
                                              {
                                                  UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                                                                       message:[NSString stringWithFormat:@"There was a problem logging in: (%li) %@", error.code, error.localizedDescription]
                                                                                                      delegate:nil
                                                                                             cancelButtonTitle:@"Ok"
                                                                                             otherButtonTitles: nil];
                                                  [errorAlert show];
                                              }
                                          }];
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
