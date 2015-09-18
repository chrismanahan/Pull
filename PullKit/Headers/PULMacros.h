//
//  PULMacros.h
//  Pull
//
//  Created by Chris Manahan on 8/26/14.
//  Copyright (c) 2014 Chris Manahan. All rights reserved.
//

#ifndef Pull_PULMacros_h
#define Pull_PULMacros_h

/*****************************************
 Logging
 *****************************************/
#define PULLog( s, ... )  NSLog( @"<%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#define PULLogNotif( s, ... ) /*CLS_LOG*/NSLog( @"NOTIF - %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])

#ifdef DEBUG
//    #define PULLog( s, ... ) NSLog( @"<%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
    #define PULLogError( title, s, ... ) NSLog( @"!ERROR <%@> | <%@:%d> %@", title, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
//    #define PULLog( s, ... )
    #define PULLogError( s, ... )
#endif


#define PULLogBounds(view) UA_log(@"%@ bounds: %@", view, NSStringFromRect([view bounds]))
#define PULLogFrame(view)  UA_log(@"%@ frame: %@", view, NSStringFromRect([view frame]))

/*****************************************
 Colors
 *****************************************/

#define PUL_rgba(r,g,b,a)				[UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define PUL_rgb(r,g,b)					PUL_rgba(r, g, b, 1.0f)

#define PUL_LightPurple [UIColor colorWithRed:0.451 green:0.420 blue:1.0 alpha:1.0]
#define PUL_Purple [UIColor colorWithRed:0.35686 green:0.137254 blue:1.0 alpha:1.0];
#define PUL_DarkPurple [UIColor colorWithRed:0.26274 green:0.09411 blue:0.713725 alpha:1.0];
#define PUL_Blue  [UIColor colorWithRed:0.054 green:0.464 blue:0.998 alpha:1.000]
#define PUL_LightGray    [UIColor colorWithWhite:0.877 alpha:1.000];

/*****************************************
 Misc.
 *****************************************/

#define NSStringFromBool(b) (b ? @"YES" : @"NO")


/*****************************************
 Maths
 *****************************************/
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define FEET_TO_METERS(feet) (feet * 0.3048)
#define METERS_TO_FEET(meters) (meters * 3.28084)
#define METERS_TO_MILES(meters) (meters * 0.000621371)

#define PUL_FORMATTED_DISTANCE_FEET(meters) [NSString stringWithFormat:@"%.0f ft", METERS_TO_FEET(meters)]
#define PUL_FORMATTED_DISTANCE_MILES(meters) [NSString stringWithFormat:@"%.2f miles", METERS_TO_MILES(meters)]

#endif
