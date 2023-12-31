//
//  HMDPerformanceReporterManager+HMDURLProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/8/22.
//

#import "HMDPerformanceReporterManager+HMDURLProvider.h"
// Utility
#import "HMDDynamicCall.h"
// Config
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings+URLHosts.h"
// DeviceInfo
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDPerformanceReporterManager (HMDURLProvider)

#pragma mark - HMDURLProvider

- (BOOL)shouldEncrypt {
    return self.needEncrypt;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    return nil;
    HMDGeneralAPISettings *settings = DC_IS(DC_OB(DC_CL(Heimdallr, shared), config), HMDHeimdallrConfig).apiSettings;
    return settings.performanceUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [HMDInjectedInfo defaultInfo].performanceUploadHosts;
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings performanceUploadDefaultHosts];
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings performanceUploadPath];
}

@end

@interface HMDPerformanceReporterURLPathProvider ()

@property (nonatomic, weak) id<HMDNetworkProvider> provider;

@end

@implementation HMDPerformanceReporterURLPathProvider

- (instancetype)initWithProvider:(id<HMDNetworkProvider>)provider {
    if (self = [super init]) {
        self.provider = provider;
    }
    return self;
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [self.provider reportPerformanceURLPath];
}

@end
