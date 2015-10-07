//
//  PULConstants.h
//  Pull
//
//  Created by Chris Manahan on 8/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

extern NSString * const kPULFirebaseURL;

extern NSString * const kPULFacebookAppID;

extern NSString * const kPULMessageFbInvite;

extern NSString * const kPULAppDownloadURL;
extern NSString * const kPULAppUpdateURL;

extern NSString * const kPULAppReportIssueEmail;
extern NSString * const kPULAppSuggestionEmail;
extern NSString * const kPULAppPartnerEmail;

// DISTANCES
extern const NSInteger kPULDistanceTogetherFeet;
extern const NSInteger kPULDistanceTogetherMeters;

extern const NSInteger kPULDistanceNoLongerTogetherFeet;
extern const NSInteger kPULDistanceNoLongerTogetherMeters;

extern const NSInteger kPULDistanceHereFeet;
extern const double kPULDistanceHereMeters;
extern const NSInteger kPULDistanceHereTogetherFeet;
extern const double kPULDistanceHereTogetherMeters;

extern const NSInteger kPULDistanceAlmostHereFeet;
extern const double kPULDistanceAlmostHereMeter;

extern const NSInteger kPULDistanceNearbyFeet;
extern const double kPULDistanceNearbyMeters;

extern const NSInteger kPULLocationTuningDistanceLowFeet;
extern const NSInteger kPULLocationTuningDistanceLowMeters;
extern const NSInteger kPULLocationTuningDistanceAutoFeet;
extern const NSInteger kPULLocationTuningDistanceAutoMeters;
extern const NSInteger kPULLocationTuningDistanceMediumFeet;
extern const NSInteger kPULLocationTuningDistanceMediumMeters;
extern const NSInteger kPULLocationTuningDistanceHighFeet;
extern const NSInteger kPULLocationTuningDistanceHighMeters;

extern const NSInteger kPULPullLocalNotificationDelayMinutes;
extern const double kPULDistanceAllowedAccuracy;

extern const NSInteger kPULPollTimeActive;
extern const NSInteger kPULPollTimePassive;
extern const NSInteger kPULPollTimeBackground;
// distance filters
extern const NSInteger kLocationForegroundDistanceFilter;
extern const NSInteger kLocationBackgroundDistanceFilter;

/**
 *  Constant defines the string that is sent as a push notification when sending a pull. For this
 *  to work correctly, use with `stringWithFormat:` and pass the FirstName paramater as the argument
 *
 *  @param FirstName    The argument to pass is the first name of the sending user
 *
 *  @warning This must be used as a formatted string and passed one argument.
 */
extern NSString * const kPULPushFormattedMessageSendPull;
/**
 *  Constant defines the string that is sent as a push notification when accepting a pull. For this
 *  to work correctly, use with `stringWithFormat:` and pass the FirstName paramater as the argument
 *
 *  @param FirstName    The argument to pass is the first name of the current user
 *
 *  @warning This must be used as a formatted string and passed one argument.
 */
extern NSString * const kPULPushFormattedMessageAcceptPull;


extern NSString * const kAnalyticsAmplitudeEventSendPull;
extern NSString * const kAnalyticsAmplitudeEventAcceptPull;
extern NSString * const kAnalyticsAmplitudeEventDeclinePull;
extern NSString * const kAnalyticsAmplitudeEventBlockUser;
extern NSString * const kAnalyticsAmplitudeEventUnblockUser;
extern NSString * const kAnalyticsAmplitudeEventPullStateTogether;
extern NSString * const kAnalyticsAmplitudeEventRefreshFriendsList;