//
//  TSPKNetworkOfNSLocalePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKNetworkOfNSLocalePipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation NSLocale (TSPrivacyKitNetwork)

+ (void)tspk_network_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKNetworkOfNSLocalePipeline class] clazz:self];
}

- (NSString *)tspk_network_countryCode
{
    NSString *method = NSStringFromSelector(@selector(countryCode));
    NSString *className = [TSPKNetworkOfNSLocalePipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfNSLocalePipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSString *originResult = [self tspk_network_countryCode];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_network_countryCode];
    }
}

+ (NSArray<NSString *> *)tspk_network_ISOCountryCodes
{
    NSString *method = NSStringFromSelector(@selector(ISOCountryCodes));
    NSString *className = [TSPKNetworkOfNSLocalePipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfNSLocalePipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSArray<NSString *> *originResult = [self tspk_network_ISOCountryCodes];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_network_ISOCountryCodes];
    }
}

@end

@implementation TSPKNetworkOfNSLocalePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineNetworkOfNSLocale;
}

+ (NSString *)dataType {
    return TSPKDataTypeNetwork;
}

+ (NSString *)stubbedClass
{
    return @"NSLocale";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(ISOCountryCodes))
    ];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(countryCode))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSLocale tspk_network_preload];
    });
}

@end
