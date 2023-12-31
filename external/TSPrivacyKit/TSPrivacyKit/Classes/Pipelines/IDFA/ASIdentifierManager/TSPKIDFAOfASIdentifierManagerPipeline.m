//
//  TSPKIDFAPipeline.m
//  TSPrivacyKit-Pods-Aweme
//
//  Created by bytedance on 2021/4/20.
//

#import "TSPKIDFAOfASIdentifierManagerPipeline.h"
#import <AdSupport/ASIdentifierManager.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation ASIdentifierManager (TSPrivacyKitIDFA)

+ (void)tspk_idfa_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKIDFAOfASIdentifierManagerPipeline class] clazz:self];
}

- (NSUUID *)tspk_idfa_advertisingIdentifier
{
    NSString *method = NSStringFromSelector(@selector(advertisingIdentifier));
    NSString *className = [TSPKIDFAOfASIdentifierManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKIDFAOfASIdentifierManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return [result getObjectWithReturnType:TSPKReturnTypeNSUUID defaultValue:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]];
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        NSUUID *originResult = [self tspk_idfa_advertisingIdentifier];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_idfa_advertisingIdentifier];
    }
}

@end

@implementation TSPKIDFAOfASIdentifierManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineIDFAOfASIdentifierManager;
}

+ (NSString *)dataType {
    return TSPKDataTypeIDFA;
}

+ (NSString *)stubbedClass
{
  return @"ASIdentifierManager";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(advertisingIdentifier))
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
        [ASIdentifierManager tspk_idfa_preload];
    });
}

@end
