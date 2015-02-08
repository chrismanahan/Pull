//
//  PULNavigationController.m
//  Pull
//
//  Created by Chris Manahan on 2/7/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULNavigationController.h"

#import "PULSlideUnwindSegue.h"

@interface PULNavigationController ()

@end

@implementation PULNavigationController
- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    PULSlideUnwindSegue *segue = [[PULSlideUnwindSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    return segue;
}

@end
