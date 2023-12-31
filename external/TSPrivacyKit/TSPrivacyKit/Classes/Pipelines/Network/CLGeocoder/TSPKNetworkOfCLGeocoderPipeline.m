//
//  TSPKNetworkOfCLGeocoderPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKNetworkOfCLGeocoderPipeline.h"
#import "NSObject+TSAddition.h"
#import <CoreLocation/CLGeocoder.h>
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation CLGeocoder (TSPrivacyKitNetwork)

+ (void)tspk_network_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKNetworkOfCLGeocoderPipeline class] clazz:self];
}

- (void)tspk_network_reverseGeocodeLocation:(CLLocation *)location completionHandler:(CLGeocodeCompletionHandler)completionHandler
{
    TSPKHandleResult *result = [TSPKNetworkOfCLGeocoderPipeline handleAPIAccess:NSStringFromSelector(@selector(reverseGeocodeLocation:completionHandler:)) className:[TSPKNetworkOfCLGeocoderPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        !completionHandler ?: completionHandler(nil, [TSPKUtils fuseError]);
        return;
    } else {
        [self tspk_network_reverseGeocodeLocation:location completionHandler:completionHandler];
    }
}

- (void)tspk_network_reverseGeocodeLocation:(CLLocation *)location preferredLocale:(NSLocale *)locale completionHandler:(CLGeocodeCompletionHandler)completionHandler
{
    TSPKHandleResult *result = [TSPKNetworkOfCLGeocoderPipeline handleAPIAccess:NSStringFromSelector(@selector(reverseGeocodeLocation:preferredLocale:completionHandler:)) className:[TSPKNetworkOfCLGeocoderPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        !completionHandler ?: completionHandler(nil, [TSPKUtils fuseError]);
        return;
    } else {
        [self tspk_network_reverseGeocodeLocation:location preferredLocale:locale completionHandler:completionHandler];
    }
}

@end

@implementation TSPKNetworkOfCLGeocoderPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineNetworkOfCLGeocoder;
}

+ (NSString *)dataType {
    return TSPKDataTypeNetwork;
}

+ (NSString *)stubbedClass
{
    return @"CLGeocoder";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(reverseGeocodeLocation:completionHandler:)),
        NSStringFromSelector(@selector(reverseGeocodeLocation:preferredLocale:completionHandler:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [CLGeocoder tspk_network_preload];
    });
}

@end
