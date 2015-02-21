//
//  PULConstants.h
//  Pull
//
//  Created by Chris Manahan on 8/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const kPULFirebaseURL = @"https://pull.firebaseio.com";

NSString * const kPULFacebookAppID = @"468309439970987";

// urls
NSString * const kPULAppDownloadURL = @"http://getpulled.com";
NSString * const kPULAppUpdateURL = @"http://getpulled.com/app/version.json";

// emails
NSString * const kPULAppReportIssueEmail = @"support@getpulled.com";
NSString * const kPULAppSuggestionEmail = @"support@getpulled.com";
NSString * const kPULAppPartnerEmail = @"support@getpulled.com";

const float kPULDistanceUnitCutoff = 1000;
const float kPULNearbyDistance = 30.48; // meters = 100 ft

// location tracking
const NSInteger kLocationForegroundDistanceFilter = 0;//20;    // meters
const NSInteger kLocationBackgroundDistanceFilter = 5;//30;