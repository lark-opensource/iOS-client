//
//  TSPKMotionOfCMMotionActivityManagerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMotionOfCMMotionActivityManagerPipeline.h"
#import <CoreMotion/CMMotionActivityManager.h>
#import "TSPKUtils.h"
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CMMotionActivityManager (TSPrivacyKitMotion)

+ (void)tspk_motion_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMotionOfCMMotionActivityManagerPipeline class] clazz:self];
}

- (void)tspk_motion_queryActivityStartingFromDate:(NSDate *)start
                               toDate:(NSDate *)end
                              toQueue:(NSOperationQueue *)queue
                          withHandler:(CMMotionActivityQueryHandler)handler
{
    TSPKHandleResult *result = [TSPKMotionOfCMMotionActivityManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(queryActivityStartingFromDate:toDate:toQueue:withHandler:)) className:[TSPKMotionOfCMMotionActivityManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (queue) {
            [queue addOperationWithBlock:^{
                !handler ?: handler(nil, [TSPKUtils fuseError]);
            }];
        } else {
            !handler ?: handler(nil, [TSPKUtils fuseError]);
        }
        return;
    } else {
        [self tspk_motion_queryActivityStartingFromDate:start toDate:end toQueue:queue withHandler:handler];
    }
}


- (void)tspk_motion_startActivityUpdatesToQueue:(NSOperationQueue *)queue
                        withHandler:(CMMotionActivityHandler)handler
{
    TSPKHandleResult *result = [TSPKMotionOfCMMotionActivityManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startActivityUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMMotionActivityManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (queue) {
            [queue addOperationWithBlock:^{
                !handler ?: handler(nil);
            }];
        } else {
            !handler ?: handler(nil);
        }
        return;
    } else {
        [self tspk_motion_startActivityUpdatesToQueue:queue withHandler:handler];
    }
}
@end

@implementation TSPKMotionOfCMMotionActivityManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMotionOfCMMotionActivityManager;
}

+ (NSString *)dataType {
    return TSPKDataTypeMotion;
}

+ (NSString *)stubbedClass
{
    return @"CMMotionActivityManager";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(queryActivityStartingFromDate:toDate:toQueue:withHandler:)),
        NSStringFromSelector(@selector(startActivityUpdatesToQueue:withHandler:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CMMotionActivityManager tspk_motion_preload];
    });
}

@end
