//
//  EMALocationManagerV2.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/3/28.
//

#import "EMALocationManagerV2.h"
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/EMADeviceHelper.h>
#import <OPFoundation/EMAMonitorHelper.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "EMALocationTask.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <LarkOpenAPIModel/LarkOpenAPIModel-Swift.h>

static NSString *const TASK_TD = @"taskId";

@interface EMALocationManagerV2 () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray<EMALocationTask *> *locationTasks;
@property (nonatomic, strong) NSMutableArray<void(^)(BOOL)> *requestAuthoriztionBlocks;
@property (nonatomic, strong) CLLocation *currentLocation;  // 当前位置
@property (nonatomic, strong) CLLocation *backupLocation;  // 用于最终无法获取到最新定位的backup
@property (nonatomic, strong) NSArray<CLLocation *> *locations;  // 当前位置的source locations
@property (nonatomic, assign) NSTimeInterval locationTime;  // 位置更新时间

@end

@implementation EMALocationManagerV2

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (BOOL)reqeustLocationWithIsNeedRequestAuthoriztion:(BOOL)isNeedRequestAuthoriztion
                                 desiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                              baseAccuracy:(CLLocationAccuracy)baseAccuracy
                      coordinateSystemType:(BDPCoordinateSystemType)coordinateSystemType
                                   timeout:(NSTimeInterval)timeout
                              cacheTimeout:(NSTimeInterval)cacheTimeout
                                   appType:(NSString *)appType
                                     appID:(NSString *)appID
                            updateCallback:(void(^)(CLLocation *, NSArray *))updateCallback
                                completion:(void(^)(CLLocation *, BDPAccuracyAuthorization, NSError *))completion {
    BDPLogInfo(@"reqeustLocationWithDesiredAccuracy, desiredAccuracy=%@, coordinateSystemType=%@, timeout=%@", @(desiredAccuracy), @(coordinateSystemType), @(timeout));
    if (timeout < 3) {
        timeout = 3;
    }
    //  可能存在多个小程序同时要求定位
    //  那么desiredAccuracy需要遍历一下self.locationTasks
    //  取到最小的desiredAccuracy设置到self.locationManager.desiredAccuracy
    self.locationManager.desiredAccuracy = [self getMinLocationAccuracyWithBaseAccuracy:baseAccuracy];

    EMAWiFiStatus wifiStatus = [EMADeviceHelper getWiFiStatusWithToken:OPSensitivityEntryTokenEeMicroAppSDKEMALocationManagerV2ReqeustLocation];
    // TODO: 埋点用到 appID 和 appType 逻辑可以从这里解耦
    OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_amap_location, nil)
    .timing()
    .kv(@"coordinate_type", EMACoordinateSystemTypeWGS84 == coordinateSystemType ? @"wgs84" : @"gcj02")
    .kv(@"desiredAccuracy", desiredAccuracy)
    .kv(@"timeout", (int)timeout)
    .kv(@"wifiStatus", wifiStatus)
    .kv(@"loc_ver", @"v2")
    .kv(@"app_type", appType)
    .kv(@"isUseNewAlgorithm", @(EMALocationManagerFGBridge.isUseNewUpdateAlgorithm))
    .kv(@"app_id", appID);
    
    // lark 租户级别gps权限关闭
    if (![EMALarkLocationAuthority checkAuthority]) {
        NSString *msg = @"lark gps switch is off";
        NSError *error = [NSError errorWithDomain:@"EMALocationManagerV2" code:EMALocationErrorLarkGPSDisabled userInfo:@{NSLocalizedDescriptionKey: msg}];
        BDPLogError(error.localizedDescription)
        completion(nil, BDPAccuracyAuthorizationUnknown, error);
        return NO;
    }

    [self requestAuthoriztionIsShowAlert:isNeedRequestAuthoriztion completion :^(BOOL authed) {
        if (!authed) {
            if (completion) {
                NSString *msg = @"has no location auth";
                NSError *error = [NSError errorWithDomain:@"EMALocationManagerV2" code:EMALocationErrorSystemAuthoriztion userInfo:@{NSLocalizedDescriptionKey: msg}];
                BDPLogError(error.localizedDescription)
                completion(nil, BDPAccuracyAuthorizationUnknown, error);
            }
            monitor.kv(@"result", @"authorization_denied").flush();
            return;
        }
        
        BDPLogInfo(@"locationManager startUpdatingLocation")
        NSError *error = nil;
        
        [OPSensitivityEntry startUpdatingLocationForToken: OPSensitivityEntryTokenEMALocationManagerV2ReqeustLocationWithIsNeedRequestAuthoriztion manager: self.locationManager error: &error];
        if (error) {
            BDPLogError(@"startUpdatingLocation failed, %@", error.localizedDescription);
            if (completion) {
                completion(nil, BDPAccuracyAuthorizationUnknown, error);
            }
            monitor.kv(@"result", @"location_entity_denied").flush();
            return;
        }
        
        EMALocationTask *task = [[EMALocationTask alloc] init];
        task.updateCallback = updateCallback;
        task.callback = completion;
        task.desiredAccuracy = desiredAccuracy;
        if (@available(iOS 14, *)) {
            CLAccuracyAuthorization auth = [self.locationManager accuracyAuthorization];
            task.accuracyAuthorization = auth;
            BDPLogInfo(@"locationManager accuracy auth: %@", @(auth));
        } else {
            task.accuracyAuthorization = BDPAccuracyAuthorizationUnknown;
        }
        // 精度授权
        monitor.kv(@"accuracyAuthorization", @(task.accuracyAuthorization));
        task.coordinateSystemType = coordinateSystemType;
        task.monitor = monitor;

        NSMutableDictionary *userInfo = NSMutableDictionary.dictionary;
        userInfo[TASK_TD] = task.taskId;
        // 定位超时
        task.timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(onLocationTimeout:) userInfo:userInfo repeats:NO];
        [self.locationTasks addObject:task];
        BDPLogInfo(@"locationManager startUpdatingLocation task has been set");

        if (self.currentLocation && NSDate.date.timeIntervalSince1970 - self.locationTime < cacheTimeout) {
            BDPLogInfo(@"getlocation use cache")
            [task updateLocationCallback:self.currentLocation locations:self.locations];
            [task updateLocation:self.currentLocation];
        } else {
            BDPLogInfo(@"getlocation use no cache")
        }
    }];
    return YES;
}

- (BOOL)reqeustLocationWithDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
                              baseAccuracy:(CLLocationAccuracy)baseAccuracy
                      coordinateSystemType:(BDPCoordinateSystemType)coordinateSystemType
                                   timeout:(NSTimeInterval)timeout
                              cacheTimeout:(NSTimeInterval)cacheTimeout
                                   appType:(NSString *)appType
                                     appID:(NSString *)appID
                            updateCallback:(void(^)(CLLocation *, NSArray *))updateCallback
                                completion:(void(^)(CLLocation *, BDPAccuracyAuthorization, NSError *))completion {
    return [self reqeustLocationWithIsNeedRequestAuthoriztion:YES
                                       desiredAccuracy:desiredAccuracy
                                          baseAccuracy:baseAccuracy
                                  coordinateSystemType:coordinateSystemType
                                               timeout:timeout
                                          cacheTimeout:cacheTimeout
                                               appType:appType
                                                 appID:appID
                                        updateCallback:updateCallback
                                                completion:completion];
}

/// 取出最高精度
/// @param baseAccuracy 传入精度
- (CLLocationAccuracy)getMinLocationAccuracyWithBaseAccuracy:(CLLocationAccuracy)baseAccuracy {
    for (EMALocationTask *task in self.locationTasks) {
        baseAccuracy = MIN(baseAccuracy, task.desiredAccuracy);
    }
    return baseAccuracy;
}
/// 查询APP定位权限
/// isShowAlert 如果用户未决策 app定位权限 是否弹出 定位申请的alert
- (void)requestAuthoriztionIsShowAlert:(BOOL)isShowAlert completion:(void(^)(BOOL authed))completion {
    if (!completion) {
        return;
    }
    // 系统定位服务是否可用
    BOOL enable = CLLocationManager.locationServicesEnabled;
    if (!enable) {
        completion(NO);
    }
    // 用户设置的定位权限
    int status = [CLLocationManager authorizationStatus];
    // 用户拒绝
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        completion(NO);     // 不可用
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        if (isShowAlert) {
            NSError *error = nil;
            [OPSensitivityEntry requestWhenInUseAuthorizationForToken: OPSensitivityEntryTokenEMALocationManagerV2RequestAuthoriztionIsShowAlert manager: self.locationManager error: &error];
            if (!error) {
                [self.requestAuthoriztionBlocks addObject:completion];  // 未决定
            } else {
                BDPLogError(@"requestAuthoriztion failed, %@", error.localizedDescription);
                completion(NO);
            }
        } else {
            completion(NO);     // 不可用
        }
    } else {
        completion(YES);    // 可用
    }
}

- (EMALocationTask *)taskForId:(NSString *)taskId {
    for (EMALocationTask *task in self.locationTasks) {
        if ([task.taskId isEqualToString:taskId]) {
            return task;
        }
    }
    return nil;
}

- (void)onLocationTimeout:(NSTimer *)timer {
    BDPLogInfo(@"onLocationTimeout");
    // 返回精度最高的结果
    if (!timer.userInfo) {
        return;
    }
    NSString *taskId = [timer.userInfo bdp_stringValueForKey:TASK_TD];
    EMALocationTask *task = [self taskForId:taskId];
    if (!task) {
        return;
    }
    //无location，则用backup
    if (!task.location) {
        task.location = self.backupLocation;
    }
    [task completeTask:YES];
    [self checkAndCleanTask];
}

- (void)checkAndCleanTask {
    NSArray *tasks = self.locationTasks.copy;
    for (EMALocationTask *task in tasks) {
        if (task.completed) {
            [self.locationTasks removeObject:task];
        }
    }
    if (self.locationTasks.count == 0) {
        // 已经没有任务，停止持续定位
        self.backupLocation = nil;
        [self.locationManager stopUpdatingLocation];
        BDPLogInfo(@"stopUpdatingLocation");
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    BDPLogWarn(@"locationManager fail, error=%@", error);
    for (EMALocationTask *task in self.locationTasks) {
        task.error = error;
    }
    [self checkAndCleanTask];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    BDPLogInfo(@"locationManager didUpdateLocations, location=%@", location);
    if (!location) {
        return;
    }
    //onLoactionChange不做过滤
    for (EMALocationTask *task in self.locationTasks) {
        [task updateLocationCallback:location locations:locations];
    }
    [self updateBackupLocation:location];
    //bugfix：解决超长时间的缓存问题。
    //https://bytedance.feishu.cn/docs/doccndL10Itf18CztcayNN2fMnh#
    //超过maxLocationCacheTime的数据不要
    BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
    NSTimeInterval maxLocationCacheTime = appEnginePlugin.onlineConfig.maxLocationCacheTime;
    if (NSDate.date.timeIntervalSince1970 - location.timestamp.timeIntervalSince1970 > maxLocationCacheTime) {
        BDPLogInfo(@"fix_loc_cache_old:%@", BDPParamStr(location));
        return;
    }
    
    //manager级别更新location
    [self updateLocation:location locations:locations];
    for (EMALocationTask *task in self.locationTasks) {
        [task updateLocation:location];
    }
    [self checkAndCleanTask];
}

- (void)setCurrentLocation:(CLLocation *)location {
    _currentLocation = location;
    self.locationTime = NSDate.date.timeIntervalSince1970;
}

- (void)updateLocation:(CLLocation *)location locations:locations{
    BDPLogInfo(@"EMALocationManagerV2 updateLocation start! location: %@, location: %@", location, locations);
    if (EMALocationManagerFGBridge.isUseNewUpdateAlgorithm) {
        [self newUpdateLocation:location locations:locations];
    } else {
        [self oldUpdateLocation:location locations:locations];
    }
    BDPLogInfo(@"EMALocationManagerV2 updateLocation done! location: %@, location: %@", self.currentLocation, self.locations);
}

- (void)oldUpdateLocation:(CLLocation *)location locations:locations{
    if (!self.currentLocation) {
        self.currentLocation = location;
        self.locations = locations;
        return;
    }
    //如果超过5s都没有修改，则直接修改
    if (NSDate.date.timeIntervalSince1970 - self.locationTime > 5) {
        self.currentLocation = location;
        self.locations = locations;
        return;
    }
    if (location.horizontalAccuracy > self.currentLocation.horizontalAccuracy) {
        // 新的精度变低的处理
        CLLocationDistance distance = [self.currentLocation distanceFromLocation:location];
        if (distance < self.currentLocation.horizontalAccuracy) {
            // 新的位置还在原精度更高的位置范围内则不用替换坐标
            return;
        }
    }
    self.currentLocation = location;
    self.locations = locations;
}

- (void)newUpdateLocation:(CLLocation *)location locations:locations{
    if (!self.currentLocation) {
        self.currentLocation = location;
        self.locations = locations;
        return;
    }
    NSTimeInterval newTimestamp = location.timestamp.timeIntervalSince1970;
    NSTimeInterval oldTimestamp = self.currentLocation.timestamp.timeIntervalSince1970;
    CLLocationAccuracy newAccuracy = location.horizontalAccuracy;
    CLLocationAccuracy oldAccuracy = self.currentLocation.horizontalAccuracy;
    if (newTimestamp - oldTimestamp >= 0
        && (newAccuracy <= oldAccuracy || newTimestamp - oldTimestamp >= EMALocationManagerFGBridge.updateCurrentLocationTimeout)){
        self.currentLocation = location;
        self.locations = locations;
    }
   
}


- (void)updateBackupLocation:(CLLocation *)location{
    if (!self.backupLocation) {
        self.backupLocation = location;
        return;
    }
    //location更新则替换
    if (location.timestamp.timeIntervalSince1970 - self.backupLocation.timestamp.timeIntervalSince1970 > 0) {
        self.backupLocation = location;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    BDPLogWarn(@"locationManager didChangeAuthorizationStatus, status=%@", @(status));
    if (status == kCLAuthorizationStatusNotDetermined) {
        // 未决定
        return;
    }
    NSDictionary *requestAuthoriztionBlocks = self.requestAuthoriztionBlocks.copy;
    [self.requestAuthoriztionBlocks removeAllObjects];
    for (void(^completion)(BOOL) in requestAuthoriztionBlocks) {
        if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
            completion(NO);
        } else {
            completion(YES);
        }
    }
    [self checkAndCleanTask];
}

#pragma mark - getter

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = CLLocationManager.new;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (NSMutableArray<EMALocationTask *> *)locationTasks {
    if (!_locationTasks) {
        _locationTasks = NSMutableArray.array;
    }
    return _locationTasks;
}

- (NSMutableArray<void (^)(BOOL)> *)requestAuthoriztionBlocks {
    if (!_requestAuthoriztionBlocks) {
        _requestAuthoriztionBlocks = NSMutableArray.array;
    }
    return _requestAuthoriztionBlocks;
}

@end
