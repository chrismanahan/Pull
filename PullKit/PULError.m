//
//  PULError.m
//  Pull
//
//  Created by Development on 11/15/14.
//  Copyright (c) 2014 Pull LLC. All rights reserved.
//

#import "PULError.h"

@implementation PULError

+ (BOOL)handleError:(NSError*)error target:(id)target selector:(SEL)selector object:(id)arg
{
    if (error)
    {
        // TODO: Find name of class that called error by looking at the stack trace
        PULLogError(@"Error", @"%@", error.localizedDescription);
    
        if (target && selector)
        {
            if ([target respondsToSelector:selector])
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [target performSelector:selector withObject:arg];
#pragma clang diagnostic pop
            }

        }
        return YES;
                    
    }
    return NO;

}

+ (BOOL)handleError:(NSError*)error;
{
    return [self handleError:error target:nil selector:nil object:nil];
}

@end

