//
//  HMDUserExceptionModuleReporter+HMDURLProvider.m
//  HeimdallrFinder
//
//  Created by Nickyo on 2023/8/21.
//

#import "HMDUserExceptionModuleReporter+HMDURLProvider.h"
// Utility
#import "HMDDynamicCall.h"
// Config
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings+URLHosts.h"
// DeviceInfo
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDUserExceptionModuleReporter (HMDURLProvider)

#pragma mark - HMDURLProvider

- (BOOL)shouldEncrypt {
    return self.needEncrypt;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    return nil;
    HMDGeneralAPISettings *settings = DC_IS(DC_OB(DC_CL(Heimdallr, shared), config), HMDHeimdallrConfig).apiSettings;
    return settings.userExceptionUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [HMDInjectedInfo defaultInfo].userExceptionUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings userExceptionUploadDefaultHosts];
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings userExceptionUploadPath];
}

@end
