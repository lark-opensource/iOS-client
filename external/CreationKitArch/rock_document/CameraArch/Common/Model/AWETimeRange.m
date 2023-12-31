//
//  AWETimeRange.m
//  Aspects
//
// Created by Xuxu on September 13, 2018
//

#import "AWETimeRange.h"

@implementation AWETimeRange

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"start" : @"start",
             @"duration" : @"duration",
             };
}

+ (AWETimeRange *)timeRangeWithCMTimeRange:(CMTimeRange)timeRange
{
    return [[AWETimeRange alloc] initWithCMTimeRange:timeRange];
}

- (id)copyWithZone:(NSZone *)zone
{
    AWETimeRange *copy = [[AWETimeRange alloc] init];
    copy.start = self.start;
    copy.duration = self.duration;
    return copy;
}

- (instancetype)initWithCMTimeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        _start = @(CMTimeGetSeconds(timeRange.start));
        _duration = @(CMTimeGetSeconds(timeRange.duration));
    }
    return self;
}

-(CMTimeRange)CMTimeRangeValue
{
    return CMTimeRangeMake(CMTimeMakeWithSeconds(self.start.doubleValue, NSEC_PER_SEC), CMTimeMakeWithSeconds(self.duration.doubleValue, NSEC_PER_SEC));
}
@end
