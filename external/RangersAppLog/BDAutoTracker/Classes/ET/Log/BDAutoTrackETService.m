//
//  BDAutoTrackETService.m
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrackETService.h"
#import "BDAutoTrackMacro.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackETRequest.h"
#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackTimer.h"

@interface BDAutoTrackETService ()

@property (nonatomic, strong) dispatch_queue_t sendingQueue;
@property (nonatomic, strong) BDAutoTrackETRequest *request;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *debugEvents;
@property (nonatomic, assign) NSUInteger eventCount;

/// 定时器。每`reportTimeInterval`毫秒请求一次。
@property (nonatomic) dispatch_source_t reportTimer;
@end

@implementation BDAutoTrackETService

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.request = [[BDAutoTrackETRequest alloc] initWithAppID:appID];
        self.serviceName = BDAutoTrackServiceNameLog;
        NSString *queueName = [NSString stringWithFormat:@"com.applog.et_%@",appID];
        self.sendingQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        self.eventCount = 0;
        self.debugEvents = [NSMutableDictionary new];
        
        // 初始化上报计时器。setter重写过，会自动配置计时器。
        self.ETReportTimeInterval = 200;  // 200ms
    }
    
    return self;
}

#pragma mark - public
/// 用于发送埋点验证上报请求
/// @param event track
/// @param key 数据表名
- (void)sendEvent:(NSDictionary *)event key:(NSString *)key {
    if (![event isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (event.count < 1) {
        return;
    }
    if (![key isKindOfClass:[NSString class]]) {
        return;
    }
    if ([key isEqualToString:BDAutoTrackTableUIEvent] || [key isEqualToString:BDAutoTrackTableProfile]) {
        key = BDAutoTrackTableEventV3;
    }
    if (![NSJSONSerialization isValidJSONObject:event]) {
        return;
    }
    
    BDAutoTrackWeakSelf;
    dispatch_async(self.sendingQueue, ^{
        BDAutoTrackStrongSelf;
        [self cacheEvents:event key:key];
        
        if (!bd_registerServiceAvailableForAppID(self.appID)) {
            /// 未注册的情况下，只缓存1000条日志
            if (self.eventCount > 1000) {
                self.eventCount = 0;
                self.debugEvents = [NSMutableDictionary new];
            }
        }
    });
}

#pragma mark - private
- (void)cacheEvents:(NSDictionary *)event key:(NSString *)key {
    NSMutableArray *events = [self.debugEvents objectForKey:key];
    if (events == nil) {
        events = [NSMutableArray new];
        [self.debugEvents setValue:events forKey:key];
    }
    self.eventCount += event.count;
    [events addObject:event];
}

- (void)sendAllEvent {
    if (self.debugEvents.count <= 0) {
        return;
    }
    
    BDAutoTrackWeakSelf;
    dispatch_async(self.sendingQueue, ^{
        BDAutoTrackStrongSelf;
        self.request.parameters = self.debugEvents;
        self.debugEvents = [NSMutableDictionary new];
        self.eventCount = 0;
        [self.request startRequestWithRetry:0];
    });
}

#pragma mark - timer 相关
/// 上报间隔的setter中自动重新设置计时器时间间隔
- (void)setETReportTimeInterval:(long long)ETReportTimeInterval {
    _ETReportTimeInterval = ETReportTimeInterval;
    [self scheduleReportTimer];
}

- (NSString *)timerName {
    NSString *appID = self.appID;
    return [@"ETReportTimer" stringByAppendingString:appID];
}

/// 设置计时器时间间隔。重新设置将覆盖之前的配置。
- (void)scheduleReportTimer {
    BDAutoTrackWeakSelf;
    [[BDAutoTrackTimer sharedInstance] scheduledDispatchTimerWithName:[self timerName]
                                                         timeInterval:self.ETReportTimeInterval / 1000.0
                                                                queue:nil
                                                              repeats:YES
                                                               action:^{
        BDAutoTrackStrongSelf;
        [self sendAllEvent];
    }];
}

// 留个cancel接口。暂时没有caller。
- (void)cancelReportTimer {
    [[BDAutoTrackTimer sharedInstance] cancelTimerWithName:[self timerName]];
}

@end


