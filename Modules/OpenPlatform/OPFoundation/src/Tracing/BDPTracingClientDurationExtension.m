//
//  BDPTracingClientDurationExtension.m
//  Timor
//
//  Created by changrong on 2020/3/9.
//

#import "BDPTracingClientDurationExtension.h"
#import <ECOInfra/BDPLog.h>

/// ClientDurationEvent 原数据，用于存储一个finished的标记位和开始时间。初始化时间即为开始时间。
@interface BDPTracingClientDurationEvent : NSObject
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) NSInteger startTime;
@property (nonatomic, assign) NSInteger startTimeStamp;

@end
@implementation BDPTracingClientDurationEvent
+ (instancetype)event {
    BDPTracingClientDurationEvent *event = [[BDPTracingClientDurationEvent alloc] init];
    event.startTime = [[NSProcessInfo processInfo] systemUptime] * 1000;
    event.startTimeStamp = (NSInteger)([NSDate date].timeIntervalSince1970*1000);
    return event;
}
@end

@interface BDPTracingClientDurationExtension()

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPTracingClientDurationEvent *> *eventMap;

@end

@implementation BDPTracingClientDurationExtension

/// 记录开始点，如果key已经存在，报错
- (void)start:(NSString *)key {
    if (!key) {
        BDPLogWarn(@"start key is null");
        return;
    }
    if (self.eventMap[key]) {
        BDPLogWarn(@"start key exist, key: %@", key);
        NSAssert(NO, @"start key exist");
        return;
    }
    @synchronized(self.eventMap) {
        self.eventMap[key] = [BDPTracingClientDurationEvent event];
    }
}

/// 计算duration，key为空或key没有start，返回-1；同时会设置当前key为finished
- (NSInteger)end:(NSString *)startKey {
    if (!startKey) {
        BDPLogWarn(@"start key is null");
        return -1;
    }
    BDPTracingClientDurationEvent *event = self.eventMap[startKey];
    if (!event) {
        BDPLogInfo(@"do not find start key, %@", startKey)
        return -1;
    }
    NSInteger duration = [[NSProcessInfo processInfo] systemUptime] * 1000 - event.startTime;
    event.finished = YES;
    return duration;
}


/// 只计算duration，不标记当前key已完成, key为空或key没有start，返回-1
- (NSInteger)endDuration:(NSString *)startKey{
    if (!startKey) {
        BDPLogWarn(@"start key is null");
        return -1;
    }
    BDPTracingClientDurationEvent *event = self.eventMap[startKey];
    if (!event) {
        BDPLogInfo(@"do not find start key, %@", startKey)
        return -1;
    }
    NSInteger duration = [[NSProcessInfo processInfo] systemUptime] * 1000 - event.startTime;
    return duration;
}

- (NSInteger)endDuration:(NSString *)startKey timestamp:(NSInteger)timestamp{
    if (!startKey) {
        BDPLogWarn(@"start key is null");
        return -1;
    }
    BDPTracingClientDurationEvent *event = self.eventMap[startKey];
    if (!event) {
        BDPLogInfo(@"do not find start key, %@", startKey)
        return -1;
    }
    CGFloat duration = timestamp - event.startTimeStamp;
    return duration;
}

#pragma mark - BDPTracingExtension

/**
 * 协议层的merge实现，三端伪代码
 *
 // ClientDuration
 func mergeExtension {
     for key in A {
         if A[key].isFinished {
             continue
         }
         if B[key] != null && !B[key].isFinished {
            !error
            continue
         }
         if B[key] != null && B[key].isFinished {
             continue
         }
         B[key] = A[key]
     }
 }
 -  */
- (void)mergeExtension:(BDPTracingClientDurationExtension *)extension {
    NSDictionary<NSString *, BDPTracingClientDurationEvent *> *copyMap = nil;
    @synchronized (extension.eventMap) {
        copyMap = [extension.eventMap copy];
    }
    [copyMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDPTracingClientDurationEvent * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.finished) {
            return ;
        }
        BDPTracingClientDurationEvent *currentEvent = self.eventMap[key];
        if (currentEvent) {
            if(!currentEvent.finished) {
                BDPLogWarn(@"start key exist, duplicated! key: %@", key);
                NSAssert(NO, @"start key exist");
                return;
            } else {
                BDPLogInfo(@"start key exist, is finished ignore, key: %@", key);
                return;
            }
        }
        self.eventMap[key] = obj;
    }];
}

# pragma mark - Getter
- (NSMutableDictionary<NSString *, BDPTracingClientDurationEvent *> *)eventMap {
    if (!_eventMap) {
        _eventMap = [NSMutableDictionary dictionary];
    }
    return _eventMap;
}

@end
