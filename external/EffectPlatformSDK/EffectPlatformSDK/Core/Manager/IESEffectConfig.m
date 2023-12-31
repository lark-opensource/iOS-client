//
//  IESEffectConfig.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/2/25.
//

#import "IESEffectConfig.h"
#import <EffectPlatformSDK/IESEffectDefines.h>

#include <sys/sysctl.h>

static NSString *kdevicePlatform = @"iphone";

static NSString *getDeveiceType() {
    static NSString *deviceType = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char *info = "hw.machine";
        size_t size;
        sysctlbyname(info, NULL, &size, NULL, 0);
        char *answer = malloc(size);
        sysctlbyname(info, answer, &size, NULL, 0);
        deviceType = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
        free(answer);
    });
    return deviceType;
}

@implementation IESEffectConfig

- (instancetype)init {
    if (self = [super init]) {
        _enableAutoCleanCache = YES;
        _effectManifestQuota = 1024 * 1024 * 5;
        _effectsDirectoryQuota = 1024 * 1024 * 300;
        _algorithmsDirectoryQuota = 1024 * 1024 * 100;
        _tmpDirectoryQuota = 1024 * 1024 * 50;
        _downloadOnlineEnviromentModel = YES;
    }
    return self;
}

- (NSString *)effectManifestPath {
    return [self.rootDirectory stringByAppendingPathComponent:@"effects_manifest.db"];
}

- (NSString *)effectsDirectory {
    return [self.rootDirectory stringByAppendingPathComponent:@"effects"];
}

- (NSString *)algorithmsDirectory {
    return [self.rootDirectory stringByAppendingPathComponent:@"algorithms"];
}

- (NSString *)tmpDirectory {
    return [self.rootDirectory stringByAppendingPathComponent:@"tmp"];
}

- (NSDictionary *)commonParameters {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    // System infomation
    parameters[@"device_id"] = (self.deviceIdentifier ?: [UIDevice currentDevice].identifierForVendor.UUIDString) ?: @"";
    parameters[@"device_platform"] = @"iphone";
    parameters[@"device_type"] = getDeveiceType() ?: @"";
    parameters[@"os_version"] = self.osVersion ?: @"";
    
    // Applicatoin infomation
    parameters[@"aid"] = self.appID ?: @"";
    parameters[@"package_name"] = self.bundleIdentifier ?: @"";
    parameters[@"app_name"] = self.appName ?: @"";
    parameters[@"app_version"] = self.appVersion ?: @"";
    parameters[@"sdk_version"] = self.effectSDKVersion ?: @"";
    parameters[@"platformSDKVersion"] = IESEffectPlatformSDKVersion ?: @"";
    parameters[@"platform_sdk_version"] = IESEffectPlatformSDKVersion ?: @"";
    
    // Other infomation
    parameters[@"channel"] = self.channel ?: @"App Store";
    parameters[@"region"] = self.region ?: @"";
    if (self.networkParametersBlock) {
        [parameters addEntriesFromDictionary:self.networkParametersBlock() ?: @{}];
    }
    
    return parameters.copy;
}

- (void)setNetworkParametersBlock:(NSDictionary * _Nonnull (^)(void))networkParametersBlock {
    _networkParametersBlock = networkParametersBlock;
    NSDictionary *networkParameters = networkParametersBlock() ?: @{};
    if ([networkParameters objectForKey:@"device_platform"]) {
        kdevicePlatform = networkParameters[@"device_platform"];
    }
}

+ (NSString *)devicePlatform {
    return kdevicePlatform;
}

- (NSDictionary *)effectSDKResourceBundleConfig
{
    NSString *configJsonPath = [[self effectSDKResourceBundlePath] stringByAppendingPathComponent:@"effect_local_config.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:configJsonPath]) {
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:configJsonPath];
        if (jsonData) {
            return [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        }
    }
    return nil;
}

@end
