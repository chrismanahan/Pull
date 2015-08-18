//
//  NSArray+Sorting.h
//  Pull
//
//  Created by Chris M on 8/18/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Sorting)

- (NSArray*)sortedPullsByExpiration;
- (NSArray*)sortedPullsByDistance;
- (NSArray*)sortedUsersByFirstName;
- (NSArray*)sortedUsersByLastName;

NS_ASSUME_NONNULL_END

@end
