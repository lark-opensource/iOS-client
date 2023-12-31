//
//  EMAPreloadManager.m
//  EEMicroAppSDK
//
//  Created by 涂耀辉 on 2019/11/21.
//

#import "EMAPreloadManagerImp.h"
#import "BDPLocationPluginCustomImpl.h"
#import "EMAAppEngine.h"
#import "EMAAppUpdateManager.h"
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TMAPluginLocation.h>
#import <OPFoundation/EMALocationManagerV2.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/EEFeatureGating.h>

static NSString * const gcj02Str = @"gcj02";
static NSString * const locationSystemTypeKey = @"type";
static NSString * const kAccuracy = @"accuracy";
static NSString * const kBaseAccuracy = @"baseAccuracy";
static NSString * const kTimeout = @"timeout";
static NSString * const kCacheTimeout = @"cacheTimeout";
static NSString * const kLocation = @"locations";

@interface EMAPreloadManagerImp ()
@property(nonatomic, strong, nonnull) NSDictionary<NSNumber* ,id<EMAPreloadTask>> *preloadTasks;
@end

@implementation EMAPreloadManagerImp
-(instancetype)init {
    if(self = [super init]) {
        _preloadTasks = [EMAPreloadManagerImp createPreloadTasks];
    }
    return self;
}

+ (NSDictionary<NSNumber* ,id<EMAPreloadTask>> *)createPreloadTasks {
    NSMutableDictionary<NSNumber* ,id<EMAPreloadTask>> *result = [NSMutableDictionary dictionary];
    if (![EEFeatureGating boolValueForKey: @"openplatform.api.prelocation_continue_disable"]) {
        result[@(EMAPreloadTypeContinueLocation)] = [EMAPreloadContinueLocationFactory createTask];
    }
    return [result copy];
    
}
- (void)preloadWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        return;
    }
    [_preloadTasks.allValues enumerateObjectsUsingBlock:^(id<EMAPreloadTask>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj preloadWithUniqueID:uniqueID];
    }];
    
    NSDictionary *dnsParams = [EMAAppEngine.currentEngine.onlineConfig getPreloadDNSParamsForUniqueID:uniqueID];
    NSDictionary *locationParams = [EMAAppEngine.currentEngine.onlineConfig getPreloadLocationParamsForUniqueID:uniqueID];
    NSDictionary *connectedWifiParams = [EMAAppEngine.currentEngine.onlineConfig getPreloadConnectedWifiParamsForUniqueID:uniqueID];

    [self preloadLoactionWithParams:locationParams uniqueID:uniqueID];
    [self preloadDNSWithParams:dnsParams];
}

- (void)preloadLoactionWithParams:(NSDictionary *)params uniqueID:(BDPUniqueID *)uniqueID {
    if (!params) {
        BDPLogInfo(@"has no location param, %@ don't preload location", uniqueID ?: @"")
        return;
    }
    BOOL enable = [CLLocationManager locationServicesEnabled];
    if (!enable) {
        BDPLogInfo(@"system location is disable, %@ don't preload location", uniqueID ?: @"")
        return;
    }
    int status = [CLLocationManager authorizationStatus];
    if (status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse) {
        BDPLogInfo(@"authorizationStatus is not open, %@ don't preload location", uniqueID ?: @"")
        return;
    }
    BDPLogInfo(@"%@ start prelocation,", uniqueID ?: @"")
//    [[TMAPluginLocation sharedPlugin] getLocationWithParam:params callback:^(BDPJSBridgeCallBackType type, NSDictionary *dic) {

//    } context:nil];
    
    
    //以下逻辑迁移自 BDPLocationPluginCustomImpl.m ， 因为这部分属于旧API，后续会下线，所以这里直接迁移了代码
    NSString *accuracy = [params bdp_stringValueForKey:kAccuracy];
    CLLocationAccuracy baseAccuracy = [self getAccuracyWithNum:[params bdp_intValueForKey:kBaseAccuracy]];
    NSTimeInterval timeout = [params bdp_doubleValueForKey:kTimeout];
    NSTimeInterval cacheTimeout = [params bdp_doubleValueForKey:kCacheTimeout];
    CLLocationAccuracy desiredAccuracy = [accuracy isEqualToString:@"best"]?kCLLocationAccuracyBest:kCLLocationAccuracyHundredMeters;
    BDPCoordinateSystemType coordinateSystemType = EMACoordinateSystemTypeWGS84;

    [EMALocationManagerV2.sharedInstance reqeustLocationWithIsNeedRequestAuthoriztion:NO desiredAccuracy:desiredAccuracy baseAccuracy:baseAccuracy coordinateSystemType:coordinateSystemType timeout:timeout cacheTimeout:cacheTimeout appType:OPAppTypeToString(uniqueID.appType) appID:uniqueID.appID updateCallback:^(CLLocation *location, NSArray *locations) {
        BDPLogInfo(@"%@ updatecallback prelocation,", uniqueID ?: @"")
    } completion:^(CLLocation *location, BDPAccuracyAuthorization accuracy, NSError *error){
        BDPLogInfo(@"%@ complete prelocation,", uniqueID ?: @"")
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"%@ prelocation error: %@", uniqueID ?: @"",error];
            BDPLogError(msg)
            return;
        }
    }];
    
}

- (void)preloadDNSWithParams:(NSDictionary *)params{
    if (!params || !params[@"url"]) {
        return;
    }
    [EMANetworkManager.shared getUrl:params[@"url"] params:@{} completionWithJsonData:^(NSDictionary * _Nullable json, NSError * _Nullable error) {
    } eventName:@"preloadDNS"];
}

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

- (id)preloadTaskWithPreloadType:(EMAPreloadType)preloadType {
    return _preloadTasks[@(preloadType)];
}

@end
