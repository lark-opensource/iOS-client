//
//  TSPKMotionOfCMPedometerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMotionOfCMPedometerPipeline.h"
#import <CoreMotion/CMPedometer.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CMPedometer (TSPrivacyKit)

+ (void)tspk_motion_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMotionOfCMPedometerPipeline class] clazz:self];
}

- (void)tspk_motion_queryPedometerDataFromDate:(NSDate *)start
                            toDate:(NSDate *)end
                       withHandler:(CMPedometerHandler)handler
{
    TSPKHandleResult *result = [TSPKMotionOfCMPedometerPipeline handleAPIAccess:NSStringFromSelector(@selector(queryPedometerDataFromDate:toDate:withHandler:)) className:[TSPKMotionOfCMPedometerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        !handler ?: handler(nil, [TSPKUtils fuseError]);
        return;
    } else {
        [self tspk_motion_queryPedometerDataFromDate:start toDate:end withHandler:handler];
    }
}

- (void)tspk_motion_startPedometerUpdatesFromDate:(NSDate *)start
                          withHandler:(CMPedometerHandler)handler
{
    TSPKHandleResult *result = [TSPKMotionOfCMPedometerPipeline handleAPIAccess:NSStringFromSelector(@selector(startPedometerUpdatesFromDate:withHandler:)) className:[TSPKMotionOfCMPedometerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        !handler ?: handler(nil, [TSPKUtils fuseError]);
        return;
    } else {
        [self tspk_motion_startPedometerUpdatesFromDate:start withHandler:handler];
    }
}

- (void)tspk_motion_startPedometerEventUpdatesWithHandler:(CMPedometerEventHandler)handler
API_AVAILABLE(ios(10.0)){
    TSPKHandleResult *result = [TSPKMotionOfCMPedometerPipeline handleAPIAccess:NSStringFromSelector(@selector(startPedometerEventUpdatesWithHandler:)) className:[TSPKMotionOfCMPedometerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        !handler ?: handler(nil, [TSPKUtils fuseError]);
        return;
    } else {
        [self tspk_motion_startPedometerEventUpdatesWithHandler:handler];
    }
}
   
@end

@implementation TSPKMotionOfCMPedometerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMotionOfCMPedometer;
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
    return @"CMPedometer";
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    NSArray *method = @[
        NSStringFromSelector(@selector(queryPedometerDataFromDate:toDate:withHandler:)),
        NSStringFromSelector(@selector(startPedometerUpdatesFromDate:withHandler:))
    ];
    NSMutableArray *methodWithLevel = [method mutableCopy];
    if (@available(iOS 10.0, *)) {
        [methodWithLevel addObject:NSStringFromSelector(@selector(startPedometerEventUpdatesWithHandler:))];
    }
    return [methodWithLevel copy];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CMPedometer tspk_motion_preload];
    });
}

@end
