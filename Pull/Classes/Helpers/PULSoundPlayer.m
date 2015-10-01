//
//  PULSoundPlayer.m
//  Pull
//
//  Created by Chris M on 9/14/15.
//  Copyright © 2015 Pull LLC. All rights reserved.
//

#import "PULSoundPlayer.h"

#import <AudioToolbox/AudioToolbox.h>

@implementation PULSoundPlayer
{
    SystemSoundID _boopSoundID;
}

- (id)init
{
    if (self = [super init])
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"boop" ofType:@"mp3"];
        NSURL *pathUrl = [NSURL fileURLWithPath:path];
        // TODO: enable sound load
  //      AudioServicesCreateSystemSoundID((__bridge CFURLRef)pathUrl, &_boopSoundID);
        
    }
    
    return self;
}

- (void)playBoop;
{
    AudioServicesPlaySystemSound(_boopSoundID);
}

- (void)dealloc
{
    AudioServicesDisposeSystemSoundID(_boopSoundID);
}

@end
