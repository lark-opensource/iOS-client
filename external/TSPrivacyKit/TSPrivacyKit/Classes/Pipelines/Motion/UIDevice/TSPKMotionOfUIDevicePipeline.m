//
//  TSPKMotionOfUIDevicePipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKMotionOfUIDevicePipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation UIDevice (TSPrivacykitMotion)

+ (void)tspk_motion_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMotionOfUIDevicePipeline class] clazz:self];
}

- (BOOL)tspk_motion_proximityState
{
    TSPKHandleResult *result = [TSPKMotionOfUIDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(proximityState)) className:[TSPKMotionOfUIDevicePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else {
        return [self tspk_motion_proximityState];
    }
}

- (BOOL)tspk_motion_isProximityMonitoringEnabled
{
    TSPKHandleResult *result = [TSPKMotionOfUIDevicePipeline handleAPIAccess:NSStringFromSelector(@selector(isProximityMonitoringEnabled)) className:[TSPKMotionOfUIDevicePipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else {
        return [self tspk_motion_isProximityMonitoringEnabled];
    }
}

@end

@implementation TSPKMotionOfUIDevicePipeline

+ (NSString *)pipelineType {
    return TSPKPipelineMotionOfUIDevice;
}

+ (NSString *)dataType {
    return TSPKDataTypeMotion;
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSString *)stubbedClass
{
    return @"UIDevice";
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(proximityState)),
        NSStringFromSelector(@selector(isProximityMonitoringEnabled))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIDevice tspk_motion_preload];
    });
}

@end
