//
//  HMDOpenTracingModule.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 5/6/2022.
//

#import "HMDOpenTracingModule.h"
#import "HMDDynamicCall.h"
#import "HMDGeneralAPISettings.h"
#import "HMDHermasUploadSetting.h"
#import "HMDHermasCleanupSetting.h"
#import "HMDHeimdallrConfig.h"
#import "HMDHermasHelper.h"
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+MovingLine.h"
#import "HMDMacro.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"
#import "HMDRecordStoreObject.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDURLSettings.h"

NSString * const kModuleOpenTraceName = @"trace_collect";
static NSInteger const kUploadLimictCount = 10;

@protocol HMDOpenTracingModuleDelegate <NSObject>
- (NSDictionary *)reportDictionary;
- (NSString *)traceID;
@end

@implementation HMDOpenTracingModule {
    Class _traceClass;
    Class _spanClass;
}

- (instancetype)init {
    if (self = [super init]) {
        _traceClass = NSClassFromString(@"HMDOTTrace");
        _spanClass = NSClassFromString(@"HMDOTSpan");
    }
    return self;
}

- (void)setupModuleConfig {
    HMModuleConfig *config = [[HMModuleConfig alloc] init];
    config.name = kModuleOpenTraceName;
    config.path = [HMDURLSettings tracingUploadPathWithMultipleHeader];
    config.zstdDictType = @"monitor";
    config.enableRawUpload = YES;
    config.isForbidSplitReportFile = YES;
    config.shareRecordThread = (self.recordThreadShareMask & 0b1000) == 0b1000;
    config.maxLocalStoreSize = [HMDInjectedInfo defaultInfo].traceLocalMaxStoreSize * BYTE_PER_MB;
    self.config = config;
    [[HMEngine sharedEngine] addModuleWithConfig:config];
}

- (void)updateModuleConfig:(HMDHeimdallrConfig *)config {
    self.heimdallrConfig = config;
    
    // global config
    [self updateRemoteHermasConfig];
    
    // encrypt config
    [self updateEncryptConfig];
    
    // double config
    [self updateDoubleUploadConfig];
    
    // domain config
    [self updateDomainConfig];
    
    // sync config to hermas engine
    [self syncConfigToHermasEngine];
}

#pragma mark - Private

- (void)updateRemoteHermasConfig {
    // cleanup
    HMDHermasCleanupSetting *hermasCleanupSetting = self.heimdallrConfig.cleanupConfig.hermasCleanupSetting;
    unsigned long maxStoreSize = hermasCleanupSetting.maxStoreSize * BYTE_PER_MB ?: 500 * BYTE_PER_MB;
   
    // devide the global maxStoreSize to module maxStoreSize
    self.config.maxStoreSize = maxStoreSize * 0.1;
    
    self.config.maxLocalStoreSize = [HMDInjectedInfo defaultInfo].traceLocalMaxStoreSize * BYTE_PER_MB;
}

- (void)updateEncryptConfig {
    // encrypt (the same as batch)
    HMDHeimdallrConfig *heimdallrConfig = self.heimdallrConfig;
    if (heimdallrConfig.apiSettings.performanceAPISetting) {
        self.config.enableEncrypt = heimdallrConfig.apiSettings.performanceAPISetting.enableEncrypt;
    } else if (heimdallrConfig.apiSettings.allAPISetting) {
        self.config.enableEncrypt = heimdallrConfig.apiSettings.allAPISetting.enableEncrypt;
    } else {
        self.config.enableEncrypt = NO;
    }
}

- (void)updateDoubleUploadConfig {
    // double upload
    self.config.forwardEnabled = NO;
}


- (void)updateDomainConfig {
    // domain (the same as batch)
//    self.config.domain = @"slardar-test.bytedance.net";
    HMDGeneralAPISettings *apiSettings = self.heimdallrConfig.apiSettings;
    if (apiSettings.performanceAPISetting.hosts.count) {
        self.config.domain = [apiSettings.performanceAPISetting.hosts firstObject];
    } else if (apiSettings.allAPISetting.hosts.count) {
        self.config.domain = [apiSettings.allAPISetting.hosts firstObject];
    } else if ([HMDInjectedInfo defaultInfo].performanceUploadHost.length > 0) {
        self.config.domain = [HMDInjectedInfo defaultInfo].performanceUploadHost;
    } else if ([HMDInjectedInfo defaultInfo].allUploadHost.length > 0) {
        self.config.domain = [HMDInjectedInfo defaultInfo].allUploadHost;
    } else {
        self.config.domain = [[HMDURLSettings performanceUploadDefaultHosts] firstObject];
    }
}

- (void)syncConfigToHermasEngine {
    [[HMEngine sharedEngine] updateModuleConfig:self.config];
}

#pragma mark - Migration

- (NSDictionary *)dataBaseTableMap {
    NSMutableDictionary *dic = @{}.mutableCopy;
    if (_traceClass && _spanClass) {
        [dic hmd_setObject:_traceClass forKey:[_traceClass tableName]];
        [dic hmd_setObject:_spanClass forKey:[_spanClass tableName]];
    }
    return [dic copy];
}

- (NSArray *)fetchDataFromDatabase {
    NSMutableArray *results = [NSMutableArray array];
    
    NSArray *traces = [self.database getObjectsWithTableName:[_traceClass tableName]
                                                       class:_traceClass
                                               andConditions:nil
                                                orConditions:nil
                                                       limit:kUploadLimictCount];
    
    NSMutableArray *orConditions = [NSMutableArray array];
    for(id trace in traces) {
        NSDictionary *traceResult = [trace reportDictionary];
        if (traceResult) {
            [results addObject:traceResult];
        }
        
        HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
        condition.judgeType = HMDConditionJudgeEqual;
        condition.key = @"traceID";
        condition.stringValue = [trace traceID];
        
        [orConditions addObject:condition];
    }
    
    NSArray *records = [self.database getObjectsWithTableName:@"HMDOTSpan"
                                                        class:_spanClass
                                                andConditions:nil
                                                 orConditions:orConditions];
    
    NSArray *spanResults = [_spanClass reportDataForRecords:records];
    if(spanResults.count > 0) {
        [results addObjectsFromArray:spanResults];
    }
    
    // record operation
    HMDDatabaseOperationRecord *operationRecord = [[HMDDatabaseOperationRecord alloc] init];
    operationRecord.tableName = @"HMDOTSpan";
    operationRecord.orConditions = [orConditions copy];
    operationRecord.limitCount = kUploadLimictCount;
    [self.operationRecords addObject:operationRecord];

    return results;
}

- (void)dataDidReportSuccess:(BOOL)success {
    if (success) {
        [self.database inTransaction:^BOOL{
            HMDDatabaseOperationRecord *operationRecord = self.operationRecords.firstObject;
            BOOL deleteTraceSuccess = [self.database deleteObjectsFromTable:[self->_traceClass tableName] andConditions:nil orConditions:operationRecord.orConditions limit:operationRecord.limitCount];
            BOOL deleteSpanSuccess = [self.database deleteObjectsFromTable:operationRecord.tableName andConditions:operationRecord.andConditions orConditions:operationRecord.orConditions limit:operationRecord.limitCount];
            return deleteTraceSuccess && deleteSpanSuccess;
        }];
    }
    [self.operationRecords removeAllObjects];
    
    [self reportHeimdallrNeedUploadedData];
}

@end
