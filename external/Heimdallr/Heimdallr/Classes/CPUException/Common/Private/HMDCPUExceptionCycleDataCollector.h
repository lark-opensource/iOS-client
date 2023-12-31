//
//  HMDCPUExceptionPool.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/4/24.
//

#import <Foundation/Foundation.h>

@class HMDCPUExceptionV2Record, HMDCPUExceptionSampleInfo;

NS_ASSUME_NONNULL_BEGIN

#pragma mark
#pragma mark --- HMDCPUExceptionSamplePool ---
/// CPU 异常的采样缓存池
@interface HMDCPUExceptionCycleDataCollector : NSObject

/// 采样周期开始时间
@property (nonatomic, assign) long long startTime;
/// 采样周期结束时间
@property (nonatomic, assign) long long endTime;
/// settings 里面的 CPU 使用阈值
@property (nonatomic, assign) float thresholdConfig;
@property (nonatomic, assign) NSUInteger sampleDuration;
@property (nonatomic, assign) NSUInteger maxTreeDepth;
@property (nonatomic, assign) BOOL hasBinaryImage;

/// 收集一次采样的信息
- (void)pushOnceSampledInfo:(HMDCPUExceptionSampleInfo *)sampleInfo;

/// 本次采样周期未达到功耗未到达阈值，清空本轮采样数据
- (void)clearAllSampleInfo;

/// 汇总生成一次 CPU 异常采样周期内的数据
- (HMDCPUExceptionV2Record * _Nullable)makeSummaryInExceptionCycle;
+ (NSDictionary *)fetchCurrenImageList;

@end

NS_ASSUME_NONNULL_END
