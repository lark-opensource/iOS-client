//
//  TSPKCallCenterOfCTCallCenterPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKCallCenterOfCTCallCenterPipeline.h"
#if __has_include(<CoreTelephony/CTCallCenter.h>)
#import <CoreTelephony/CTCallCenter.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CTCallCenter (TSPrivacykit)

+ (void)tspk_call_center_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKCallCenterOfCTCallCenterPipeline class] clazz:self];
}

- (NSSet<CTCall *> *)tspk_call_center_currentCalls {
    NSString *method = NSStringFromSelector(@selector(currentCalls));
    NSString *className = [TSPKCallCenterOfCTCallCenterPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKCallCenterOfCTCallCenterPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSSet<CTCall *> *originResult = [self tspk_call_center_currentCalls];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_call_center_currentCalls];
    }
}

- (void)tspk_call_center_setCallEventHandler:(CTCall*)calls {
    
    TSPKHandleResult *result = [TSPKCallCenterOfCTCallCenterPipeline handleAPIAccess:NSStringFromSelector(@selector(setCallEventHandler:)) className:[TSPKCallCenterOfCTCallCenterPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        return [self tspk_call_center_setCallEventHandler:calls];
    }
}
@end

#endif

@implementation TSPKCallCenterOfCTCallCenterPipeline

+ (NSString *)pipelineType {
    return TSPKPipelineCallCenterOfCTCallCenter;
}

+ (NSString *)dataType {
    return TSPKDataTypeCallCenter;
}

+ (NSString *)stubbedClass
{
  return @"CTCallCenter";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(currentCalls)),
        NSStringFromSelector(@selector(setCallEventHandler:))
    ];
}

+ (void)preload
{
#if __has_include(<CoreTelephony/CTCallCenter.h>)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CTCallCenter tspk_call_center_preload];
    });
#endif
}

@end
