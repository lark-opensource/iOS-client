//
//  TSPKNetworkOfCTTelephonyNetworkInfoPipeline.m
//  Musically
//
//  Created by ByteDance on 2023/2/23.
//

#import "TSPKNetworkOfCTTelephonyNetworkInfoPipeline.h"
#import "TSPKPipelineSwizzleUtil.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@implementation CTTelephonyNetworkInfo (TSPrivacyKitNetwork)

+ (void)tspk_network_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKNetworkOfCTTelephonyNetworkInfoPipeline class] clazz:self];
}

- (NSString *)tspk_network_currentRadioAccessTechnology
{
    NSString *method = @"currentRadioAccessTechnology";
    NSString *className = [TSPKNetworkOfCTTelephonyNetworkInfoPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfCTTelephonyNetworkInfoPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSString" defaultValue:nil];
    } else {
        return [self tspk_network_currentRadioAccessTechnology];
    }
}

- (NSDictionary<NSString *, NSString *> *)tspk_network_serviceCurrentRadioAccessTechnology
{
    NSString *method = @"serviceCurrentRadioAccessTechnology";
    NSString *className = [TSPKNetworkOfCTTelephonyNetworkInfoPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKNetworkOfCTTelephonyNetworkInfoPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:@"NSDictionary" defaultValue:nil];
    } else {
        return [self tspk_network_serviceCurrentRadioAccessTechnology];
    }
}

@end

@implementation TSPKNetworkOfCTTelephonyNetworkInfoPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineNetworkOfCTTelephonyNetworkInfo;
}

+ (NSString *)dataType {
    return TSPKDataTypeNetwork;
}

+ (NSString *)stubbedClass
{
    return @"CTTelephonyNetworkInfo";
}

+ (BOOL)isEntryDefaultEnable {
    return NO;
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    NSArray *method = @[
        @"currentRadioAccessTechnology"
    ];
    NSMutableArray *methodWithLevel = [method mutableCopy];
    if (@available(iOS 12.0, *)) {
        [methodWithLevel addObject:@"serviceCurrentRadioAccessTechnology"];
    }
    return [methodWithLevel copy];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CTTelephonyNetworkInfo tspk_network_preload];
    });
}

@end
