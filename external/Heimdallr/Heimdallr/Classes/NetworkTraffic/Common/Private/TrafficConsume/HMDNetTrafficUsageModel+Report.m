//
//  HMDNetTrafficUsageModel+Report.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/8/21.
//

#import "HMDNetTrafficUsageModel+Report.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetTrafficDefinedKey.h"

#pragma mark --- HMDNetTrafficUsageModel
@implementation HMDNetTrafficSourceUsageModel (Report)

+ (NSArray<NSDictionary *> *)formatNormalUsageInfosToStoredDicts:(NSArray<HMDNetTrafficSourceUsageModel *> *)usageArray {
   NSMutableArray *reportArray = [NSMutableArray array];
    for (HMDNetTrafficSourceUsageModel *usageModel in usageArray) {
        NSDictionary *trafficInfo = @{
            kHMDTrafficBizUsageReportKeyPath: usageModel.souceId?:@"unknown",
            kHMDTrafficBizUsageReportKeyUsage: @(usageModel.usageBytes),
            kHMDTrafficBizUsageReportKeyBiz: usageModel.business?:@"unknown"
        };
        [reportArray hmd_addObject:trafficInfo];
    }
    return [reportArray copy];
}

+ (NSArray<NSDictionary *> *)formatHighFreqUsageInfosToStoredDicts:(NSArray<HMDNetTrafficSourceUsageModel *> *)usageArray {
    NSMutableArray *reportArray = [NSMutableArray array];
    for (HMDNetTrafficSourceUsageModel *usageModel in usageArray) {
        NSDictionary *trafficInfo = @{
            kHMDTrafficBizUsageReportKeyPath: usageModel.souceId?:@"unknown",
            kHMDTrafficBizUsageReportKeyFreq: @(usageModel.executeCount),
            kHMDTrafficBizUsageReportKeyUsage: @(usageModel.usageBytes),
            kHMDTrafficBizUsageReportKeyBiz: usageModel.business?:@"unknown"
        };
        [reportArray hmd_addObject:trafficInfo];
    }
    return [reportArray copy];
}

@end

#pragma mark --- HMDNetTrafficBizUsageModel
@implementation HMDNetTrafficBizUsageModel (Report)

- (NSDictionary *)formatGroupByBizWithNeedSource:(BOOL)needSource {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:self.bizName?:@"unknown" forKey:kHMDTrafficReportKeyBizName];
    NSDictionary *usageInfo = @{
        kHMDTrafficReportUsageKeyInterval: @(self.totalUsage),
        kHMDTrafficReportUsageKeyWiFiFront: @(self.wifiFrontUsage),
        kHMDTrafficReportUsageKeyWiFiBack: @(self.wifiBackUsage),
        kHMDTrafficReportUsageKeyMobileFront: @(self.mobileFrontUsage),
        kHMDTrafficReportUsageKeyMobileBack: @(self.mobileBackUsage)
    };
    [dict hmd_setObject:usageInfo forKey:kHMDTrafficReportKeyBizUsageDetail];
    if (needSource && self.detailMap.count > 0) {
        NSMutableArray *sourceDetails = [NSMutableArray array];
        for (HMDNetTrafficSourceUsageModel *source in self.detailMap.allValues) {
            if ([source isKindOfClass:[HMDNetTrafficSourceUsageModel class]]) {
                NSDictionary *sourceUsageInfo = @{
                    kHMDTrafficReportUsageKeyInterval: @(source.totalUsage),
                    kHMDTrafficReportUsageKeyWiFiFront: @(source.wifiFrontUsage),
                    kHMDTrafficReportUsageKeyWiFiBack: @(source.wifiBackUsage),
                    kHMDTrafficReportUsageKeyMobileFront: @(source.mobileFrontUsage),
                    kHMDTrafficReportUsageKeyMobileBack: @(source.mobileBackUsage)
                };
                NSDictionary *sourceDetail = @{
                    kHMDTrafficReportKeySourceName: source.souceId?:@"unknown",
                    kHMDTrafficReportKeySourceUsageDetail: sourceUsageInfo?:@{}
                };
                [sourceDetails hmd_addObject:sourceDetail];
            }
        }
        [dict hmd_setObject:[sourceDetails copy] forKey:kHMDTrafficReportKeyBizSourceDetail];
    }

    return [dict copy];
}

@end

