//
//  HMDGameURLProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/8/10.
//

#import "HMDGameURLProvider.h"
#import "Heimdallr+Private.h"
#import "HMDCommonAPISetting.h"
#import "HMDGeneralAPISettings+URLHosts.h"
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDGameTracker (HMDURLProvider)

#pragma mark - HMDURLProvider

- (BOOL)shouldEncrypt {
    HMDGeneralAPISettings *settings = self.heimdallr.config.apiSettings;
    if (settings.crashUploadSetting) {
        return settings.crashUploadSetting.enableEncrypt;
    }
    return settings.allAPISetting.enableEncrypt;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    HMDGeneralAPISettings *settings = self.heimdallr.config.apiSettings;
    return settings.crashUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [HMDInjectedInfo defaultInfo].crashUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings crashUploadDefaultHosts];
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings crashUploadPath];
}

@end
