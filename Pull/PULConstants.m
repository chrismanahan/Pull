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

// messages
NSString * const kPULMessageFbInvite = @"Pull me on Pull!";

// urls
NSString * const kPULAppDownloadURL = @"http://getpulled.com";
NSString * const kPULAppUpdateURL = @"http://getpulled.com/app/version.json";

// emails
NSString * const kPULAppReportIssueEmail = @"support@getpulled.com";
NSString * const kPULAppSuggestionEmail = @"support@getpulled.com";
NSString * const kPULAppPartnerEmail = @"support@getpulled.com";

const float kPULNearbyDistance = 304.8; // 1000 feet
const float kPULDistanceUnitCutoff = 100;

// location tracking
const NSInteger kLocationForegroundDistanceFilter = 1;//20;    // meters
const NSInteger kLocationBackgroundDistanceFilter = 4;//30;