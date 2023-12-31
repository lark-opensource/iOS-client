//
//  BDPTrackerEvent.m
//  Timor
//
//  Created by 维旭光 on 2018/12/9.
//

#import "BDPTrackerEvent.h"

@interface BDPTrackerTimingEvent ()

@property (nonatomic, assign) NSUInteger countingTime; // 0表示stop

@end

@implementation BDPTrackerTimingEvent

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self start];
    }
    return self;
}

- (void)start {
    if (![self isStart]) {
        _countingTime = (NSUInteger)([[NSDate date] timeIntervalSince1970] * 1000);
        _startTime = _countingTime;
    }
}

- (void)stop {
    [self duration];
    _countingTime = 0;
}

- (void)reset {
    _countingTime = 0;
    _startTime = 0;
    _duration = 0;
}

- (void)reStart
{
    [self reset];
    [self start];
}

- (BOOL)isStart {
    return _countingTime > 0;
}

- (NSUInteger)duration {
    if ([self isStart]) {
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970] * 1000;
        NSUInteger time = (NSUInteger)(endTime - _countingTime);
        _duration += time;
        _countingTime = endTime;
    }
    return _duration;
}

@end


@interface BDPTrackerPageEvent ()

@end

@implementation BDPTrackerPageEvent

- (instancetype)initWithPath:(NSString *)pagePath hasWebview:(BOOL)hasWebview {
    self = [super init];
    if (self) {
        self.pagePath = pagePath;
        _hasWebview = hasWebview;
    }
    return self;
}

@end
