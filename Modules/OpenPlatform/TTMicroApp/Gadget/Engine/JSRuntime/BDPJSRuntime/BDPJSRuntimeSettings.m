//
//  BDPJSRuntimeSettings.m
//  TTMicroApp
//
//  Created by MJXin on 2021/12/16.
//

#import "BDPJSRuntimeSettings.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPTimorClient.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import "BDPTaskManager.h"

NSString * const kUseV2Prefetch = @"openplatform.request.v2.prefetch";
NSString * const kForceDisablePrefetch =  @"openplatform.request.disable.prefetch";
NSString * const kUseNewNetworkAPISettingsKey =  @"use_new_network_api";
NSString * const kRequestSettingsKey =  @"request";
NSString * const kUploadFileSettingsKey =  @"upload";
NSString * const kDownloadFileSettingsKey =  @"download";
NSString * const kDefaultSettingsKey =  @"default";
NSString * const kForceDisableSettingsKey =  @"forceDisable";

@implementation BDPJSRuntimeSettings
+ (BOOL)isUsePrefetch:(OPAppUniqueID *)uniqueID {
    if ([EEFeatureGating boolValueForKey:kForceDisablePrefetch]) {
        return NO;
    }
    BDPTask* appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
    if(appTask.config.prefetches.count > 0 || appTask.config.prefetchRules.count > 0) {
        return  YES;
    }
    return NO;
}

/// 网络 API 版本控制逻辑
/// 详见: https://bytedance.feishu.cn/docx/doxcnF5f4Oj4qo0x1j8Xuakwarc
+ (BOOL)getNetworkAPIVersionFromLarkSettings:(NSDictionary<NSString *, NSNumber *> *)settings
                           appConfig:(BDPNetworkAPIVersionType)appConfig
                 withUniqueID:(OPAppUniqueID *)uniqueID {
    // 没有线上配置, 强制走旧版
    if (!settings) {
        return NO;
    }
    // 如果 settings 开启了强关, 那么强制用旧版 API
    if([settings[kForceDisableSettingsKey] boolValue]) {
        return NO;
    }
    
    // 如果 settings 中强制约束了 appid 使用的 API 版本,则使用 Settings 的设置
    NSString *appID = uniqueID.appID;
    if(appID && appID.length > 0 && settings[appID] != nil) {
        return [settings[appID] boolValue];
    }

    // 如果 settings[default] 为 true, 或者 app.json 中设置了 v2. 则使用新版网络 API
    return [settings[kDefaultSettingsKey] boolValue] || appConfig == BDPNetworkAPIVersionTypeV2;
}

+ (NSDictionary<NSString *, NSNumber *> *)getNetworkAPISettingsWithUniqueID:(OPAppUniqueID *)uniqueID {
    NSString* appID = uniqueID.appID;
    BOOL isUsePrefetch = [self isUsePrefetch: uniqueID];
    BOOL useV2Prefetch = [EEFeatureGating boolValueForKey:kUseV2Prefetch];
    BDPLogInfo(@"BDPJSRuntimeSettings appid<%@> isUsePrefetch %d", appID, isUsePrefetch);
    id<ECOConfigService> service = [ECOConfig service];
    /// 获取 Lark Settings 配置
    NSDictionary<NSString *, id> *settings = BDPSafeDictionary([service getDictionaryValueForKey: kUseNewNetworkAPISettingsKey]);
    NSDictionary<NSString *, NSNumber *> *requestSettings = settings[kRequestSettingsKey];
    NSDictionary<NSString *, NSNumber *> *uploadSettings = settings[kUploadFileSettingsKey];
    NSDictionary<NSString *, NSNumber *> *downloadSettings = settings[kDownloadFileSettingsKey];
    BDPLogInfo(@"BDPJSRuntimeSettings settings use_new_network_api: %@", settings);
    
    /// 获取开发者在应用 app.json 中描述的配置
    BDPNetworkAPIVersionConfig* appConfig = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID].config.networkAPIVersion;
    BDPLogInfo(@"BDPJSRuntimeSettings appConfig networkAPIVersion: %@", [appConfig toDictionary]);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ((!isUsePrefetch || useV2Prefetch) && [self getNetworkAPIVersionFromLarkSettings:requestSettings
                                                           appConfig:appConfig.requestVersion.networkAPIVersionType
                                                                       withUniqueID:uniqueID]) {
        result[@"useNewRequestAPI"] = @(YES);
    }
    if ([self getNetworkAPIVersionFromLarkSettings:uploadSettings
                                         appConfig:appConfig.uploadFileVersion.networkAPIVersionType
                                      withUniqueID:uniqueID]) {
        result[@"useNewUploadAPI"] = @(YES);
    }
    if ([self getNetworkAPIVersionFromLarkSettings:downloadSettings
                                         appConfig:appConfig.downloadFileVersion.networkAPIVersionType
                                                     withUniqueID:uniqueID]) {
        result[@"useNewDownloadAPI"] = @(YES);
    }
    BDPLogInfo(@"BDPJSRuntimeSettings use_new_network_api appid<%@> result %@", appID, result);
    return [result copy];
}

+ (BOOL)isUseNewNetworkAPIWithUniqueID:(OPAppUniqueID *)uniqueID {
    NSDictionary<NSString *, NSNumber *> *dict = [self getNetworkAPISettingsWithUniqueID:uniqueID];
    __block BOOL usedNewNetworkAPI = NO;
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj boolValue]) {
            usedNewNetworkAPI = YES;
        }
    }];
    return usedNewNetworkAPI;
}

+ (NSString *)generateRandomID:(NSString *)source {
    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    if (![userPlugin respondsToSelector:@selector(bdp_deviceId)]) {
        return nil;
    }
    NSString *sourceStr = [NSString stringWithFormat:@"%@.%@.%@", [userPlugin bdp_deviceId], [[NSUUID UUID] UUIDString], @([NSDate date].timeIntervalSince1970)];
    return [[NSString stringWithFormat:@"%@%@", sourceStr, source] bdp_md5];
}
@end
