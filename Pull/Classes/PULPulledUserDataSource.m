//
//  PULPulledUserDataSource.m
//  Pull
//
//  Created by Chris M on 8/26/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPulledUserDataSource.h"

#import "NSArray+Sorting.h"

#import "PULParseMiddleMan.h"

@interface PULPulledUserDataSource ()

@property (nonatomic, strong) id pullsLoadedNotification;

@end

@implementation PULPulledUserDataSource

- (void)loadDatasourceCompletion:(void(^)(NSArray *ds))completion
{
    PULParseMiddleMan *parse = [PULParseMiddleMan sharedInstance];
    
    if ([parse.cache cachedPulls])
    {
        completion([parse.cache cachedPulls]);
    }
}

//- (BOOL)_validateDatasource
//{
//    double lastDistance = 0;
//    for (int i = 0; i < _datasource.count; i++)
//    {
//        PULPull *pull = _datasource[i];
//        double thisDistance = [[pull otherUser] distanceFromUser:[PULUser currentUser]];
//        
//        // check if status has changed
//        for (PULPull *aPull in [PULUser currentUser].pulls)
//        {
//            if ([aPull isEqual:pull])
//            {
//                // match status
//                if (aPull.status != pull.status)
//                {
//                    return NO;
//                }
//            }
//        }
//        
//        if (thisDistance < lastDistance && pull.status == PULPullStatusPulled)
//        {
//            return NO;
//        }
//        else
//        {
//            lastDistance = thisDistance;
//        }
//    }
//    
//    return YES;
//}

/**
 *  Builds the datasource
 *
 *  @return Bool indicating if the datasource has changed from the previous datasource
 */
- (BOOL)_buildDatasource
{
    // TODO: BUILD DATA SOURCE
//    NSMutableArray *ds;
//    
//    PULUser *acct = [PULUser currentUser];
//    // get active pulls
//    NSMutableArray *activePulls = [[NSMutableArray alloc] initWithArray:acct.pullsPulledNearby];
//    [activePulls addObjectsFromArray:acct.pullsPulledFar];
//    
//    // sort by distance and store
//    ds = [[NSMutableArray alloc] initWithArray:[activePulls sortedPullsByDistance]];
//    
//    // add the rest of pulls
//    [ds addObjectsFromArray:acct.pullsPending];
//    [ds addObjectsFromArray:acct.pullsWaiting];
//    
//    // set data source
//    _datasource = [[NSArray alloc] initWithArray:ds];
    
    return YES;
}


@end
