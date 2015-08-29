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
    if (_slideRight)
    {
        frame.origin.x = -CGRectGetWidth(sourceViewController.view.frame);
    }
    destView.frame = frame;
    [sourceViewController.view.superview insertSubview:destView atIndex:0];
    
    
    //    destinationViewController.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(sourceViewController.view.frame), 0);
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:0
                     animations:^{
                         CGFloat x = _slideRight ? CGRectGetWidth(sourceViewController.view.frame) : -CGRectGetWidth(sourceViewController.view.frame);
                         sourceViewController.view.transform = CGAffineTransformMakeTranslation(x, 0);
                         
                         destView.transform = CGAffineTransformMakeTranslation(0, 0);
                     }
                     completion:^(BOOL finished){
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [sourceViewController dismissViewControllerAnimated:NO completion:NULL];
                             [destView removeFromSuperview];
                         });
                         
//                         [destView removeFromSuperview]; // remove from temp super view
//                         destView.frame = origFrame;
                     }];
}



@end
