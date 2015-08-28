//
//  PULPulledUserDataSource.h
//  Pull
//
//  Created by Chris M on 8/26/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PULPulledUserDataSource : NSObject

@property (nonatomic, strong, readonly) NSArray *datasource;

+ (PULPulledUserDataSource*)sharedDataSource;

- (void)loadDatasourceCompletion:(void(^)(NSArray *ds))completion;

@end
