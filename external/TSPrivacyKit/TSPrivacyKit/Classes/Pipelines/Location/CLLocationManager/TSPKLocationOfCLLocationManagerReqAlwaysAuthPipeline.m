//
//  TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/19.
//

#import "TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CLLocationManager (TSPrivacyKitLocationRequestAlwaysAuthorization)

+ (void)tspk_location_req_always_auth_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline class] clazz:self];
}

- (void)tspk_location_requestAlwaysAuthorization
{
    TSPKHandleResult *result = [TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline handleAPIAccess:NSStringFromSelector(@selector(requestAlwaysAuthorization)) className:[TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate) {
            if (@available(iOS 14.0, *)) {
                if ([self.delegate respondsToSelector:@selector(locationManagerDidChangeAuthorization:)]) {
                    [self.delegate locationManagerDidChangeAuthorization:self];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) {
                    [self.delegate locationManager:self didChangeAuthorizationStatus:kCLAuthorizationStatusDenied];
                }
            }
        }

    } else {
        [self tspk_location_requestAlwaysAuthorization];
    }
}

@end

@implementation TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineLocationOfCLLocationManagerReqAlwaysAuth;
}

+ (NSString *)dataType {
    return TSPKDataTypeLocation;
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
        NSStringFromSelector(@selector(requestAlwaysAuthorization))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CLLocationManager tspk_location_req_always_auth_preload];
    });
}

@end
