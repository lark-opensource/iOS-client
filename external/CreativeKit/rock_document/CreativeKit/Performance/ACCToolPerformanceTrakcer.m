//
//  ACCToolPerformanceTrakcer.m
//  CreativeKit-Pods-Aweme
//
//  Created by Liyingpeng on 2021/7/18.
//

#import "ACCToolPerformanceTrakcer.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>

static const NSInteger kPerformancePendingValue = 0;

@interface ACCToolPerformanceTrakcer ()

@property (nonatomic, strong) NSMutableDictionary *eventBeginDictionary;
@property (nonatomic, strong) NSMutableDictionary *eventEndDictionary;

@property (nonatomic, assign) BOOL pending;
@property (nonatomic, copy) NSString *trackName;
@property (nonatomic, assign, readwrite) BOOL finished;

@end

@implementation ACCToolPerformanceTrakcer

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _eventBeginDictionary = @{}.mutableCopy;
        _eventEndDictionary = @{}.mutableCopy;
        _trackName = name;
        _finished = YES;
    }
    return self;
}

- (void)eventBegin:(NSString *)event
{
    acc_infra_main_async_safe(^{
        if (event.length <= 0) {
            return;
        }
        
        if ([event isEqualToString:self.primaryKey]) {
            self.finished = NO;
        } else if (self.finished) {
            return;
        }
        
        self.eventBeginDictionary[event] = @(CACurrentMediaTime());
    });
}

- (void)eventEnd:(NSString *)event
{
    acc_infra_main_async_safe(^{
        if (event.length <= 0 || self.finished) {
            return;
        }
        
        if ([self.eventEndDictionary.allKeys containsObject:event]) {
            // avoid duplicated
            return;
        }
        
        self.eventEndDictionary[event] = @(CACurrentMediaTime());
        
        if (self.pending) {
            [self startTrack];
        }
    });
}

- (void)eventEnd:(NSString *)event trackingBeginEvent:(NSString *)beginEvent {
    acc_infra_main_async_safe(^{
        if (self.finished) {
            return;
        }
        if (beginEvent.length > 0 && self.eventBeginDictionary[beginEvent]) {
            self.eventBeginDictionary[event] = self.eventBeginDictionary[beginEvent];
        } else {
            self.eventBeginDictionary[event] = @(kPerformancePendingValue);
        }
        [self eventEnd:event];
    });
}

- (void)eventEnd:(NSString *)event trackingEndEvent:(NSString *)endEvent {
    acc_infra_main_async_safe(^{
        if (self.finished) {
            return;
        }
        if (endEvent.length > 0 && self.eventEndDictionary[endEvent]) {
            self.eventBeginDictionary[event] = self.eventEndDictionary[endEvent];
        } else {
            self.eventBeginDictionary[event] = @(kPerformancePendingValue);
        }
        [self eventEnd:event];
    });
}

- (void)checkPrimaryKey {
    if (self.primaryKey.length <= 0) {
        return;
    }
    if (!self.eventBeginDictionary[self.primaryKey]) {
        [self eventBegin:self.primaryKey];
    }
}

- (void)startTrack {
    [self startTrackWithParam:nil];
}

- (NSInteger)getDurationBetween:(NSString *)key1 and:(NSString *)key2 {
    if (key1.length <= 0) {
        return [self getDuration:key2];
    }
    if (key2.length <= 0) {
        return [self getDuration:key1];
    }
    CFTimeInterval begin = MIN([self.eventBeginDictionary[key1] doubleValue], [self.eventBeginDictionary[key2] doubleValue]);
    CFTimeInterval end = MAX([self.eventEndDictionary[key1] doubleValue], [self.eventEndDictionary[key2] doubleValue]);
    return (end - begin) * 1000.f;
}

- (void)failedTrackWithErrorCode:(NSInteger)errorCode {
    [self failedTrackWithErrorCode:errorCode noEventTracking:NO];
}

- (void)failedTrackWithErrorCode:(NSInteger)errorCode noEventTracking:(BOOL)noEventTracking {
    acc_infra_main_async_safe(^{
        if (self.finished) {
            return;
        }
        NSMutableDictionary *mParas = [NSMutableDictionary dictionary];
        mParas[@"performance_error_code"] = @(errorCode);
        if (noEventTracking) {
            [self realTrackWithParam:mParas];
            return;
        }
        
        if (!self.eventEndDictionary[self.primaryKey]) {
            [self eventEnd:self.primaryKey];
        }
        for (NSString *waitingKey in self.waitingKeyArray) {
            if (!self.eventBeginDictionary[waitingKey]) {
                [self eventEnd:waitingKey trackingBeginEvent:self.primaryKey];
            } else if (!self.eventEndDictionary[waitingKey]) {
                [self eventEnd:waitingKey];
            }
        }
        
        [self startTrackWithParam:mParas.copy];
    });
}

- (void)clear
{
    acc_infra_main_async_safe(^{
        [self.eventBeginDictionary removeAllObjects];
        [self.eventEndDictionary removeAllObjects];
        self.pending = NO;
        self.finished = YES;
    });
}

#pragma mark - private

- (NSInteger)getDuration:(NSString *)key {
    if (!self.eventBeginDictionary[key] || !self.eventEndDictionary[key]) {
        return kPerformancePendingValue;
    }
    if ([self.eventBeginDictionary[key] integerValue] == kPerformancePendingValue) {
        return kPerformancePendingValue;
    }
    return ([self.eventEndDictionary[key] doubleValue] - [self.eventBeginDictionary[key] doubleValue]) * 1000.f;
}

- (BOOL)checkTrackDataFinished {
    __block BOOL result = YES;
    NSArray *trackingKeys = [self.eventBeginDictionary allKeys];
    if (self.waitingKeyArray) {
        trackingKeys = self.waitingKeyArray;
    }
    [trackingKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!self.eventEndDictionary[key]) {
            result = NO;
            *stop = YES;
        }
    }];
    
    return result;
}

- (void)startTrackWithParam:(NSDictionary *)param {
    acc_infra_main_async_safe(^{
        if (self.finished) {
            return;
        }
        if (![self checkTrackDataFinished]) {
            self.pending = YES;
            return;
        }
        
        NSMutableDictionary *mParams = [NSMutableDictionary dictionaryWithDictionary:param];
        
        [self.eventBeginDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [mParams setObject:@([self getDuration:key]) forKey:key];
        }];
        
        !self.additionHandleBlock ?: self.additionHandleBlock(mParams);
        
        [self realTrackWithParam:mParams];
    });
}

- (void)realTrackWithParam:(NSMutableDictionary *)mParams {
    [ACCTracker() trackEvent:self.trackName params:mParams.copy needStagingFlag:NO];
    
    //monitor
    mParams[@"service"] = self.trackName;
    [ACCMonitor() trackData:mParams.copy logTypeStr:@"dmt_studio_performance_log"];
    
    [self clear];
}

@end
