//
//  HMDCrashURLHostProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/8/1.
//

#if !SIMPLIFYEXTENSION

#import "HMDCrashURLHostProvider.h"
#import "HMDCrashConfig.h"
#import "HMDCommonAPISetting.h"
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDCrashTracker (HMDURLHostProvider)

#pragma mark - HMDURLHostProvider

- (BOOL)shouldEncrypt {
    HMDCrashConfig *config = [self __crashConfig];
    if (config.crashUploadSetting) {
        return config.crashUploadSetting.enableEncrypt;
    }
    return config.allAPISetting.enableEncrypt;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    HMDCrashConfig *config = [self __crashConfig];
    if (config.crashUploadSetting.hosts.count > 0) {
        return config.crashUploadSetting.hosts;
    }
    return config.allAPISetting.hosts;
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [HMDInjectedInfo defaultInfo].crashUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings crashUploadDefaultHosts];
}

- (HMDCrashConfig *)__crashConfig {
    if ([self.config isKindOfClass:[HMDCrashConfig class]]) {
        return (HMDCrashConfig *)self.config;
    }
    return nil;
}

@end

#endif /* SIMPLIFYEXTENSION */
