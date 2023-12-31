//
//  TSPKIDFVPipeline.m
//  TSPrivacyKit-Pods-Aweme
//
//  Created by bytedance on 2021/4/20.
//

#import "TSPKIDFVOfUIDevicePipeline.h"
#import <UIKit/UIDevice.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation UIDevice (TSPrivacyKitIDFV)

+ (void)tspk_idfv_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKIDFVOfUIDevicePipeline class] clazz:self];
}

- (NSUUID *)tspk_idfv_identifierForVendor
{
    NSString *method = NSStringFromSelector(@selector(identifierForVendor));
    NSString *className = [TSPKIDFVOfUIDevicePipeline stubbedClass];
    TSPKHandleResult *result = [TSPKIDFVOfUIDevicePipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:TSPKReturnTypeNSUUID defaultValue:nil];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSUUID *originResult = [self tspk_idfv_identifierForVendor];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_idfv_identifierForVendor];
    }
}

@end

@implementation TSPKIDFVOfUIDevicePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineIDFVOfUIDevice;
}

+ (NSString *)dataType {
    return TSPKDataTypeIDFV;
}

+ (NSString *)stubbedClass
{
  return @"UIDevice";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(identifierForVendor))
    ];
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIDevice tspk_idfv_preload];
    });
}

@end
