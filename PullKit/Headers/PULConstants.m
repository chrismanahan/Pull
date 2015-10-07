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
const NSInteger kPULDistanceTogetherFeet = 20;
const NSInteger kPULDistanceTogetherMeters = FEET_TO_METERS(kPULDistanceTogetherFeet);
const NSInteger kPULDistanceNoLongerTogetherFeet = 70;
const NSInteger kPULDistanceNoLongerTogetherMeters = FEET_TO_METERS(kPULDistanceNoLongerTogetherFeet);

const NSInteger kPULDistanceHereFeet = 30;
const double kPULDistanceHereMeters =  FEET_TO_METERS( kPULDistanceHereFeet);

const NSInteger kPULDistanceHereTogetherFeet = 50;
const double kPULDistanceHereTogetherMeters = FEET_TO_METERS(kPULDistanceHereTogetherFeet);

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

const NSInteger kPULPollTimeActive = 2;//TODO:5;
const NSInteger kPULPollTimePassive = 15;//TODO:30;
const NSInteger kPULPollTimeBackground = 30;//TODO:120;

// location tracking
const NSInteger kLocationForegroundDistanceFilter = 1;//20;    // meters
const NSInteger kLocationBackgroundDistanceFilter = 4;//30;


NSString * const kPULPushFormattedMessageSendPull = @"%@ has sent you a pull!";
NSString * const kPULPushFormattedMessageAcceptPull = @"%@ has accepted your pull!";



NSString * const kAnalyticsAmplitudeEventSendPull = @"Send Pull";
NSString * const kAnalyticsAmplitudeEventAcceptPull = @"Accept Pull";
NSString * const kAnalyticsAmplitudeEventDeclinePull = @"Deleted Pull";
NSString * const kAnalyticsAmplitudeEventBlockUser = @"Blocked User";
NSString * const kAnalyticsAmplitudeEventUnblockUser = @"Unblocked User";
NSString * const kAnalyticsAmplitudeEventPullStateTogether = @"Arrived Together";