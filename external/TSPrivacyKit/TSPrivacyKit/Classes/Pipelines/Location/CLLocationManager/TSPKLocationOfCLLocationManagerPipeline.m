//
//  TSPKLocationOfCLLocationManagerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKLocationOfCLLocationManagerPipeline.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "TSPKConfigs.h"
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKLogger.h"
#import "TSPKPipelineSwizzleUtil.h"

@interface TSPKLocationOfCLLocationManagerPipeline ()

+ (nullable TSPKHandleResult *)handleAPIAccess:(nonnull NSString *)api className:(nullable NSString *)className accuracy:(double)accuracy authStatus:(int)authStatus;

@end

@implementation CLLocationManager (TSPrivacyKitLocation)

+ (void)tspk_location_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKLocationOfCLLocationManagerPipeline class] clazz:self];
}

- (void)tspk_location_requestLocation
{
    TSPKHandleResult *result = [TSPKLocationOfCLLocationManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(requestLocation)) className:[TSPKLocationOfCLLocationManagerPipeline stubbedClass] accuracy:self.desiredAccuracy authStatus:[self getCurrentStatus]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
            [self.delegate locationManager:self didFailWithError:[TSPKUtils fuseError]];
        }
    } else {
        [self tspk_location_requestLocation];
    }
}

- (void)tspk_location_startUpdatingLocation
{
    TSPKHandleResult *result = [TSPKLocationOfCLLocationManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startUpdatingLocation)) className:[TSPKLocationOfCLLocationManagerPipeline stubbedClass] accuracy:self.desiredAccuracy authStatus:[self getCurrentStatus]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
            [self.delegate locationManager:self didFailWithError:[TSPKUtils fuseError]];
        }
    } else {
        [self tspk_location_startUpdatingLocation];
    }
}

- (void)tspk_location_startMonitoringSignificantLocationChanges
{
    TSPKHandleResult *result = [TSPKLocationOfCLLocationManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startMonitoringSignificantLocationChanges)) className:[TSPKLocationOfCLLocationManagerPipeline stubbedClass] accuracy:self.desiredAccuracy authStatus:[self getCurrentStatus]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
            [self.delegate locationManager:self didFailWithError:[TSPKUtils fuseError]];
        }
    } else {
        [self tspk_location_startMonitoringSignificantLocationChanges];
    }
}

#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
- (void)tspk_location_startMonitoringForRegion:(CLRegion *)region
{
    TSPKHandleResult *result = [TSPKLocationOfCLLocationManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(startMonitoringForRegion:)) className:[TSPKLocationOfCLLocationManagerPipeline stubbedClass] accuracy:self.desiredAccuracy authStatus:[self getCurrentStatus]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)]) {
            [self.delegate locationManager:self monitoringDidFailForRegion:region withError:[TSPKUtils fuseError]];
        }
    } else {
        [self tspk_location_startMonitoringForRegion:region];
    }
}
#endif

- (CLAuthorizationStatus)getCurrentStatus
{
    if (@available(iOS 14.0, *)) {
        return self.authorizationStatus;
    } else {
        return CLLocationManager.authorizationStatus;
    }
}

- (void)tspk_location_requestWhenInUseAuthorization
{
    TSPKHandleResult *result = [TSPKLocationOfCLLocationManagerPipeline handleAPIAccess:NSStringFromSelector(@selector(requestWhenInUseAuthorization)) className:[TSPKLocationOfCLLocationManagerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (self.delegate) {
            if (@available(iOS 14.0, *)) {
                if ([[TSPKConfigs sharedConfig] enableLocationDelegate]) {
                    if ([self.delegate respondsToSelector:@selector(locationManagerDidChangeAuthorization:)]) {
                        [self.delegate locationManagerDidChangeAuthorization:self];
                    }
                }
            } else {
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
                if ([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) {
                    [self.delegate locationManager:self didChangeAuthorizationStatus:kCLAuthorizationStatusDenied];
                }
#endif
            }
        }
        
    } else {
        [self tspk_location_requestWhenInUseAuthorization];
    }
}

@end

@implementation TSPKLocationOfCLLocationManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineLocationOfCLLocationManager;
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
        NSStringFromSelector(@selector(requestWhenInUseAuthorization)),
        NSStringFromSelector(@selector(requestLocation)),
        NSStringFromSelector(@selector(startUpdatingLocation)),
        NSStringFromSelector(@selector(startMonitoringSignificantLocationChanges)),
        NSStringFromSelector(@selector(startMonitoringForRegion:)),
    ];
}

+ (TSPKHandleResult *)handleAPIAccess:(NSString *)api
                            className:(NSString *)className
                             accuracy:(CLLocationAccuracy)accuracy
                           authStatus:(int)authStatus
{
    CLLAccuracy passedAccuracy = CLLAccuracyBestForNavigation;
    
    if (accuracy == kCLLocationAccuracyBestForNavigation) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyBestForNavigation"];
        passedAccuracy = CLLAccuracyBestForNavigation;
    } else if (accuracy == kCLLocationAccuracyBest) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyBest"];
        passedAccuracy = CLLAccuracyBest;
    } else if (accuracy == kCLLocationAccuracyNearestTenMeters) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyNearestTenMeters"];
        passedAccuracy = CLLAccuracyNearestTenMeters;
    } else if (accuracy == kCLLocationAccuracyHundredMeters) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyHundredMeters"];
        passedAccuracy = CLLAccuracyHundredMeters;
    } else if (accuracy == kCLLocationAccuracyKilometer) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyKilometer"];
        passedAccuracy = CLLAccuracyKilometer;
    } else if (accuracy == kCLLocationAccuracyThreeKilometers) {
        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyThreeKilometers"];
        passedAccuracy = CLLAccuracyThreeKilometers;
    } else {
        if (@available(iOS 14.0, *)) {
            if (accuracy == kCLLocationAccuracyReduced) {
                [TSPKLogger logWithTag:TSPKLogCommonTag message:@"location accuracy is CLLAccuracyReduced"];
                passedAccuracy = CLLAccuracyReduced;
            }
        }
    }
    
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"final location accuracy is %@", @(passedAccuracy)]];
    
    NSDictionary *params = @{@"accuracy_grade": @(passedAccuracy), @"location_auth_status": [self convertStatusText:authStatus]};
    
    return [self handleAPIAccess:api className:className params:params customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
        if (authStatus != kCLAuthorizationStatusAuthorizedAlways && authStatus != kCLAuthorizationStatusAuthorizedWhenInUse) {
#else
        if (authStatus != kCLAuthorizationStatusAuthorizedWhenInUse) {
#endif
            apiModel.isNonauth = YES;
        }
    }];
}

+ (NSString *)convertStatusText:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            return @"NotDetermined";
        case kCLAuthorizationStatusRestricted:
            return @"Restricted";
        case kCLAuthorizationStatusDenied:
            return @"Denied";
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
        case kCLAuthorizationStatusAuthorizedAlways:
            return @"AuthorizedAlways";
#endif
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return @"AuthorizedWhenInUse";
    }
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CLLocationManager tspk_location_preload];
    });
}

@end
