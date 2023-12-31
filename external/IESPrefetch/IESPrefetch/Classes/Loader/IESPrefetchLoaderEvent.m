//
//  IESPrefetchLoaderEvent.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/17.
//

#import "IESPrefetchLoaderEvent.h"

NSTimeInterval eventDurationToNow(id<IESPrefetchLoaderEvent> event)
{
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceReferenceDate] - event.startTime;
    return duration * 1000;
}

static inline void initializeEvent(id<IESPrefetchLoaderEvent> event)
{
    event.startTime = [[NSDate date] timeIntervalSinceReferenceDate];
}

@implementation IESPrefetchLoaderConfigEvent

@synthesize startTime;
@synthesize error;

- (instancetype)init
{
    if (self = [super init]) {
        initializeEvent(self);
    }
    return self;
}

@end

@implementation IESPrefetchLoaderTriggerEvent

@synthesize startTime;
@synthesize error;

- (instancetype)init
{
    if (self = [super init]) {
        initializeEvent(self);
    }
    return self;
}

@end

@implementation IESPrefetchLoaderAPIEvent

@synthesize startTime;
@synthesize error;

- (instancetype)init
{
    if (self = [super init]) {
        initializeEvent(self);
    }
    return self;
}

@end
