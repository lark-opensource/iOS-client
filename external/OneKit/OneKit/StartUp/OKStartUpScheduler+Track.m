//
//  OKStartUpScheduler+Track.m
//  OneKit
//
//  Created by bob on 2021/1/12.
//

#import "OKStartUpScheduler+Track.h"
#import "OKUtility.h"

@implementation OKStartUpScheduler (Track)

@dynamic taskTimeStamps;

- (void)trackStartupTask:(NSString *)taskIdentifier duration:(long long)duration {
    if (!OK_isValidString(taskIdentifier)) {
        return;
    }
    [self.taskTimeStamps setValue:@(duration) forKey:taskIdentifier];
}

- (void)startReport {
//    [OKTrackerProtocol eventV3:@"bd_startup_task" params:[self.taskTimeStamps copy]];
    self.taskTimeStamps = [NSMutableDictionary new];
}

@end
