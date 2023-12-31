//
//  HMDTTMonitor+FrequenceDetect.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 6/5/2022.
//

#import "HMDTTMonitor.h"

extern NSString * _Nonnull const kHMDFrequenceDetectParamDidChangeNotification;

/// 在监控时间范围duration内：
/// 1. 如果累计频繁数据超过上报阈值maxCount，且距离上次上报超过reportInterval，则进行上报
/// 2. 如果累计频繁数据介于maxCount * 0.5 ~ maxCount, 会触发离散系数的计算，如果结果小于标准值，且距离上次上报超过reportInterval，则进行上报
@interface HMDFrequenceDetectParam : NSObject <NSCopying>

/// 是否开启频繁监控功能
@property (nonatomic, assign) BOOL enabled;

/// 监控的时间范围
@property (nonatomic, assign) double duration;

/// 上报阈值
@property (nonatomic, assign) NSUInteger maxCount;

/// 上报间隔
@property (nonatomic, assign) double reportInterval;



@end


@interface HMDTTMonitor (FrequenceDetect)

+ (void)setFrequenceDetectParam:(nullable HMDFrequenceDetectParam *)param;

+ (nullable HMDFrequenceDetectParam *)getFrequenceDetectParam;

@end
