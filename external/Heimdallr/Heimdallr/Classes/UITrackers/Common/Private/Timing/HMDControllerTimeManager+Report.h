//
//  HMDControllerTimeManager+Report.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDControllerTimeManager.h"

@interface HMDControllerTimeManager (Report)

- (NSArray *)getAggregateDataWithRecords:(NSArray<HMDControllerTimeRecord *> *)records;
- (NSArray *)getDataWithRecords:(NSArray<HMDControllerTimeRecord *> *)records;

@end
