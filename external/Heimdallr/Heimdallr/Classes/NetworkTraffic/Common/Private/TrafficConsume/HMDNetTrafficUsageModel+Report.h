//
//  HMDNetTrafficUsageModel+Report.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/8/21.
//

#import "HMDNetTrafficSourceUsageModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark --- HMDNetTrafficUsageModel
@interface HMDNetTrafficSourceUsageModel (Report)

+ (NSArray<NSDictionary *> *)formatNormalUsageInfosToStoredDicts:(NSArray<HMDNetTrafficSourceUsageModel *> *)usageArray;
/// high frequency report content include "freq"
+ (NSArray<NSDictionary *> *)formatHighFreqUsageInfosToStoredDicts:(NSArray<HMDNetTrafficSourceUsageModel *> *)usageArray;

@end

#pragma mark --- HMDNetTrafficBizUsageModel
@interface HMDNetTrafficBizUsageModel (Report)

- (NSDictionary *)formatGroupByBizWithNeedSource:(BOOL)needSource;

@end


NS_ASSUME_NONNULL_END
