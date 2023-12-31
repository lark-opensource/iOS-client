//
//  HMDControllerTimeManager+Report.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDControllerTimeManager+Report.h"
#import "HMDControllerTimeRecord.h"
#import "HMDPerformanceAggregate.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"



@implementation HMDControllerTimeManager (Report)

- (NSArray *)getAggregateDataWithRecords:(NSArray<HMDControllerTimeRecord *> *)records {
    if (records.count < 1) {
        return nil;
    }

    HMDPerformanceAggregate *aggregate = [[HMDPerformanceAggregate alloc] init];
    for (int index = 0; index < records.count; index ++) {
        HMDControllerTimeRecord *record = records[index];

        NSMutableDictionary *needAggregateDictionary = [NSMutableDictionary dictionary];

        NSMutableDictionary *extra_values = [NSMutableDictionary dictionary];
        NSString *type = record.typeName;
        if (type) {
            [extra_values hmd_setObject:@(record.timeInterval) forKey:type];
        }
        if (extra_values) {
            [needAggregateDictionary setValue:extra_values forKey:@"extra_values"];
        }

        NSMutableDictionary *normalDictionary = [NSMutableDictionary dictionary];
        [normalDictionary setValue:@"page_load" forKey:@"service"];
        [normalDictionary setValue:@"performance_monitor" forKey:@"log_type"];
        long long time = MilliSecond(record.timestamp);
        [normalDictionary setValue:@(time) forKey:@"timestamp"];
        [normalDictionary setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *keysDictionary = [NSMutableDictionary dictionary];
        [keysDictionary setValue:record.pageName forKey:@"scene"];
        [keysDictionary setValue:@(record.isFirstOpen) forKey:@"is_first_open"];

        [aggregate aggregateWithSessionID:record.sessionID aggregateKeys:keysDictionary needAggregateDictionary:needAggregateDictionary normalDictionary:normalDictionary listDictionary:nil currentecordIndex:index];
    }
    return [[aggregate getAggregateRecords] copy];
}


- (NSArray *)getDataWithRecords:(NSArray<HMDControllerTimeRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    for (HMDControllerTimeRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];

        long long time = MilliSecond(record.timestamp);
        [dataValue setValue:@(time) forKey:@"timestamp"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:@"page_load" forKey:@"service"];
        [dataValue setValue:@"performance_monitor_debug" forKey:@"log_type"];
        [dataValue setValue:@(record.localID) forKey:@"log_id"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
        NSString *type = record.typeName;
        if (type) {
            [extraValue setValue:@(record.timeInterval) forKey:type];
        }
        [dataValue setValue:extraValue forKey:@"extra_values"];

        NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
        [extraStatus setValue:record.pageName forKey:@"scene"];
        [extraStatus setValue:@(record.isFirstOpen) forKey:@"is_first_open"];

        [dataValue setValue:extraStatus forKey:@"extra_status"];

        [dataArray addObject:dataValue];
    }
    return [dataArray copy];
}

@end
