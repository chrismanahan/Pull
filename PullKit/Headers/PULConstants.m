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

// distances
const NSInteger kPULDistanceHereFeet = 30;
const double kPULDistanceHereMeters =  FEET_TO_METERS( kPULDistanceHereFeet);

const NSInteger kPULDistanceAlmostHereFeet = 100;
const double kPULDistanceAlmostHereMeter = FEET_TO_METERS(kPULDistanceAlmostHereFeet);

const NSInteger kPULDistanceNearbyFeet = 1000;
const double kPULDistanceNearbyMeters = FEET_TO_METERS(kPULDistanceNearbyFeet);


const NSInteger kPULLocationTuningDistanceLowFeet = 7000;
const NSInteger kPULLocationTuningDistanceLowMeters = FEET_TO_METERS(kPULLocationTuningDistanceLowFeet);
const NSInteger kPULLocationTuningDistanceAutoFeet = 1000;
const NSInteger kPULLocationTuningDistanceAutoMeters = FEET_TO_METERS(kPULLocationTuningDistanceAutoFeet);
const NSInteger kPULLocationTuningDistanceMediumFeet = 100;
const NSInteger kPULLocationTuningDistanceMediumMeters = FEET_TO_METERS(kPULLocationTuningDistanceMediumFeet);
const NSInteger kPULLocationTuningDistanceHighFeet = 0;
const NSInteger kPULLocationTuningDistanceHighMeters = FEET_TO_METERS(kPULLocationTuningDistanceHighFeet);

const double kPULDistanceAllowedAccuracy = 15;

const NSInteger kPULPullLocalNotificationDelayMinutes = 5;

// location tracking
const NSInteger kLocationForegroundDistanceFilter = 1;//20;    // meters
const NSInteger kLocationBackgroundDistanceFilter = 4;//30;