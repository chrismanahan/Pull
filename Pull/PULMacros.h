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
#ifdef DEBUG
    #define PULLog( s, ... ) NSLog( @"<%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
    #define PULLogError( title, s, ... ) NSLog( @"!ERROR <%@> | <%@:%d> %@", title, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
    #define PULLog( s, ... )
    #define PULLogError( s, ... )
#endif


#define PULLogBounds(view) UA_log(@"%@ bounds: %@", view, NSStringFromRect([view bounds]))
#define PULLogFrame(view)  UA_log(@"%@ frame: %@", view, NSStringFromRect([view frame]))

/*****************************************
 Colors
 *****************************************/

#define PUL_rgba(r,g,b,a)				[UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define PUL_rgb(r,g,b)					PUL_rgba(r, g, b, 1.0f)

/*****************************************
 Misc.
 *****************************************/

#define NSStringFromBool(b) (b ? @"YES" : @"NO")


#endif
