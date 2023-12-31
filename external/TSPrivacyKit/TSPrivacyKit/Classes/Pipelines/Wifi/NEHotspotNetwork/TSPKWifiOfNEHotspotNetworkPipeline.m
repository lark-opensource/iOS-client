//
//  TSPKWifiOfNEHotspotNetworkPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKWifiOfNEHotspotNetworkPipeline.h"
#import <NetworkExtension/NEHotspotNetwork.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation NEHotspotNetwork (TSPrivacyKitWifi)

+ (void)tspk_wifi_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKWifiOfNEHotspotNetworkPipeline class] clazz:self];
}

- (NSString *)tspk_wifi_SSID
{
    NSString *method = NSStringFromSelector(@selector(SSID));
    NSString *className = NSStringFromClass([NEHotspotNetwork class]);
    TSPKHandleResult *result = [TSPKWifiOfNEHotspotNetworkPipeline handleAPIAccess:method className:className];
    
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:TSPKReturnTypeNSString defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];;
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSString *originResult = [self tspk_wifi_SSID];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_wifi_SSID];
    }
}

- (NSString *)tspk_wifi_BSSID
{
    NSString *method = NSStringFromSelector(@selector(BSSID));
    NSString *className = NSStringFromClass([NEHotspotNetwork class]);
    TSPKHandleResult *result = [TSPKWifiOfNEHotspotNetworkPipeline handleAPIAccess:method className:className];
    
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:TSPKReturnTypeNSString defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSString *originResult = [self tspk_wifi_BSSID];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_wifi_BSSID];
    }
}

+ (void)tspk_wifi_fetchCurrentWithCompletionHandler:(void (^)(NEHotspotNetwork * __nullable currentNetwork))completionHandler
{
    TSPKHandleResult *result = [TSPKWifiOfNEHotspotNetworkPipeline handleAPIAccess:NSStringFromSelector(@selector(fetchCurrentWithCompletionHandler:)) className:NSStringFromClass([NEHotspotNetwork class])];
    
    if (result.action == TSPKResultActionFuse) {
        completionHandler(nil);
    } else {
        [self tspk_wifi_fetchCurrentWithCompletionHandler:completionHandler];
    }
}

@end

@implementation TSPKWifiOfNEHotspotNetworkPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineWifiOfNEHotspotNetwork;
}

+ (NSString *)dataType {
    return TSPKDataTypeWifi;
}

+ (NSString *)stubbedClass
{
    return @"NEHotspotNetwork";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(fetchCurrentWithCompletionHandler:))
    ];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(SSID)),
        NSStringFromSelector(@selector(BSSID))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NEHotspotNetwork tspk_wifi_preload];
    });
}

@end
