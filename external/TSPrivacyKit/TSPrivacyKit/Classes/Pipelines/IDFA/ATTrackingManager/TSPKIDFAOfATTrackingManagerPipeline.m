//
//  TSPKIDFAPipeline.m
//  TSPrivacyKit-Pods-Aweme
//
//  Created by bytedance on 2021/4/20.
//

#import "TSPKIDFAOfATTrackingManagerPipeline.h"
#import <AppTrackingTransparency/ATTrackingManager.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation ATTrackingManager (TSPrivacyKitIDFA)

+ (void)tspk_idfa_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKIDFAOfATTrackingManagerPipeline class] clazz:self];
}

+ (void)tspk_idfa_requestTrackingAuthorizationWithCompletionHandler:(void (^)(ATTrackingManagerAuthorizationStatus status))completion
{
    TSPKHandleResult *result = [TSPKIDFAOfATTrackingManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(requestTrackingAuthorizationWithCompletionHandler:)) className:[TSPKIDFAOfATTrackingManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (completion) {
            completion([ATTrackingManager trackingAuthorizationStatus]);            
        }
    } else {
        [ATTrackingManager tspk_idfa_requestTrackingAuthorizationWithCompletionHandler:completion];
    }
}

@end

@implementation TSPKIDFAOfATTrackingManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineIDFAOfATTrackingManager;
}

+ (NSString *)dataType {
    return TSPKDataTypeIDFA;
}

+ (NSString *)stubbedClass
{
    if (@available(iOS 14, *)) {
        return @"ATTrackingManager";
    }
    return nil;
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(requestTrackingAuthorizationWithCompletionHandler:))
    ];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return nil;
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 14, *)) {
            [ATTrackingManager tspk_idfa_preload];
        }
    });
}

@end
