//
//  Heimdallr+UserTracker.m
//  Heimdallr
//
//  Created by joy on 2018/6/8.
//

#import "Heimdallr+UserTracker.h"
#import "HMDStartDetector.h"

@implementation Heimdallr (UserTracker)
+ (void)hmd_didFnishConcurrentRendering {
    [[HMDStartDetector share] didFnishConcurrentRendering];
}
@end
