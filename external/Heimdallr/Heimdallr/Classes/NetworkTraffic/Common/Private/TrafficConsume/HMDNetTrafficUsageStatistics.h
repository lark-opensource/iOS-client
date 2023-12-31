//
//  HMDNetTrafficUsageManager.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/8/17.
//

#import <Foundation/Foundation.h>
#import "HMDNetTrafficMonitor+TrafficConsume.h"

@class HMDNetTrafficSourceUsageModel;
@class HMDNetTrafficBizUsageModel;
@class HMDNetTrafficIntervalUsageModel;
@class HMDNetTrafficMonitorConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void(^HMDTrafficIntervalCallback)(HMDNetTrafficIntervalUsageModel *);

@interface HMDNetTrafficUsageStatistics : NSObject

@property (nonatomic, assign) long long anchorTS;
@property (nonatomic, assign) NSInteger configInterval;
@property (nonatomic, assign) BOOL isBackground;

- (instancetype)initWithOperationQueue:(dispatch_queue_t)queue;
#pragma mark --- work status change
- (void)updateTrafficConfig:(HMDNetTrafficMonitorConfig *)config;
- (void)resetStatisticsDataOnSafeThread;
/// not thread safety and call it must in traffic operation queue !!!
- (void)resetStatisticsData;

- (void)addCustomSpanTrafficCollect:(NSString *)collectorName;
- (void)endCustomSpanTrafficCollect:(NSString *)collectorName
                         completion:(HMDTrafficIntervalCallback)completion;

#pragma mark --- inject net traffic usage information
- (void)hmdBizConsumeWithTrafficBytes:(long long)trafficBytes
                             sourceId:(NSString *)sourceId
                             business:(NSString *)business
                                scene:(NSString *)scene
                          extraStatus:(NSDictionary *)extraStatus
                             extraLog:(NSDictionary *)extraLog
                  isCurrentTotalUsage:(BOOL)isCurrentTotalUsage
                          trafficType:(HMDNetTrafficMonitorTrafficType)trafficType;

- (void)networkTrafficUsageWithURL:(NSString *)url
                         sendBytes:(unsigned long long)sendBytes
                         recvBytes:(unsigned long long)recvBytes
                        clientType:(NSString *)clientType
                          MIMEType:(NSString *)MIMEType;

- (void)networkTrafficUsageWithURL:(NSString *)url
                        requestLog:(NSString *)requestLog
                        clientType:(NSString *)clientType
                          MIMEType:(NSString *)MIMEType;

#pragma mark --- statistic usage
- (void)intervalTrafficDetailWithModel:(HMDTrafficIntervalCallback)completion;

@end

NS_ASSUME_NONNULL_END
