//
//  HMDCPUExceptionSampleInfo.h
//  Heimdallr-8bda3036
//
//  Created by bytedance on 2022/6/23.
//

#import <Foundation/Foundation.h>

@class HMDThreadCPUInfo;

NS_ASSUME_NONNULL_BEGIN

@interface HMDCPUExceptionSampleInfo : NSObject
/// 电量模式
@property (nonatomic, assign) BOOL isLowPowerModel;
@property (nonatomic, assign) BOOL isBack;
/// 发热状态
@property (nonatomic, assign) NSInteger thermalModel;
/// 线程数量
@property (nonatomic, assign) int threadCount;
/// 采样时候的平均 CPU 使用率
@property (nonatomic, assign) float averageUsage;
/// 核心数
@property (nonatomic, assign) NSUInteger processorCount;
@property (nonatomic, assign) long long timestamp;

@property (nonatomic, copy) NSString *scene;
@property (nonatomic, copy) NSString *customScene;
@property (nonatomic, copy) NSArray<HMDThreadCPUInfo *> *threadsInfo;

+ (HMDCPUExceptionSampleInfo *)sampleInfo;

@end

NS_ASSUME_NONNULL_END
