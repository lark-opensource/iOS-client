//
//  TSPKNetworkOfCTCarrierPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKNetworkOfCTCarrierPipeline.h"
#import <CoreTelephony/CTCarrier.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CTCarrier (TSPrivacyKitNetwork)

+ (void)tspk_network_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKNetworkOfCTCarrierPipeline class] clazz:self];
}

- (NSString *)tspk_network_mobileNetworkCode
{
    NSString *method = NSStringFromSelector(@selector(mobileNetworkCode));
    NSString *className = [TSPKNetworkOfCTCarrierPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfCTCarrierPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSString *originResult = [self tspk_network_mobileNetworkCode];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_network_mobileNetworkCode];
    }
}

- (NSString *)tspk_network_mobileCountryCode
{
    NSString *method = NSStringFromSelector(@selector(mobileCountryCode));
    NSString *className = [TSPKNetworkOfCTCarrierPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfCTCarrierPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSString *originResult = [self tspk_network_mobileCountryCode];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_network_mobileCountryCode];
    }
}

- (NSString *)tspk_network_carrierName
{
    NSString *method = NSStringFromSelector(@selector(carrierName));
    NSString *className = [TSPKNetworkOfCTCarrierPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfCTCarrierPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSString *originResult = [self tspk_network_carrierName];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_network_carrierName];
    }
}

@end

@implementation TSPKNetworkOfCTCarrierPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineNetworkOfCTCarrier;
}

+ (NSString *)dataType {
    return TSPKDataTypeNetwork;
}

+ (BOOL)isEntryDefaultEnable {
    return NO;
}

+ (NSString *)stubbedClass
{
    return @"CTCarrier";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        @"mobileCountryCode",
        @"mobileNetworkCode",
        @"carrierName"
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CTCarrier tspk_network_preload];
    });
}

@end
