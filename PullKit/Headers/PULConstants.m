//
//  PULConstants.h
//  Pull
//
//  Created by Chris Manahan on 8/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const kPULFacebookAppID = @"468309439970987";

// messages
NSString * const kPULMessageFbInvite = @"Pull me on Pull!";

// urls
// TODO: change app download url
NSString * const kPULAppDownloadURL = @"http://getpulled.com";
NSString * const kPULAppUpdateURL = @"http://getpulled.com/app/version.json";

// emails
NSString * const kPULAppReportIssueEmail = @"support@getpulled.com";
NSString * const kPULAppSuggestionEmail = @"support@getpulled.com";
NSString * const kPULAppPartnerEmail = @"support@getpulled.com";

// distances
const NSInteger kPULDistanceTogetherFeet = 25;
const double kPULDistanceTogetherMeters = FEET_TO_METERS(kPULDistanceTogetherFeet);
const NSInteger kPULDistanceNoLongerTogetherFeet = 70;
const double kPULDistanceNoLongerTogetherMeters = FEET_TO_METERS(kPULDistanceNoLongerTogetherFeet);

const NSInteger kPULDistanceHereFeet = 30;
const double kPULDistanceHereMeters =  FEET_TO_METERS( kPULDistanceHereFeet);

const NSInteger kPULDistanceHereTogetherFeet = 50;
const double kPULDistanceHereTogetherMeters = FEET_TO_METERS(kPULDistanceHereTogetherFeet);

const NSInteger kPULDistanceAlmostHereFeet = 100;
const double kPULDistanceAlmostHereMeter = FEET_TO_METERS(kPULDistanceAlmostHereFeet);

const NSInteger kPULDistanceNearbyFeet = 1000;
const double kPULDistanceNearbyMeters = FEET_TO_METERS(kPULDistanceNearbyFeet);


const NSInteger kPULLocationTuningDistanceVeryFarFeet = 7000;
const NSInteger kPULLocationTuningDistanceVeryFarMeters = FEET_TO_METERS(kPULLocationTuningDistanceVeryFarFeet);
const NSInteger kPULLocationTuningDistanceFarFeet = 2000;
const NSInteger kPULLocationTuningDistanceFarMeters = FEET_TO_METERS(kPULLocationTuningDistanceFarFeet);
const NSInteger kPULLocationTuningDistanceNearbyFeet = 250;
const NSInteger kPULLocationTuningDistanceNearbyMeters = FEET_TO_METERS(kPULLocationTuningDistanceNearbyFeet);

const NSInteger kPULLocationTuningIntervalVeryFar = 300;
const NSInteger kPULLocationTuningIntervalFar = 65;
const NSInteger kPULLocationTuningIntervalNearby = 25;
const NSInteger kPULLocationTuningIntervalClose = 10;

const double kPULDistanceAllowedAccuracy = 25;
const double kPULDistanceMaxDistanceForAccuracyReading = FEET_TO_METERS(5000);

const NSInteger kPULPullLocalNotificationDelayMinutes = 5;

const NSInteger kPULPollTimeActive = 11;
const NSInteger kPULPollTimePassive = 60;
const NSInteger kPULPollTimeBackground = 120;

NSString * const kPULPushFormattedMessageSendPull = @"%@ has sent you a pull!";
NSString * const kPULPushFormattedMessageAcceptPull = @"%@ has accepted your pull!";



NSString * const kAnalyticsAmplitudeEventSendPull = @"Send Pull";
NSString * const kAnalyticsAmplitudeEventAcceptPull = @"Accept Pull";
NSString * const kAnalyticsAmplitudeEventDeclinePull = @"Deleted Pull";
NSString * const kAnalyticsAmplitudeEventBlockUser = @"Blocked User";
NSString * const kAnalyticsAmplitudeEventUnblockUser = @"Unblocked User";
NSString * const kAnalyticsAmplitudeEventPullStateTogether = @"Arrived Together";
NSString * const kAnalyticsAmplitudeEventRefreshFriendsList = @"Refreshed Friends List";