//
//  HMDHighPriorityModule.m
//  Heimdallr
//
//  Created by liuhan on 2023/8/14.
//

#import "HMDHighPriorityModule.h"
#import "HMDURLSettings.h"
#import "HMDGeneralAPISettings.h"
#import "HMDHermasUploadSetting.h"
#import "HMDHermasCleanupSetting.h"
#import "HMDHeimdallrConfig.h"
#import "HMDHermasHelper.h"
#import "HMDDoubleReporter.h"
#import "HMDInjectedInfo.h"
#import "HMDReportDowngrador.h"
#import "HMDDynamicCall.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP


NSString * const kModuleHighPriorityName = @"high_priority";
static double kTimeDelta;

@interface HMDHighPriorityModule ()

@end

@implementation HMDHighPriorityModule

- (instancetype)init {
    if (self = [super init]) {
        kTimeDelta = [NSDate date].timeIntervalSince1970 - CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (void)setupModuleConfig {
    HMModuleConfig *config = [[HMModuleConfig alloc] init];
    config.name = kModuleHighPriorityName;
    config.path = [HMDURLSettings highPriorityUploadPath];
    config.zstdDictType = @"monitor";
    config.enableRawUpload = YES;
    // 共享线程配置同步异常
    config.shareRecordThread = (self.recordThreadShareMask & 0b0010) == 0b0010;
    
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

- (void)updateModuleConfig:(HMDHeimdallrConfig * _Nullable)config {
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

- (void)updateRemoteHermasConfig {
    // cleanup
    HMDHermasCleanupSetting *hermasCleanupSetting = self.heimdallrConfig.cleanupConfig.hermasCleanupSetting;
    unsigned long maxStoreSize = hermasCleanupSetting.maxStoreSize * BYTE_PER_MB ?: 500 * BYTE_PER_MB;
   
    // devide the global maxStoreSize to module maxStoreSize
    self.config.maxStoreSize = maxStoreSize * 0.1;
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

@end
