//
//  PULSlideUnwindSegue.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULSlideUnwindSegue.h"

@implementation PULSlideUnwindSegue

- (void)perform
{
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // Add the destination view as a subview, temporarily
    UIView *destView = destinationViewController.view;
    CGRect frame = destView.frame;
    CGRect origFrame = frame;
    frame.origin.x = CGRectGetWidth(sourceViewController.view.frame);
    destView.frame = frame;
    [sourceViewController.view.superview insertSubview:destView atIndex:0];
    
    
    //    destinationViewController.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(sourceViewController.view.frame), 0);
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         sourceViewController.view.transform = CGAffineTransformMakeTranslation(-CGRectGetWidth(sourceViewController.view.frame), 0);
                         
                         destView.transform = CGAffineTransformMakeTranslation(0, 0);
                     }
                     completion:^(BOOL finished){

                         [destView removeFromSuperview]; // remove from temp super view
                         destView.frame = origFrame;
                         
                         [sourceViewController dismissViewControllerAnimated:NO completion:NULL];

                     }];
}



@end
