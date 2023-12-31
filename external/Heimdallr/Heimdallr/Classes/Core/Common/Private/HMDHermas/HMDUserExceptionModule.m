//
//  HMDUserExceptionModule.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 5/6/2022.
//

#import "HMDUserExceptionModule.h"
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

NSString * const kModuleUserExceptionName = @"ios_custom_exception";

@implementation HMDUserExceptionModule

- (void)setupModuleConfig {
    HMModuleConfig *config = [[HMModuleConfig alloc] init];
    config.name = kModuleUserExceptionName;
    config.path = [HMDURLSettings userExceptionUploadPathWithMultipleHeader];
    config.zstdDictType = @"monitor";
    config.enableRawUpload = YES;
    config.shareRecordThread = (self.recordThreadShareMask & 0b0100) == 0b0100;
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
    self.config.maxStoreSize = maxStoreSize * 0.2;
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
    // user_exception
//    self.config.domain = @"slardar-test.bytedance.net";
    HMDGeneralAPISettings *apiSettings = self.heimdallrConfig.apiSettings;
    if (apiSettings.exceptionUploadSetting.hosts.count) {
        self.config.domain = [apiSettings.exceptionUploadSetting.hosts firstObject];
    } else if (apiSettings.allAPISetting.hosts.count) {
        self.config.domain = [apiSettings.allAPISetting.hosts firstObject];
    } else if ([HMDInjectedInfo defaultInfo].userExceptionUploadHost.length > 0) {
        self.config.domain = [HMDInjectedInfo defaultInfo].userExceptionUploadHost;
    } else if ([HMDInjectedInfo defaultInfo].allUploadHost.length > 0) {
        self.config.domain = [HMDInjectedInfo defaultInfo].allUploadHost;
    } else {
        self.config.domain = [[HMDURLSettings userExceptionUploadDefaultHosts] firstObject];
    }
}

- (void)syncConfigToHermasEngine {
    [[HMEngine sharedEngine] updateModuleConfig:self.config];
}

- (NSDictionary *)dataBaseTableMap {
    NSMutableDictionary *dic = @{}.mutableCopy;
    Class cls = NSClassFromString(@"HMDUserExceptionRecord");
    if (cls) {
        [dic setValue:cls forKey:@"user_exception"];
    }
    
    return [dic copy];
}



@end
