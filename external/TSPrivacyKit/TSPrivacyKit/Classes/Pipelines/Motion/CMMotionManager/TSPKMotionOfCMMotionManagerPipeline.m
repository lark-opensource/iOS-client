//
//  TSPKMotionOfCMMotionManagerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMotionOfCMMotionManagerPipeline.h"
#import <CoreMotion/CoreMotion.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CMMotionManager (TSPrivacyKitMotion)

+ (void)tspk_motion_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMotionOfCMMotionManagerPipeline class] clazz:self];
}

- (void)tspk_motion_startAccelerometerUpdates {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startAccelerometerUpdates)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_motion_startAccelerometerUpdates];
    }
}
        
- (void)tspk_motion_startAccelerometerUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMAccelerometerHandler)handler {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startAccelerometerUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(nil, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_motion_startAccelerometerUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)tspk_motion_startGyroUpdates {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startGyroUpdates)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_motion_startGyroUpdates];
    }
}
- (void)tspk_motion_startGyroUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMGyroHandler)handler  {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startGyroUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(nil, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_motion_startGyroUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)tspk_motion_startMagnetometerUpdates {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startMagnetometerUpdates)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_motion_startMagnetometerUpdates];
    }
}

#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
- (void)tspk_motion_startMagnetometerUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMMagnetometerHandler)handler {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startMagnetometerUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(nil, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_motion_startMagnetometerUpdatesToQueue:queue withHandler:handler];
    }
}
#endif

- (void)tspk_motion_startDeviceMotionUpdates {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startDeviceMotionUpdates)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_motion_startDeviceMotionUpdates];
    }
}

- (void)tspk_motion_startDeviceMotionUpdatesToQueue:(NSOperationQueue *)queue withHandler:(CMDeviceMotionHandler)handler {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startDeviceMotionUpdatesToQueue:withHandler:)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(nil, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_motion_startDeviceMotionUpdatesToQueue:queue withHandler:handler];
    }
}

- (void)tspk_motion_startDeviceMotionUpdatesUsingReferenceFrame:(CMAttitudeReferenceFrame)referenceFrame {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startDeviceMotionUpdatesUsingReferenceFrame:)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_motion_startDeviceMotionUpdatesUsingReferenceFrame:referenceFrame];
    }
}

- (void)tspk_motion_startDeviceMotionUpdatesUsingReferenceFrame:(CMAttitudeReferenceFrame)referenceFrame toQueue:(NSOperationQueue *)queue withHandler:(CMDeviceMotionHandler)handler {
    TSPKHandleResult *result = [TSPKMotionOfCMMotionManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startDeviceMotionUpdatesUsingReferenceFrame:toQueue:withHandler:)) className:[TSPKMotionOfCMMotionManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(nil, [TSPKUtils fuseError]);
        }
    } else {
        [self tspk_motion_startDeviceMotionUpdatesUsingReferenceFrame:referenceFrame toQueue:queue withHandler:handler];
    }
}

@end

@implementation TSPKMotionOfCMMotionManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMotionOfCMMotionManager;
}

+ (NSString *)dataType {
    return TSPKDataTypeMotion;
}

+ (NSString *)stubbedClass
{
    return @"CMMotionManager";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(startAccelerometerUpdates)),
        NSStringFromSelector(@selector(startAccelerometerUpdatesToQueue:withHandler:)),
        NSStringFromSelector(@selector(startGyroUpdates)),
        NSStringFromSelector(@selector(startGyroUpdatesToQueue:withHandler:)),
        NSStringFromSelector(@selector(startMagnetometerUpdates)),
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
        NSStringFromSelector(@selector(startMagnetometerUpdatesToQueue:withHandler:)),
#endif
        NSStringFromSelector(@selector(startDeviceMotionUpdates)),
        NSStringFromSelector(@selector(startDeviceMotionUpdatesToQueue:withHandler:)),
        NSStringFromSelector(@selector(startDeviceMotionUpdatesUsingReferenceFrame:)),
        NSStringFromSelector(@selector(startDeviceMotionUpdatesUsingReferenceFrame:toQueue:withHandler:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CMMotionManager tspk_motion_preload];
    });
}

@end
