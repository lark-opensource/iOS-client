//
//  HMDPerformanceUploadSetting.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/19.
//

#import "HMDCommonAPISetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDPerformanceUploadSetting : HMDCommonAPISetting

@property (nonatomic, assign) NSUInteger maxRetryCount; //最大重试次数
@property (nonatomic, assign) NSUInteger uploadInterval;
@property (nonatomic, assign) NSUInteger onceMaxCount;
@property (nonatomic, assign) NSUInteger reportFailBaseInterval;
@property (nonatomic, assign) BOOL enableNetQualityReport;
@property (nonatomic, assign) BOOL enableDowngradeByChannel;
@end

NS_ASSUME_NONNULL_END
