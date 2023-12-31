//
//  HMDModuleConfig+StartWeight.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/5.
//

#import "HMDModuleConfig.h"

//按大小排序，按序加载
typedef NS_ENUM(NSInteger, HMDModuleStartWeight) {
    HMDCrashModuleStartWeight = -1000,
    HMDWatchDogModuleStartWeight,
    HMDProtectorModuleStartWeight,
    HMDLagModuleStartWeight,
    
    HMDDefaultModuleStartWeight = 0,
};

NS_ASSUME_NONNULL_BEGIN

@interface HMDModuleConfig (StartWeight)

- (HMDModuleStartWeight)startWeight;

- (NSComparisonResult)compareStartWeight:(HMDModuleConfig *)config;

@end

NS_ASSUME_NONNULL_END
