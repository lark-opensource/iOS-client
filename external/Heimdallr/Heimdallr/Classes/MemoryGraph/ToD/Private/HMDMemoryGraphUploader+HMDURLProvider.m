//
//  HMDMemoryGraphUploader+HMDURLProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/8/22.
//

#import "HMDMemoryGraphUploader+HMDURLProvider.h"
// Utility
#import "HMDDynamicCall.h"
// Config
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings+URLHosts.h"
// DeviceInfo
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDMemoryGraphUploader (HMDURLProvider)

#pragma mark - HMDURLProvider

- (BOOL)shouldEncrypt {
    return NO;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    return nil;
    HMDGeneralAPISettings *settings = DC_IS(DC_OB(DC_CL(Heimdallr, shared), config), HMDHeimdallrConfig).apiSettings;
    return settings.fileUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [HMDInjectedInfo defaultInfo].fileUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings fileUploadDefaultHosts];
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings memoryGraphUploadCheckPath];
}

@end
