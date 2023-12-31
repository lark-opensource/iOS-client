//
//  HMDFileUploader+HMDURLProvider.m
//  AppHost-HeimdallrFinder-Unit-Tests
//
//  Created by Nickyo on 2023/8/18.
//

#import "HMDFileUploader+HMDURLProvider.h"
// Utility
#import "HMDDynamicCall.h"
// Config
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings+URLHosts.h"
// DeviceInfo
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDFileUploader (HMDURLProvider)

- (BOOL)shouldEncrypt {
    return NO;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    HMDGeneralAPISettings *settings = DC_IS(DC_OB(DC_CL(Heimdallr, shared), config), HMDHeimdallrConfig).apiSettings;
    return settings.fileUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [HMDInjectedInfo defaultInfo].fileUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings fileUploadDefaultHosts];
}

@end
