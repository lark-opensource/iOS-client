//
//  TSPKLockIDOfLAContextPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKLockIDOfLAContextPipeline.h"
#import <LocalAuthentication/LAContext.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation LAContext (TSPrivacyKitLockID)

+ (void)tspk_lockid_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKLockIDOfLAContextPipeline class] clazz:self];
}

- (void)tspk_lockid_evaluatePolicy:(LAPolicy)policy localizedReason:(NSString *)localizedReason reply:(void (^)(BOOL, NSError * _Nullable))reply
{
    TSPKHandleResult *result = [TSPKLockIDOfLAContextPipeline handleAPIAccess:NSStringFromSelector(@selector(evaluatePolicy:localizedReason:reply:)) className:[TSPKLockIDOfLAContextPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (reply) {
            reply(NO, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_lockid_evaluatePolicy:policy localizedReason:localizedReason reply:reply];
    }
}

@end

@implementation TSPKLockIDOfLAContextPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineLockIDOfLAContext;
}

+ (NSString *)dataType {
    return TSPKDataTypeLockId;
}

+ (NSString *)stubbedClass
{
    return @"LAContext";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(evaluatePolicy:localizedReason:reply:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [LAContext tspk_lockid_preload];
    });
}

@end
