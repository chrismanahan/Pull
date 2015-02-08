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
    UIView *destView = destinationViewController.view;
    CGRect frame = destView.frame;
    CGRect origFrame = frame;
    frame.origin.x = -CGRectGetWidth(sourceViewController.view.frame);
    destView.frame = frame;
    [sourceViewController.view addSubview:destView];
    
    
//    destinationViewController.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(sourceViewController.view.frame), 0);

    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGAffineTransform slide = CGAffineTransformMakeTranslation(CGRectGetWidth(sourceViewController.view.bounds), 0);
//                         destView.transform = slide;
                         sourceViewController.view.transform = slide;
                     }
                     completion:^(BOOL finished){
                         [destView removeFromSuperview]; // remove from temp super view
                         [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL]; // present VC
                         
                         destView.frame = origFrame;
                     }];
}


@end
