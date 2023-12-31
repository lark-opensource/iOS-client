//
//  HMDWatchdogProtectRecord.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import "HMDWatchdogProtectRecord.h"

NSString * const kHMDWatchdogProtectTableName = @"HMDWatchdogProtect";

@implementation HMDWatchdogProtectRecord

+ (NSString *)tableName {
    return kHMDWatchdogProtectTableName;
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

+ (instancetype)newRecord {
    __kindof HMDWatchdogProtectRecord *record = [super newRecord];
    return record;
}

@end
