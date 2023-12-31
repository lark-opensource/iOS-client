//
//  HMDNetTrafficMonitor+Privated.h
//  Heimdallr-30fca18e
//
//  Created by zhangxiao on 2020/8/17.
//

#import "HMDNetTrafficMonitor.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDNetTrafficApplicationStateType) {
    HMDNetTrafficApplicationStateForeground = 0,
    HMDNetTrafficApplicationStateBackground,
    HMDNetTrafficApplicationStateNeverFront,
};

@interface HMDNetTrafficMonitor (Privated)

@property (nonatomic, strong, readonly) HMDNetTrafficUsageStatistics *statisticsTool;
@property (nonatomic, strong, readonly) dispatch_queue_t trafficCollectQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary *customSpanInfoDict;
@property (nonatomic, assign, readonly) BOOL everFront;
@property (nonatomic, strong, readwrite, nullable) dispatch_source_t intervalTrafficTimer;

- (void)networkTrafficUsageWithURL:(NSString *)url
                        requestLog:(NSString *)requestLog
                        clientType:(NSString *)clientType
                          MIMEType:(NSString *)MIMEType;

- (void)networkTrafficUsageWithURL:(NSString *)url
                         sendBytes:(unsigned long long)sendBytes
                         recvBytes:(unsigned long long)recvBytes
                        clientType:(NSString *)clientType
                          MIMEType:(NSString *)MIMEType;

/// implementation "HMDNetTrafficMonitor+TrafficConsume.h"
- (void)setupTimerForIntervalTrafficUsage;
/// implementation "HMDNetTrafficMonitor+TrafficConsume.h"
- (void)stopTimeForIntervalTrafficUsageIfNeed;
- (void)switchIntervalTimerWithStatus:(BOOL)enableIntervalTimer;

+ (void)changeTrafficAppState:(HMDNetTrafficApplicationStateType)state;
+ (HMDNetTrafficApplicationStateType)currentTrafficAppState;
- (void)notificateConsumeEnterForground:(BOOL)stateChange;
- (void)notificateConsumeEnterBackground:(BOOL)stateChange;

- (void)executePublicCallBackWithMonitorType:(NSString *)monitorType usage:(NSDictionary *)usage biz:(NSDictionary * _Nullable)biz;

@end

NS_ASSUME_NONNULL_END
