//
//  HMDCPUExceptionConfig.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/4/23.
//

#import "HMDModuleConfig.h"



extern NSString * _Nonnull const kHMDModuleCPUExceptionMonitor;//CPU异常监控

@interface HMDCPUExceptionConfig : HMDModuleConfig

/// CPU 异常阈; 1 代表 100%, 为平均 CPU使用率, 即 平均到核心的 CPU 使用率
@property (nonatomic, assign) float cpuThreshold;
/// 对于线程 CPU 使用率超过多少的线程进行采样; 1 代表 100%, 默认是 0.05 即 5%
@property (nonatomic, assign) float threadUsageThreshold;
/// 采样 间隔; 单位 秒, 默认 1s
@property (nonatomic, assign) NSInteger sampleInterval;
/// 功耗
@property (nonatomic, assign) float powerConsumptionThreshold;
/// 是否开启去重逻辑
@property (nonatomic, assign) BOOL ignoreDuplicate;
@property (nonatomic, assign) BOOL threadSuspend;
@property (nonatomic, assign) NSInteger maxTreeDepth;

@property (nonatomic, assign) BOOL enablePerformaceCollect;
@property (nonatomic, assign) BOOL enableThermalMonitor;
@property (nonatomic, assign) float characterScale;

@end


