//
//  HMDExceptionModule.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 5/6/2022.
//

#import "HMDExceptionModule.h"
#import "HMDDynamicCall.h"
#import "HMDGeneralAPISettings.h"
#import "HMDHermasUploadSetting.h"
#import "HMDHermasCleanupSetting.h"
#import "HMDHeimdallrConfig.h"
#import "HMDHermasHelper.h"
#import "HMDInjectedInfo.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDURLSettings.h"

NSString * const kModuleExceptionName = @"collect";

@implementation HMDExceptionModule

- (void)setupModuleConfig {
    HMModuleConfig *config = [[HMModuleConfig alloc] init];
    config.name = kModuleExceptionName;
    config.path = [HMDURLSettings exceptionUploadPathWithMultipleHeader];
    config.zstdDictType = @"monitor";
    config.enableRawUpload = YES;
    config.enableEncrypt = NO;
    config.shareRecordThread = (self.recordThreadShareMask & 0b0010) == 0b0010;
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
    NSUInteger maxStoreSize = self.heimdallrConfig.cleanupConfig.expectedDBSize;
    
    // devide the global maxStoreSize to module maxStoreSize
    self.config.maxStoreSize = maxStoreSize * 0.1;
}

- (void)updateEncryptConfig {
    HMDHeimdallrConfig *heimdallrConfig = self.heimdallrConfig;
    
    // collect enableEncrypt
    if (heimdallrConfig.apiSettings.exceptionUploadSetting) {
        self.config.enableEncrypt = heimdallrConfig.apiSettings.exceptionUploadSetting.enableEncrypt;
    } else if (heimdallrConfig.apiSettings.allAPISetting){
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
//    self.config.domain = @"slardar-test.bytedance.net";
    HMDGeneralAPISettings *apiSettings = self.heimdallrConfig.apiSettings;

    // collect
    if (apiSettings.exceptionUploadSetting.hosts.count) {
        self.config.domain = [apiSettings.exceptionUploadSetting.hosts firstObject];
    } else if (apiSettings.allAPISetting.hosts.count) {
        self.config.domain = [apiSettings.allAPISetting.hosts firstObject];
    } else if ([HMDInjectedInfo defaultInfo].exceptionUploadHost.length > 0) {
        self.config.domain = [HMDInjectedInfo defaultInfo].exceptionUploadHost;
    } else if ([HMDInjectedInfo defaultInfo].allUploadHost.length > 0) {
        self.config.domain = [HMDInjectedInfo defaultInfo].allUploadHost;
    } else {
        self.config.domain = [[HMDURLSettings exceptionUploadDefaultHosts] firstObject];
    }
}

- (void)syncConfigToHermasEngine {
    [[HMEngine sharedEngine] updateModuleConfig:self.config];
}


/// CaptureBacktrace、MetricKit 没有表，
/// OOMDetector有表，但是不需要处理
- (NSDictionary *)dataBaseTableMap {
    NSMutableDictionary *dic = @{}.mutableCopy;
    NSArray *recordNames = @[@"HMDExceptionRecord",
                         @"HMDCPUExceptionV2Record",
                         @"HMDWatchdogProtectRecord",
                         @"HMDANRRecord",
                         @"HMDWatchDogRecord",
                         @"HMDUIFrozenRecord",
                         @"HMDOOMCrashRecord",
                         @"HMDFDRecord",
                         @"HMDDartRecord",
                         @"HMDGameRecord"];
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

- (BOOL)shouldCareEnableUpload:(NSString *)recordClassName {
    NSArray *enableUploadTables = @[
        @"HMDExceptionRecord",
        @"HMDANRRecord",
        @"HMDDartRecord",
        @"HMDGameRecord"
    ];
    return [enableUploadTables containsObject:recordClassName];
}

@end
