//
//  HMDPerformanceModule.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 5/6/2022.
//

#import "HMDPerformanceModule.h"
#import "HMDDynamicCall.h"
#import "HMDGeneralAPISettings.h"
#import "HMDHermasUploadSetting.h"
#import "HMDHermasCleanupSetting.h"
#import "HMDHeimdallrConfig.h"
#import "HMDHermasHelper.h"
#import "HMDDoubleReporter.h"
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+MovingLine.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDNetworkReqModel.h"
#import "HMDNetworkManager.h"
#import "HMDStoreIMP.h"
#import "HMDRecordStore.h"
#import "HMDUploadHelper.h"
#import "HMDReportDowngrador.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDURLSettings.h"

NSString * const kModulePerformaceName = @"batch";
static double kTimeDelta;

@interface HMDPerformanceModule ()

@end

@implementation HMDPerformanceModule {
    
}

- (instancetype)init {
    if (self = [super init]) {
        kTimeDelta = [NSDate date].timeIntervalSince1970 - CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (void)setupModuleConfig {
    HMModuleConfig *config = [[HMModuleConfig alloc] init];
    config.name = kModulePerformaceName;
    config.path = [HMDURLSettings performanceUploadPath];
    config.zstdDictType = @"monitor";
    config.enableRawUpload = YES;
    config.shareRecordThread = (self.recordThreadShareMask & 0b0001) == 0b0001;
    HMAggregateParam *aggregateParam = [[HMAggregateParam alloc] init];
    aggregateParam.aggreIntoMax = @{@"cpu" : @[@"peak_usage"]};
    config.aggregateParam = aggregateParam;
    config.maxLocalStoreSize = [HMDInjectedInfo defaultInfo].performanceLocalMaxStoreSize * BYTE_PER_MB;
    config.cloudCommandBlock = ^(NSData * _Nonnull encyptedData, NSString * _Nonnull ran) {
        @autoreleasepool {
            DC_OB(DC_CL(HMDCloudCommandManager, sharedInstance), executeCommandWithData:ran:, encyptedData, ran);
        }
    };
    
    config.downgradeRuleUpdateBlock = ^(NSDictionary * _Nullable rule) {
        @autoreleasepool {
            [[HMDReportDowngrador sharedInstance] updateDowngradeRule:rule];
        }
    };
    
    config.downgradeBlock = ^BOOL(NSString * _Nonnull logType, NSString * _Nullable serviceName, NSString * _Nonnull aid, double currentTime) {
        // CFAbsoluteTimeGetCurrent's reference date is 00:00:00 1 January 2001
        // while CurTimeSecond's reference data is 00:00:00 UTC on 1 January 1970
        // so we need to adjust currentTime with kTimeDelta
        BOOL ret = NO;
        @autoreleasepool {
            currentTime -= kTimeDelta;
            ret = [[HMDReportDowngrador sharedInstance] needUploadWithLogType:logType serviceName:serviceName aid:aid currentTime:currentTime];
        }
        return ret;
    };
    
    config.tagVerifyBlock = ^BOOL(NSInteger tag) {
        @autoreleasepool {
            NSNumber *retNumber;
            retNumber = DC_ET(DC_CL(HMDTTMonitorTagHelper, verifyMonitorTag:, tag), NSNumber);
            return retNumber.boolValue;
        }
    };
    
    self.config = config;
    [[HMEngine sharedEngine] addModuleWithConfig:config];
}

- (void)updateModuleConfig:(HMDHeimdallrConfig *)config {
    self.heimdallrConfig = config;
    
    // max store size config
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
    self.config.maxStoreSize = maxStoreSize * 0.5;
    
    self.config.maxLocalStoreSize = [HMDInjectedInfo defaultInfo].performanceLocalMaxStoreSize * BYTE_PER_MB;
}

- (void)updateEncryptConfig {
    HMDHeimdallrConfig *heimdallrConfig = self.heimdallrConfig;
    // batch enableEncrypt
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
    HMDDoubleUploadSettings *doubleUploadSettings = self.heimdallrConfig.apiSettings.doubleUploadSetting;
    self.config.forwardEnabled = YES;
    self.config.forwardUrl = [doubleUploadSettings.hostAndPath firstObject];

    // update for double reporter
    [[HMDDoubleReporter sharedReporter] update:self.heimdallrConfig];
}


- (void)updateDomainConfig {
    // batch
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
    NSArray *recordNames = @[@"HMDBatteryMonitorRecord",
                             @"HMDCPUMonitorRecord",
                             @"HMDDiskMonitorRecord",
                             @"HMDFPSMonitorRecord",
                             @"HMDFrameDropRecord",
                             @"HMDMemoryMonitorRecord",
                             @"HMDTTMonitorRecord",
                             @"HMDControllerTimeRecord",
                             @"HMDUITrackRecord",
                             @"HMDHTTPDetailRecord",
                             @"HMDNetTrafficMonitorRecord",
                             @"HMDLaunchTimingRecord",
                             @"HMDStartRecord"];
    [recordNames enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cls = NSClassFromString(name);
        if (cls && [cls respondsToSelector:@selector(tableName)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
            [dic setValue:cls forKey:[cls tableName]];
#pragma clang diagnostic pop
        }
    }];
    return [dic copy];
}

- (NSArray *)conditionArrayWithTableName:(NSString *)recordClassName {
    NSMutableArray *conditions = @[].mutableCopy;
    
    HMDStoreCondition *condition0 = [[HMDStoreCondition alloc] init];
    condition0.key = [recordClassName isEqualToString:@"HMDTTMonitorRecord"] ? @"needUpload" : @"enableUpload";
    condition0.threshold = 0;
    condition0.judgeType = HMDConditionJudgeGreater;
    [conditions addObject:condition0];
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = [[NSDate date] timeIntervalSince1970];
    condition1.judgeType = HMDConditionJudgeLess;
    [conditions addObject:condition1];
    
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];
    if (ignoreTime > 0) {
        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"timestamp";
        condition2.threshold =
        condition2.judgeType = HMDConditionJudgeGreater;
        [conditions addObject:condition2];
    }
    
    return conditions;
}


@end
