//
//  BDPLocationPluginCustomImpl.m
//  Pods
//
//  Created by zhangkun on 19/07/2018.
//

#import "BDPLocationPluginCustomImpl.h"
#import "EERoute.h"
#import <OPFoundation/EMADebugUtil.h>
#import <OPFoundation/EMALocationManagerV2.h>
#import <CoreLocation/CoreLocation.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import <TTRoute/TTRoute.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPLocationPluginDelegate.h>
#import <OPFoundation/BDPLocationPluginModel.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/BDPUniqueID.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

static NSString * const gcj02Str = @"gcj02";
static NSString * const locationSystemTypeKey = @"type";
static NSString * const kAccuracy = @"accuracy";
static NSString * const kBaseAccuracy = @"baseAccuracy";
static NSString * const kTimeout = @"timeout";
static NSString * const kCacheTimeout = @"cacheTimeout";
static NSString * const kLocation = @"locations";

@interface BDPLocationPluginCustomImpl() <BDPLocationPluginDelegate>

@end

@implementation BDPLocationPluginCustomImpl

#pragma mark - TMAPluginMapDelegate

+ (id<BDPLocationPluginDelegate>)sharedPlugin
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}


/// 请求定位服务
/// @param param 请求参数
/// @param context 应用上下文
/// @param completion 回调
- (void)bdp_reqeustLocationWithParam:(NSDictionary * _Nullable)param
                             context:(BDPPluginContext _Nullable)context
                          completion:(void(^ _Nullable)(CLLocation * _Nullable,
                                                        BDPAccuracyAuthorization,
                                                        NSError * _Nullable))completion {
    if (!completion) {
        BDPLogError(@"location service has no completion block, stop location")
        return;
    }
    NSString *type = [param bdp_stringValueForKey:locationSystemTypeKey];
    NSString *accuracy = [param bdp_stringValueForKey:kAccuracy];
    CLLocationAccuracy baseAccuracy = [self getAccuracyWithNum:[param bdp_intValueForKey:kBaseAccuracy]];
    NSTimeInterval timeout = [param bdp_doubleValueForKey:kTimeout];
    NSTimeInterval cacheTimeout = [param bdp_doubleValueForKey:kCacheTimeout];
    CLLocationAccuracy desiredAccuracy = [accuracy isEqualToString:@"best"]?kCLLocationAccuracyBest:kCLLocationAccuracyHundredMeters;
    BDPCoordinateSystemType coordinateSystemType = EMACoordinateSystemTypeWGS84;
    if ([type isEqualToString:gcj02Str]) {
        if (![OPLocaionOCBridge canConvertToGCJ02]) {
            NSString *msg = @"cannot use gcj02 type without amap";
            //  等待接入错误码
            completion(nil, BDPAccuracyAuthorizationUnknown, [NSError errorWithDomain:@"getLocation" code:-1 userInfo:@{NSLocalizedDescriptionKey : msg}]);
            BDPLogError(msg)
            return;
        }
        coordinateSystemType = EMACoordinateSystemTypeGCJ02;
    }
    // 超时范围限制在 [3, 180]，超出范围则使用默认逻辑
    if (timeout < 3 || timeout > 180) {
        if (desiredAccuracy < kCLLocationAccuracyHundredMeters) {
            timeout = 10;   // 高精度默认10s
        } else {
            timeout = 3;    // 百米精度默认3s
        }
    }
    //如果cacheTimeout小于0或大于60s，则不使用缓存
    if(cacheTimeout < 0 || cacheTimeout > 60) {
        cacheTimeout = 0;
    }
    BDPLogInfo(@"start location with params: %@", param ?: @{})
    [EMALocationManagerV2.sharedInstance reqeustLocationWithDesiredAccuracy:desiredAccuracy
                                                               baseAccuracy:baseAccuracy
                                                       coordinateSystemType:coordinateSystemType
                                                                    timeout:timeout
                                                               cacheTimeout:cacheTimeout
                                                                    appType:OPAppTypeToString(context.engine.uniqueID.appType)
                                                                      appID:context.engine.uniqueID.appID
                                                             updateCallback:^(CLLocation *location, NSArray *locations) {
        //  构造 onLocationChange 参数
        NSMutableDictionary *data = [self getDicWithLocation:location type:type];
        NSString *onLocationChangeEvent = @"onLocationChange";
        if (locations) {
            NSMutableArray *finnalLocations = [NSMutableArray array];
            for (CLLocation *loc in locations) {
                [finnalLocations addObject:[self getDicWithLocation:loc type:type]];
            }
            data[kLocation] = finnalLocations;
        }
        if ([self isAppActiveWithEngine:context.engine location:location]) {
            [context.engine bdp_fireEvent:onLocationChangeEvent
                                 sourceID:NSNotFound
                                     data:data.copy];
        } else {
            BDPLogInfo(@"onLocationChange app !isActive");
        }
    } completion:completion];
}

//  中间方法等待志友完全处理common，就换成common协议方法
- (BOOL)isAppActiveWithEngine:(id<BDPEngineProtocol>)engine location:(CLLocation *)location {
    if ([engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPJSBridgeEngine gadgetEngine = (BDPJSBridgeEngine)engine;
        BDPTask *appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:gadgetEngine.uniqueID];
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:gadgetEngine.uniqueID];
        //  如果ready并且active就进行回调
        if (appTask && common.isReady && common.isActive && location) {
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

- (NSMutableDictionary *)getDicWithLocation:(CLLocation *)location type:(NSString *)type{
    NSMutableDictionary *data = NSMutableDictionary.dictionary;
    data[@"type"] = type;
    data[@"latitude"] = @(location.coordinate.latitude);
    data[@"longitude"] = @(location.coordinate.longitude);
    data[@"verticalAccuracy"] = @(location.verticalAccuracy);
    data[@"horizontalAccuracy"] = @(location.horizontalAccuracy);
    data[@"timestamp"] = @((int64_t)(location.timestamp.timeIntervalSince1970 * 1000));
    data[@"accuracy"] = @(MAX(location.horizontalAccuracy, location.verticalAccuracy));
    return data;
}

/**
 *  kCLLocationAccuracyThreeKilometers: 3000
 *  kCLLocationAccuracyKilometer: 1000
 *  kCLLocationAccuracyHundredMeters: 100
 *  kCLLocationAccuracyNearestTenMeters: 10
 *  kCLLocationAccuracyBest: -1
 *  kCLLocationAccuracyBestForNavigation: -2
 */
- (CLLocationAccuracy)getAccuracyWithNum: (NSInteger)num {
    CLLocationAccuracy accuracy = kCLLocationAccuracyBest;
    switch (num) {
        case 3000:
            accuracy = kCLLocationAccuracyThreeKilometers;
            break;
        case 1000:
            accuracy = kCLLocationAccuracyKilometer;
            break;
        case 100:
            accuracy = kCLLocationAccuracyHundredMeters;
            break;
        case 10:
            accuracy = kCLLocationAccuracyNearestTenMeters;
            break;
        case -1:
            accuracy = kCLLocationAccuracyBest;
            break;
        case -2:
            accuracy = kCLLocationAccuracyBestForNavigation;
            break;
        default:
            break;
    }
    return accuracy;
}

@end
