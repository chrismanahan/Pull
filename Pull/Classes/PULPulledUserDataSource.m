//
//  PULPulledUserDataSource.m
//  Pull
//
//  Created by Chris M on 8/26/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import "PULPulledUserDataSource.h"

#import "NSArray+Sorting.h"

@implementation PULPulledUserDataSource

- (void)loadDatasourceCompletion:(void(^)(NSArray *ds))completion
{
    PULAccount *acct = [PULAccount currentUser];
    // check if pulls are loaded
    if (acct.pulls.isLoaded)
    {
        // unregister from pulls loaded block if needed
        [acct.pulls unregisterLoadedBlock];
        
        // check if we need to rebuild the datasource
        if ([self _validateDatasource] && _datasource.count == acct.pulls.count && _datasource != nil)
        {
            completion(_datasource);
        }
        else
        {
            // create data source
            [self _buildDatasource];
            
            if (completion)
            {
                completion(_datasource);
            }
        }
    }
    else
    {
        if (acct.pulls)
        {
            [acct.pulls registerLoadedBlock:^(FireMutableArray *objects) {
                [self loadDatasourceCompletion:completion];
            }];
        }
        else
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self loadDatasourceCompletion:completion];
            });
        }
    }
}

- (BOOL)_validateDatasource
{
    double lastDistance = 0;
    for (int i = 0; i < _datasource.count; i++)
    {
        PULPull *pull = _datasource[i];
        double thisDistance = [[pull otherUser] distanceFromUser:[PULAccount currentUser]];
        
        // check if status has changed
        for (PULPull *aPull in [PULAccount currentUser].pulls)
        {
            if ([aPull isEqual:pull])
            {
                // match status
                if (aPull.status != pull.status)
                {
                    return NO;
                }
            }
        }
        
        if (thisDistance < lastDistance && pull.status == PULPullStatusPulled)
        {
            return NO;
        }
        else
        {
            lastDistance = thisDistance;
        }
    }
    
    return YES;
}

/**
 *  Builds the datasource
 *
 *  @return Bool indicating if the datasource has changed from the previous datasource
 */
- (BOOL)_buildDatasource
{
    NSMutableArray *ds;
    
    PULAccount *acct = [PULAccount currentUser];
    // get active pulls
    NSMutableArray *activePulls = [[NSMutableArray alloc] initWithArray:acct.pullsPulledNearby];
    [activePulls addObjectsFromArray:acct.pullsPulledFar];
    
    // sort by distance and store
    ds = [[NSMutableArray alloc] initWithArray:[activePulls sortedPullsByDistance]];
    
    // add the rest of pulls
    [ds addObjectsFromArray:acct.pullsPending];
    [ds addObjectsFromArray:acct.pullsWaiting];
    
    // set data source
    _datasource = [[NSArray alloc] initWithArray:ds];
    
    return YES;
}


@end
