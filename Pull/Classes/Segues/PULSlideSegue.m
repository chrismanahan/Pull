//
//  PULSlideSegue.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULSlideSegue.h"

@implementation PULSlideSegue

- (void)perform
{
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // Add the destination view as a subview, temporarily
    UIView *destView = [destinationViewController.view snapshotViewAfterScreenUpdates:YES];
    CGRect frame = destView.frame;
    CGRect origFrame = frame;
    frame.origin.x = -CGRectGetWidth(sourceViewController.view.frame);
    if (_slideLeft)
    {
        frame.origin.x = CGRectGetWidth(sourceViewController.view.frame);
    }
    destView.frame = frame;
    [sourceViewController.view addSubview:destView];
    
    
//    destinationViewController.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(sourceViewController.view.frame), 0);

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:0
                     animations:^{
                         CGFloat x = CGRectGetWidth(sourceViewController.view.bounds);
                         if (_slideLeft)
                         {
                             x = -x;
                         }
                         CGAffineTransform slide = CGAffineTransformMakeTranslation(x, 0);
                         sourceViewController.view.transform = slide;
                     }
                     completion:^(BOOL finished){
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL]; // present VC
                         });
                         
//                         [destView removeFromSuperview]; // remove from temp super view
//                         destView.frame = origFrame;
                     }];
}


@end
