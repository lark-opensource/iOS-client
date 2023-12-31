//
//  HMDNetTrafficMonitorRecord+TrafficUsage.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/9/2.
//

#import "HMDNetTrafficMonitorRecord+Report.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDNetTrafficMonitorRecord (Report)

+ (NSArray *)aggregateExceptionTrafficDataWithRecords:(NSArray<HMDNetTrafficMonitorRecord *> *)records
{
    NSMutableArray *exceptionTraffics = [NSMutableArray array];
    for (int index = 0; index < records.count; index ++) {
        HMDNetTrafficMonitorRecord *record = [records hmd_objectAtIndex:index];
        if (!record) { continue; }
        NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
        long long time = MilliSecond(record.timestamp);
        [dataDict setValue:@(time) forKey:@"timestamp"];
        [dataDict setValue:record.sessionID forKey:@"session_id"];
        [dataDict setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataDict setValue:@"traffic" forKey:@"service"];
        [dataDict setValue:@"performance_monitor" forKey:@"log_type"];
        [dataDict setValue:@(record.localID) forKey:@"log_id"];
        [dataDict setValue:@(record.netQualityType) forKey:@"network_quality"];

        NSMutableDictionary *extraValues = [NSMutableDictionary dictionary];
        [extraValues setValue:@(record.tenMinUsage) forKey:@"usage_10_minutes"];
        [dataDict setValue:extraValues forKey:@"extra_values"];

        NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
        [extraStatus setValue:record.scene forKey:@"scene"];
        [extraStatus setValue:record.frontType?:@"unknown" forKey:@"front"];
        [extraStatus setValue:record.netType?:@"unknown" forKey:@"net"];
        [dataDict setValue:extraStatus forKey:@"extra_status"];

        [dataDict setValue:@(record.isExceptionTraffic) forKey:@"exception"];
        if (record.exceptionTypes.count > 0) {
            [dataDict setValue:record.exceptionTypes forKey:@"exception_type"];
        }
        if (record.trafficDetail &&
            [record.trafficDetail isKindOfClass:[NSDictionary class]] &&
            record.trafficDetail.count > 0) {
            [dataDict setValue:record.trafficDetail forKey:@"detail"];
        }

        [exceptionTraffics hmd_addObject:dataDict];
    }

    return [exceptionTraffics copy];
}


- (NSDictionary *)reportDictionary
{
    if (hermas_enabled()) {
        NSMutableDictionary *dataValue = [[self class] intervalTrafficUsageReportDictWithRecord:self logType:@"performance_monitor"].mutableCopy;
        int64_t sequenceCode = self.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDNetTrafficMonitorRecord"] : -1;
        [dataValue hmd_setObject:@(self.enableUpload) forKey:@"enable_upload"];
        [dataValue hmd_setObject:@(sequenceCode) forKey:@"sequence_code"];
        [dataValue setValue:@"HMDNetTrafficMonitorRecord" forKey:@"class_name"];
        return [dataValue copy];
    } else {
        return [[self class] intervalTrafficUsageReportDictWithRecord:self logType:@"performance_monitor_debug"];
    }
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDNetTrafficMonitorRecord *> *)records
{
    NSMutableArray *reportArray = [NSMutableArray array];
    for (int index = 0; index < records.count; index ++) {
        HMDNetTrafficMonitorRecord *record = [records hmd_objectAtIndex:index];
        if (!record) { continue; }

        if (record.tenMinUsage > 0 || record.customExtraValue.count > 0) {
            NSDictionary *reportDict = [[self class] intervalTrafficUsageReportDictWithRecord:record logType:@"performance_monitor"];
            if (reportDict) {
                [reportArray hmd_addObject:reportDict];
            }
        }
    }
    return [reportArray copy];
}


+ (NSDictionary * _Nullable)intervalTrafficUsageReportDictWithRecord:(HMDNetTrafficMonitorRecord *)record logType:(NSString *)logType {
    if (!record) {
        return nil;
    }
    NSMutableDictionary *reportDict = [NSMutableDictionary dictionary];

    [reportDict setValue:@"traffic" forKey:@"service"];
    [reportDict setValue:logType forKey:@"log_type"];
    long long time = MilliSecond(record.timestamp);
    [reportDict setValue:@(time) forKey:@"timestamp"];
    [reportDict setValue:@(record.inAppTime) forKey:@"inapp_time"];
    [reportDict setValue:@(record.netQualityType) forKey:@"network_quality"];
    [reportDict setValue:record.sessionID forKey:@"session_id"];
    [reportDict setValue:@(record.localID) forKey:@"log_id"];

    NSMutableDictionary *extraStatus = [NSMutableDictionary dictionary];
    [extraStatus setValue:record.scene forKey:@"scene"];
    if (record.frontType && record.frontType.length > 0) {
        [extraStatus setValue:record.frontType forKey:@"front"];
    }
    if (record.netType && record.netType.length > 0) {
        [extraStatus setValue:record.netType forKey:@"net"];
    }
    if (record.customExtraStatus && record.customExtraStatus.count > 0) {
        [extraStatus addEntriesFromDictionary:record.customExtraStatus];
    }
    [reportDict setValue:extraStatus forKey:@"extra_status"];

    NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
    if (record.tenMinUsage > 0) {
        [extraValue setValue:@(record.tenMinUsage) forKey:@"usage_10_minutes"];
    }
    if (record.customExtraValue && record.customExtraValue.count > 0) {
        [extraValue addEntriesFromDictionary:record.customExtraValue];
    }
    [reportDict setValue:extraValue forKey:@"extra_values"];

    if (record.customExtra && record.customExtra.count > 0) {
        [reportDict setValue:record.customExtra forKey:@"extra"];
    }

    if (record.trafficDetail &&
        [record.trafficDetail isKindOfClass:[NSDictionary class]] &&
        record.trafficDetail.count > 0) {
        // 非异常上报只上报 uage 里面的内容;
        NSArray *usageInfoes = [record.trafficDetail hmd_objectForKey:@"usage" class:[NSArray class]];
        if ([usageInfoes isKindOfClass:[NSArray class]] && usageInfoes.count > 0) {
            NSMutableDictionary *detailUsage = [NSMutableDictionary dictionary];
            [detailUsage setValue:usageInfoes forKey:@"usage"];
            [reportDict setValue:detailUsage forKey:@"detail"];
        }
    }

    return [reportDict copy];
}


@end
