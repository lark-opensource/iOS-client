//
//  TSPKMotionOfCLLocationManagerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMotionOfCLLocationManagerPipeline.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CLLocationManager (TSPrivacyKitMotion)

+ (void)tspk_motion_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMotionOfCLLocationManagerPipeline class] clazz:self];
}

- (void)tspk_motion_startUpdatingHeading {
    TSPKHandleResult *result = [TSPKMotionOfCLLocationManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startUpdatingHeading)) className:[TSPKMotionOfCLLocationManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate&&[self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
            [self.delegate locationManager:self didFailWithError:[TSPKUtils fuseError]];
        }
    } else {
        [self tspk_motion_startUpdatingHeading];
    }
}

@end

@implementation TSPKMotionOfCLLocationManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMotionOfCLLocationManager;
}

+ (NSString *)dataType {
    return TSPKDataTypeMotion;
}

+ (NSString *)stubbedClass
{
    return @"CLLocationManager";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(startUpdatingHeading))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CLLocationManager tspk_motion_preload];
    });
}

@end
