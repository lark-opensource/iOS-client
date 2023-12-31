//
//  ACCRecorderTrackerTool.m
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2020/10/27.
//

#import "ACCTimeTraceUtil.h"

@implementation ACCTimeTraceUtil

+ (void)startTraceTimeForKey:(id<NSCopying>)key
{
    if (key) {
        NSNumber *startTime = @(CACurrentMediaTime()*1000.0);
        @synchronized (self) {
            [[self timingDict] setObject:startTime forKey:key];
        }
    }
}

+ (void)cancelTraceTimeForKey:(nonnull id<NSCopying>)key
{
    if (key) {
        @synchronized (self) {
            [[self timingDict] removeObjectForKey:key];
        }
    }
}

+ (NSTimeInterval)timeIntervalForKey:(nonnull id<NSCopying>)key
{
    if (!key) {
        return 0.0;
    }

    NSNumber *startTime;
    @synchronized (self) {
       startTime = (NSNumber *)[self timingDict][key];
    }

    if (!startTime) {
        return 0;
    }
    double endTime = CACurrentMediaTime()*1000.0;
    NSTimeInterval timeInterval = endTime - [startTime doubleValue];
    return timeInterval;
}

+ (BOOL)alreadyTraceForKey:(id<NSCopying>)key
{
    return [[self timingDict] objectForKey:key] ? YES:NO;
}

#pragma mark - Private Methods

+ (NSMutableDictionary *)timingDict
{
    static NSMutableDictionary *timingDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timingDict = [NSMutableDictionary dictionary];
    });
    return timingDict;
}

@end
