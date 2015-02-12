//
//  PULReverseModal.m
//  Pull
//
//  Created by Chris Manahan on 2/12/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULReverseModal.h"

@implementation PULReverseModal

- (void)perform
{
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // Add the destination view as a subview, temporarily
    UIView *destView = [destinationViewController.view snapshotViewAfterScreenUpdates:YES];
    destView.frame = sourceViewController.view.frame;
    [sourceViewController.view.superview insertSubview:destView belowSubview:sourceViewController.view];

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:0
                     animations:^{
                         CGAffineTransform slide = CGAffineTransformMakeTranslation(0, CGRectGetHeight(sourceViewController.view.frame));
                         sourceViewController.view.transform = slide;
                     }
                     completion:^(BOOL finished){
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL]; // present VC
                         });

                     }];
}


@end
