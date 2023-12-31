//
//  HMDDiskMonitorRecord.m
//  Heimdallr
//
//  Created by fengyadong on 2018/6/14.
//

#import "HMDDiskMonitorRecord.h"
#import "HMDMacro.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDDiskMonitorRecord

- (HMDMonitorRecordValue)value {
    return self.appUsage;
}

- (NSDictionary *)reportDictionary {
    if (hermas_enabled()) {
        return [self reportDictionaryForLogTyepe:@"performance_monitor"];
    } else {
        return [self reportDictionaryForLogTyepe:@"performance_monitor_debug"];
    }
    
}

- (NSDictionary *)reportDictionaryForLogTyepe:(NSString *)logType {
    NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
    
    long long time = MilliSecond(self.timestamp);
    
    [dataValue setValue:@(time) forKey:@"timestamp"];
    [dataValue setValue:self.sessionID forKey:@"session_id"];
    [dataValue setValue:@(self.inAppTime) forKey:@"inapp_time"];
    [dataValue setValue:@"disk" forKey:@"service"];
    [dataValue setValue:self.scene forKey:@"scene"];
    [dataValue setValue:logType forKey:@"log_type"];
    [dataValue setValue:@(self.localID) forKey:@"log_id"];
    [dataValue setValue:@(self.netQualityType) forKey:@"network_quality"];

    if (self.topFileLists.count > 0) {
        [dataValue setValue:self.topFileLists forKey:@"top_usage"];
    }
    if (self.exceptionFolders.count > 0) {
        [dataValue setValue:self.exceptionFolders forKey:@"exception_folders"];
    }
    if (self.outdatedFiles.count > 0) {
        [dataValue setValue:self.outdatedFiles forKey:@"outdated_files"];
    }
    if (self.diskInfo.count > 0) {
        [dataValue setValue:self.diskInfo forKey:@"disk_info"];
    }
    
    NSMutableDictionary *extraValue = [NSMutableDictionary dictionary];
    [extraValue setValue:@(self.appUsage) forKey:@"app_usage"];
    [extraValue setValue:@(self.totalDiskLevel) forKey:@"d_zoom_all"];
    [extraValue setValue:@(self.freeBlockCounts) forKey:@"d_zoom_free"];
    if (self.pageUsage > 0) {
        [extraValue setValue:@(self.pageUsage) forKey:@"page_usage"];
    }
    if (self.documentsAndDataUsage > 0) {
        [extraValue setValue:@(self.documentsAndDataUsage) forKey:@"documents_data_usage"];
    }

    [dataValue setValue:extraValue forKey:@"extra_values"];
    [dataValue setValue:@(self.enableUpload) forKey:@"enable_upload"];

    if (hermas_enabled() && !self.needAggregate) {
        self.sequenceCode = self.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:NSStringFromClass([self class])] : -1;
        [dataValue setValue:@(self.sequenceCode) forKey:@"sequence_code"];
    }
    return dataValue;
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDDiskMonitorRecord *> *)records
{
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDDiskMonitorRecord *record in records) {
        NSDictionary *dataValue = [record reportDictionaryForLogTyepe:@"performance_monitor"];
        if (dataValue) {
            [dataArray addObject:dataValue];
        }
    }
    
    return dataArray;
}

+ (NSUInteger)cleanupWeight {
    return 20;
}

- (BOOL)needAggregate {
    return NO;
}

@end
