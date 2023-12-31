//
//  TSPKMotionOfCMAltimeterPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMotionOfCMAltimeterPipeline.h"
#import <CoreMotion/CMAltimeter.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CMAltimeter (TSPrivacyKitMotion)

+ (void)tspk_motion_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMotionOfCMAltimeterPipeline class] clazz:self];
}

- (void)tspk_motion_startRelativeAltitudeUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMAltitudeHandler)handler
{
    TSPKHandleResult *result = [TSPKMotionOfCMAltimeterPipeline handleAPIAccess:NSStringFromSelector(@selector(startRelativeAltitudeUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMAltimeterPipeline stubbedClass]];
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
        [self tspk_motion_startRelativeAltitudeUpdatesToQueue:queue withHandler:handler];
    }
}
        
- (void)tspk_motion_startAbsoluteAltitudeUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMAbsoluteAltitudeHandler)handler
API_AVAILABLE(ios(15.0)){
    TSPKHandleResult *result = [TSPKMotionOfCMAltimeterPipeline handleAPIAccess:NSStringFromSelector(@selector(startAbsoluteAltitudeUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMAltimeterPipeline stubbedClass]];
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
        [self tspk_motion_startAbsoluteAltitudeUpdatesToQueue:queue withHandler:handler];
    }
}

@end

@implementation TSPKMotionOfCMAltimeterPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMotionOfCMAltimeter;
}

+ (NSString *)dataType {
    return TSPKDataTypeMotion;
}

+ (NSString *)stubbedClass
{
    return @"CMAltimeter";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    NSArray *methods = @[
        NSStringFromSelector(@selector(startRelativeAltitudeUpdatesToQueue:withHandler:))
    ];
    NSMutableArray *methodsWithLevel = [methods mutableCopy];
    if (@available(iOS 15.0, *)) {
        [methodsWithLevel addObject:NSStringFromSelector(@selector(startAbsoluteAltitudeUpdatesToQueue:withHandler:))];
    }
    return [methodsWithLevel copy];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CMAltimeter tspk_motion_preload];
    });
}

@end
