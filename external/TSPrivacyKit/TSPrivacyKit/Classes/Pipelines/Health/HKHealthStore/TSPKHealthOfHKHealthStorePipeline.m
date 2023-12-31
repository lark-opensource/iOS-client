//
//  TSPKHealthOfHKHealthStorePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKHealthOfHKHealthStorePipeline.h"
#import <HealthKit/HealthKit.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation HKHealthStore (TSPrivacyKitHealth)

+ (void)tspk_health_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKHealthOfHKHealthStorePipeline class] clazz:self];
}

- (void)tspk_health_requestAuthorizationToShareTypes:(nullable NSSet<HKSampleType *> *)typesToShare
                               readTypes:(nullable NSSet<HKObjectType *> *)typesToRead
                              completion:(void (^)(BOOL success, NSError * _Nullable error))completion
{
    TSPKHandleResult *result = [TSPKHealthOfHKHealthStorePipeline handleAPIAccess:NSStringFromSelector(@selector(requestAuthorizationToShareTypes:readTypes:completion:)) className:[TSPKHealthOfHKHealthStorePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        !completion ?: completion(NO, [TSPKUtils fuseError]);
        return;
    } else {
        [self tspk_health_requestAuthorizationToShareTypes:typesToShare readTypes:typesToRead completion:completion];
    }
}

- (void)tspk_health_executeQuery:(HKQuery *)query
{
    TSPKHandleResult *result = [TSPKHealthOfHKHealthStorePipeline handleAPIAccess:NSStringFromSelector(@selector(executeQuery:)) className:[TSPKHealthOfHKHealthStorePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_health_executeQuery:query];
    }
}

@end

@implementation TSPKHealthOfHKHealthStorePipeline

+ (NSString *)pipelineType {
    return TSPKPipelineHealthOfHKHealthStore;
}

+ (NSString *)dataType {
    return TSPKDataTypeHealth;
}

+ (NSString *)stubbedClass
{
  return @"HKHealthStore";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(requestAuthorizationToShareTypes:readTypes:completion:)),
        NSStringFromSelector(@selector(executeQuery:))
    ];
}

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HKHealthStore tspk_health_preload];
    });
}

@end
