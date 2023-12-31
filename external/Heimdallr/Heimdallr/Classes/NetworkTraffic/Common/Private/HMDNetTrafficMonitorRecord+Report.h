//
//  HMDNetTrafficMonitorRecord+TrafficUsage.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/9/2.
//

#import "HMDNetTrafficMonitorRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDNetTrafficMonitorRecord (Report)

+ (NSArray *)aggregateExceptionTrafficDataWithRecords:(NSArray<HMDNetTrafficMonitorRecord *> *)records;

@end

NS_ASSUME_NONNULL_END
