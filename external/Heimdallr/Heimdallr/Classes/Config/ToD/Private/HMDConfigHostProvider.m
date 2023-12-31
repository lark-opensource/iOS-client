//
//  HMDConfigHostProvider.m
//  Heimdallr
//
//  Created by Nickyo on 2023/4/18.
//

#import "HMDConfigHostProvider.h"
// Utility
#import "NSArray+HMDSafe.h"
// Config
#import "HMDHeimdallrConfig.h"
#import "HMDGeneralAPISettings+URLHosts.h"
// DeviceInfo
#import "HMDInjectedInfo+URLHosts.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDConfigHostProvider

#pragma mark - HMDURLProvider

- (BOOL)shouldEncrypt {
    return NO;
}

- (NSArray<NSString *> *)URLHostProviderConfigHosts:(NSString *)appID {
    return [self _standardizeHosts:[self.dataSource mainConfig].apiSettings.configFetchHosts];
}

- (NSArray<NSString *> *)URLHostProviderInjectedHosts:(NSString *)appID {
    return [self _standardizeHosts:[HMDInjectedInfo defaultInfo].configFetchHosts];
}

- (NSArray<NSString *> *)URLHostProviderDefaultHosts:(NSString *)appID {
    return [HMDURLSettings configFetchDefaultHosts];
}

- (NSArray<NSString *> *)_standardizeHosts:(NSArray<NSString *> *)array {
    NSMutableArray<NSString *> *hosts = [NSMutableArray arrayWithCapacity:array.count];
    [array hmd_enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *host = [self.dataSource standardizeHost:obj] ?: obj;
        if (host.length > 0 && ![hosts containsObject:host]) {
            [hosts addObject:host];
        }
    } class:[NSString class]];
    return [hosts copy];
}

- (NSString *)URLPathProviderURLPath:(NSString *)appID {
    return [HMDURLSettings configFetchPath];
}

@end
