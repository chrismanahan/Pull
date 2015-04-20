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
#define PULLog( s, ... ) CLS_LOG( @"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
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

#define PUL_Purple [UIColor colorWithRed:0.290 green:0.271 blue:0.998 alpha:1.000];
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
#define METERS_TO_FEET(meters) (meters * 3.28084)
#define METERS_TO_MILES(meters) (meters * 0.000621371)

#endif
