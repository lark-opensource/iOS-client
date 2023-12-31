//
//  EMAAppUpdateManagerV2.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import "EMAAppUpdateManagerV2.h"
#import "EMAAppEngine.h"
#import "EMAAppUpdateInfo.h"
#import "EMAAppUpdateInfoManager.h"
#import "EMAAppUpdateOperation.h"
#import "EMALifeCycleManager.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <OPFoundation/EMARequestUtil.h>
#import <ECOInfra/EMANetworkManager.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <TTMicroApp/BDPAppLoadContext.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPNetworking.h>
#import <TTMicroApp/BDPStorageManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <TTMicroApp/BDPTask.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <TTMicroApp/BDPAppLoadManager+Util.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/EMAConfigManager.h>
#import <TTMicroApp/BDPAppLoadManager+Clean.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

static NSString * const kEMALastUpdateTime = @"ema_last_update_time";
static NSString * const kUpdateLogTag = @"EMAUpdate";
static NSString * const kCellularCanDownloadAppList = @"cellular_can_download_appList";

@interface EMAAppUpdateManagerV2() <EMALifeCycleListener>

@property (nonatomic, strong, nonnull, readwrite) EMAAppUpdateInfoManager *infoManager;            // 更新信息管理器，负责信息管理和持久化
@property (nonatomic, strong, nonnull, readwrite) dispatch_queue_t updateSerialQueue;              // 更新代码执行队列，所有的更新逻辑代码都在这个串行队列执行，保证线程安全

@property (nonatomic, strong, nonnull, readwrite) NSOperationQueue *operationQueue;                // 更新任务队列（只用来执行更新任务）

@property (nonatomic, assign) NSTimeInterval lastCheckUpdateTaskTime;                              // 上次检查待更新列表时间

@end

@implementation EMAAppUpdateManagerV2

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;    // 同时只能进行一个更新任务

        _updateSerialQueue = dispatch_queue_create("com.bytedance.microapp.update.serialQueue", DISPATCH_QUEUE_SERIAL); // 串行队列

        [EMALifeCycleManager.sharedInstance addListener:self];

        [self onEngineLaunch];
    }
    return self;
}

- (void)dealloc {
    [self.operationQueue cancelAllOperations];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (EMAAppUpdateInfoManager *)infoManager {
    if (!_infoManager) {
        // 耗时操作懒加载
        _infoManager = [[EMAAppUpdateInfoManager alloc] init];
    }
    return _infoManager;
}

/// 收到Push消息，要保证引擎此前已经初始化
- (void)onReceiveUpdatePushForAppID:(NSString *)appID
                            latency:(NSInteger)latency
                          extraInfo:(NSString *)extraJson
{
    BDPLogInfo(@"onReceiveUpdatePush, appID=%@, latency=%@, extraJson=%@", appID, @(latency), extraJson);
    if (BDPIsEmptyString(appID)) {
        return;
    }

    if (EMAAppEngine.currentEngine.updateManager != self) {    // 引擎还没有初始化
        BDPLogTagWarn(kUpdateLogTag, @"engine not ready");
        return;
    }

    // 转为 AppUpdateInfo
    JSONModelError *error = nil;
    EMAAppUpdateInfo *info = [[EMAAppUpdateInfo alloc] initWithString:extraJson error:&error];
    if (error) {
        BDPLogTagError(kUpdateLogTag, @"json parse error:%@", error);
        return;
    }
    if (info.extensions.count>0) {
        for (EMAAppUpdateInfo * appInfo in info.extensions) {
            [self onReceiveUpdatePushForAppID:appID
                                      latency:latency
                                      appInfo:appInfo];
        }
    } else{
        [self onReceiveUpdatePushForAppID:appID
                                  latency:latency
                                  appInfo:info];
    }
}
- (void)onReceiveUpdatePushForAppID:(NSString *)appID
                            latency:(NSInteger)latency
                            appInfo:(EMAAppUpdateInfo *)info
{
    if (BDPIsEmptyString(info.strategy_version)) {
        // 没有 strategy_version 则认为是不能处理的消息
        BDPLogTagInfo(kUpdateLogTag, @"no strategy_version");
        return;
    }
    info.app_id = appID;

    info.sourceFrom = [NSNumber numberWithInteger:OPMetaHitSourceFromPush];

    if (BDPIsEmptyString(info.app_version)) {
        BDPLogWarn(@"app_version isEmpty");
        return;
    }
    
    BDPUniqueID *uniqueID = info.uniqueID;
    if (!uniqueID) {
        BDPLogWarn(@"uniqueID is nil");
        return;
    }

    WeakSelf;
    dispatch_async(self.updateSerialQueue, ^{
        StrongSelfIfNilReturn;
        if (EMAAppEngine.currentEngine.updateManager != self) {    // 引擎还没有初始化
            return;
        }

        BDPLogTagInfo(kUpdateLogTag, @"handleNewAppUpdateInfo %@", info.app_id);

        [self.infoManager mergeNewUpdateInfo:info];
        [self.infoManager saveAll];    // 持久化

        // latency时间内随机时间点发起请求，避免Push后集中请求造成后端压力
        NSTimeInterval delayTime = 10;
        if (latency > 0) {
            delayTime = arc4random() % latency;
        }
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), self.updateSerialQueue, ^{
            StrongSelfIfNilReturn;
            //统计有多少是被条件过滤的 keepe/before_keeped
            BDPMonitorWithName(kEventName_mp_push_meta_hit, info.uniqueID)
            .kv(@"hit_type", @"before_keeped")
            .kv(@"app_id", info.app_id)
            .kv(@"app_version", info.app_version)
            .kv(@"ext_type", info.ext_type)
            .kv(@"source", @"push")
            .kv(@"source_from", OPMetaHitSourceFromPush)
            .flush();
            EMAAppUpdateOperation *operation = [[EMAAppUpdateOperation alloc] initWithUniqueID:uniqueID updateManager:self];
            [self.operationQueue addOperation:operation];
        });
    });
}

/// 引擎启动时调用一次
- (void)onEngineLaunch {
    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), self.updateSerialQueue, ^{   // 这里固定延迟3秒，避开应用启动的关键时间
        NSTimeInterval checkDelayAfterLaunch = EMAAppEngine.currentEngine.onlineConfig.checkDelayAfterLaunch;    // 读取后台延迟参数
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(checkDelayAfterLaunch * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            if (EMAAppEngine.currentEngine.updateManager != self) {    // 引擎还没有初始化
                return;
            }

            // 监听网络变化
            [NSNotificationCenter.defaultCenter removeObserver:self];
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reachabilityChanged) name:BDPNetworking.reachabilityChangedNotification object:nil];
            [self deleteExpiredPkgIfNeeded];
            
            WeakSelf;
            [self pullAppUpdateInfoList:^{
                StrongSelfIfNilReturn;
                self.lastCheckUpdateTaskTime = 0;   // 需要立即启动任务
                [self checkCachedTask];
            }];
        });
    });
}

/// 主动拉取更新列表
- (void)pullAppUpdateInfoList:(void(^)())completion {
    BDPLogInfo(@"pullAppUpdateInfoList");
    if(!completion) {
        return;
    }
    if (EMAAppEngine.currentEngine.updateManager != self) {    // 引擎还没有初始化
        completion();
        return;
    }

    // 上次启动时间
    TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
    NSNumber *lastLaunchTime = [storage objectForKey:kEMALastUpdateTime];
    NSTimeInterval minTimeSinceLastPullUpdateInfo = EMAAppEngine.currentEngine.onlineConfig.minTimeSinceLastPullUpdateInfo;    // 读取后台参数
    if (lastLaunchTime && [lastLaunchTime isKindOfClass:NSNumber.class] && lastLaunchTime.doubleValue < (NSDate.date.timeIntervalSince1970 - minTimeSinceLastPullUpdateInfo)) {
        // 启动后一段开始检查
        BDPLogTagInfo(kUpdateLogTag, @"pullAppUpdateInfoList start");
    } else {
        if (lastLaunchTime) {
            // 检查时间间隔以内，不需要检查
            BDPLogTagInfo(kUpdateLogTag, @"no need pullAppUpdateInfoList");
            completion();
            return;
        }
    }

    NSArray<EMAAppUpdateInfo *> *updateList = self.infoManager.updateInfos.copy;
    NSMutableArray *appInfoList = NSMutableArray.array;
    if (updateList) {
        for (EMAAppUpdateInfo *info in updateList) {
            [appInfoList addObject:@{
                @"app_id": info.app_id ?: @"",
                @"app_version": info.app_version ?: @"",
            }];
            if (appInfoList.count >= 200) {
                break;  // 兜底保护，最多请求n个应用的更新信息
            }
        }
    }

    // 发起请求
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    params[@"app_info_list"] = appInfoList.copy;
    WeakSelf;
    [EMANetworkManager.shared postUrl:EMAAPI.getUpdateAppInfos params:params.copy completionWithJsonData:^(NSDictionary * _Nullable json, NSError * _Nullable error) {
        StrongSelfIfNilReturn;
        if (error) {
            BDPLogTagError(kUpdateLogTag, @"postUrl getUpdateAppInfos error:%@", error);
            completion();
            return;
        }

//        mock
//        json = @{
//            @"data": @[
//                    @{
//                        @"app_id": @"cli_9d5ffbba3e389101",
//                        @"app_version": @"9.9.9",
//                        @"app_version_code": @1590726210,
//                        @"need_clear_cache": @NO,
//                        @"need_update": @YES,
//                        @"force_update": @NO,
//                        @"max_update_times": @200,
//                        @"strategy_version": @"2",
//                        @"priority": @100
//                    }
//            ]
//        };

        WeakSelf;
        dispatch_async(self.updateSerialQueue, ^{
            StrongSelfIfNilReturn;
            if (EMAAppEngine.currentEngine.updateManager != self) {    // 引擎还没有初始化
                return;
            }

            NSArray *data = [json bdp_arrayValueForKey:@"data"];
            if (!data) {
                BDPLogTagInfo(kUpdateLogTag, @"no data");
                completion();
                return;
            }
            NSError *error = nil;
            NSArray *array = [EMAAppUpdateInfo arrayOfModelsFromDictionaries:data error:&error];
            if (error) {
                BDPLogTagError(kUpdateLogTag, @"json parse error %@", error);
                completion();
                return;
            }

            for (EMAAppUpdateInfo *info in array) {
                //如果存在子结构，直接使用 extensions 内的数据
                // https://bytedance.feishu.cn/wiki/wikcnPuZJOxlYrUbDJtDf2uoC3I#doxcn0YCQiy2eySwyIRlJtitwGh
                if (info.extensions.count>0 &&
                    [OPSDKFeatureGating isWebappOfflineEnable]) {
                    for (EMAAppUpdateInfo * extensionInfo in info.extensions) {
                        if ([extensionInfo isKindOfClass:EMAAppUpdateInfo.class]) {
                            extensionInfo.sourceFrom = [NSNumber numberWithInteger:OPMetaHitSourceFromPull];
                            [self.infoManager mergeNewUpdateInfo:extensionInfo];
                        }
                    }
                } else {
                    if ([info isKindOfClass:EMAAppUpdateInfo.class]) {
                        info.sourceFrom = [NSNumber numberWithInteger:OPMetaHitSourceFromPull];
                        [self.infoManager mergeNewUpdateInfo:info];
                    }
                }
            }

            [self.infoManager saveAll];    // 持久化

            [storage setObject:@(NSDate.date.timeIntervalSince1970) forKey:kEMALastUpdateTime];

            completion();
        });
    } eventName:@"getUpdateAppInfos" requestTracing:nil];
}

/// 检查待更新列表
- (void)checkCachedTask {
    BDPLogInfo(@"checkCachedTask");
    if (EMAAppEngine.currentEngine.updateManager != self) {     // 引擎还没有初始化
        return;
    }
    if (self.operationQueue.operationCount > 0) {               // 还有任务未完成，不用开始
        BDPLogTagInfo(kUpdateLogTag, @"some update operation still run");
        return;
    }
    if (!BDPNetworking.isNetworkConnected) {                    // 网络断开，不用开始
        BDPLogTagInfo(kUpdateLogTag, @"network not connected");
        return;
    }

    // 距离上次检查时间太小就不用再检查，避免频率太高
    NSTimeInterval minTimeSinceLastCheck = EMAAppEngine.currentEngine.onlineConfig.minTimeSinceLastCheck;    // 读取后台参数
    if (NSDate.date.timeIntervalSince1970 - self.lastCheckUpdateTaskTime < (minTimeSinceLastCheck)) {
        BDPLogTagDebug(kUpdateLogTag, @"[Update]checkCachedTask too often");
        return;
    }
    self.lastCheckUpdateTaskTime = NSDate.date.timeIntervalSince1970;

    NSArray<EMAAppUpdateInfo *> *updateInfos = [self.infoManager updateInfos];
    if (!updateInfos.count) {
        return; // 没有记录直接返回
    }
    for (EMAAppUpdateInfo *info in updateInfos) {
        if (!info.need_update) {
            continue;
        }

        //统计有多少是被条件过滤的 keepe/before_keeped
        //fix: 这边before_keeped上报条件和Android对齐.解决iOS之前数据量过大情况.
        BDPMonitorWithName(kEventName_mp_push_meta_hit, info.uniqueID)
        .kv(@"hit_type", @"before_keeped")
        .kv(@"app_id", info.app_id)
        .kv(@"app_version", info.app_version)
        .kv(@"ext_type", info.ext_type)
        .kv(@"source", @"cache")
        .kv(@"source_from", info.sourceFrom)
        .flush();

        BDPUniqueID *uniqueID = info.uniqueID;
        if (!uniqueID) {
            BDPMonitorWithName(kEventName_mp_push_meta_hit, nil)
            .kv(@"hit_type", @"intercepted")
            .kv(@"intercept_type", OPPreInstallInterceptedCustom)
            .kv(@"custom_info", @"uniqueID is nil")
            .flush();
            continue;
        }

        //Note: 这边网络条件/每天下载次数筛选条件统一交给EMAAppUpdateOperation中判断处理;
        EMAAppUpdateOperation *operation = [[EMAAppUpdateOperation alloc] initWithUniqueID:uniqueID updateManager:self];
        [self.operationQueue addOperation:operation];
    }

    [self.infoManager saveAll];    // 持久化
}

/// 网络条件变化
- (void)reachabilityChanged {
    if (EMAAppEngine.currentEngine.updateManager != self) {    // 引擎还没有初始化
        return;
    }
    if (!BDPNetworking.isNetworkConnected) {    // 断网就不用继续了
        return;
    }
    // 距离上次检查时间太小就不用再检查，避免频率太高
    NSTimeInterval minTimeSinceLastCheck = EMAAppEngine.currentEngine.onlineConfig.minTimeSinceLastCheck;    // 读取后台参数
    if (NSDate.date.timeIntervalSince1970 - self.lastCheckUpdateTaskTime < (minTimeSinceLastCheck)) {
        return;
    }
    BDPNetworkType networkType = BDPNetworking.networkType;
    if (networkType & BDPNetworkTypeWifi) {
        WeakSelf;
        NSTimeInterval checkDelayAfterNetworkChange = EMAAppEngine.currentEngine.onlineConfig.checkDelayAfterNetworkChange;    // 读取后台参数
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(checkDelayAfterNetworkChange * NSEC_PER_SEC)), self.updateSerialQueue, ^{
            StrongSelfIfNilReturn;
            if (!BDPNetworking.isNetworkConnected) {    // 断网就不用继续了
                return;
            }
            BDPNetworkType networkType = BDPNetworking.networkType;
            if (networkType & BDPNetworkTypeWifi) {
                // 网络变为wifi后稳定x秒后再开始检查
                BDPLogTagInfo(kUpdateLogTag, @"[Update]reachabilityChanged checkCachedTask");
                [self checkCachedTask];
            }
        });
    }
}

#pragma mark - EMALifeCycleListener

/// 小程序启动
- (void)onLaunch:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return;
    }

    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.updateSerialQueue, ^{
        StrongSelfIfNilReturn;

        BOOL load_with_cache = NO;
        EMAAppUpdateInfo *info = [self.infoManager appUpdateInfoForUniqueID:uniqueID];
        if (info) {             // 找到小程序记录
            load_with_cache = YES;
            if (info.updated_times > 0) {
                info.updated_times = 0;                 // 启动后清零
                [self.infoManager markInfoChanged];
                [self.infoManager saveAll];             // 持久化
            }
        } else {                // 未找到小程序记录
            //  原来的目的是能取到就够了，@yinyuan
            id<BDPCommonUpdateModelProtocol> inUseAppModel = [EMABridgeFromWebapp  getModelWithUniqueID:uniqueID];
            if (inUseAppModel) {
                info = [[EMAAppUpdateInfo alloc] init];
                info.app_id = uniqueID.appID;
                info.app_version = inUseAppModel.version;
                [self.infoManager mergeNewUpdateInfo:info]; // 写入记录
                [self.infoManager saveAll];                 // 持久化
            }
        }

        if (!info) {
            return;
        }
        //和Android 判断实现逻辑保持一致
        //如果缓存信息里有，且两边版本一致
        //则判断这次启动包来自于预安装, 需要上报 hit_type==used
        if(load_with_cache) {
            BDPCommon * common = [BDPCommonManager.sharedManager getCommonWithUniqueID:uniqueID];
            if (!(BDPIsEmptyString(common.model.version) || BDPIsEmptyString(info.app_version))&&
                [common.model.version isEqualToString:info.app_version]) {
                //新增 USED 记录
                BDPMonitorWithName(kEventName_mp_push_meta_hit, uniqueID)
                .kv(@"hit_type", @"used")
                .kv(@"app_id", info.app_id)
                .kv(@"app_version", info.app_version)
                .kv(@"ext_type", info.ext_type)
                .flush();
            }
        }

        NSMutableDictionary *params = NSMutableDictionary.dictionary;
        params[@"app_id"] = uniqueID.appID;
        params[@"app_version"] = info.app_version;
        params[@"load_with_cache"] = @(load_with_cache);
        //TODO: 网络专用 Trace, 派生了一级,勿直接使用.目前网络层级混乱,直接调了底层网络类,所以只能在这里派生(否者会和 EMARequestUtil 的封装冲突),网络重构后会统一修改 --majiaxin
        OPTrace *tracing = [EMARequestUtil generateRequestTracing:uniqueID];
        // 启动上报
        [EMANetworkManager.shared postUrl:EMAAPI.uploadAppLoadInfo params:params.copy completionWithJsonData:^(NSDictionary * _Nullable json, NSError * _Nullable error) {
            if (error) {
                BDPLogTagError(kUpdateLogTag, @"[Update]postUrl uploadAppLoadInfo error:%@", error);
            }
        } eventName:@"uploadAppLoadInfo" requestTracing:tracing];
    });
}

#pragma mark - private method


/// 是否可以在非Wi-Fi下进行下载（与服务端的force_update的区别在于 会被allAppUpdatedTimes限制，优先级低于force_update）
+ (BOOL)canCellularDownloadFor:(NSString *)appID{
    if (BDPIsEmptyString(appID)) {
        return NO;
    }
    NSArray<NSString *> *cellularCanDownloadAppList = [EMAAppEngine.currentEngine.configManager.minaConfig getArrayValueForKey:kCellularCanDownloadAppList];
    if (BDPIsEmptyArray(cellularCanDownloadAppList)) {
        return NO;
    }
    
    return [cellularCanDownloadAppList containsObject:appID];
}

/// 超过最大下载次数
-(BOOL)exceededMaxTimesOneDayLimit{
    NSTimeInterval maxTimesOneDay = EMAAppEngine.currentEngine.onlineConfig.maxTimesOneDay;    // 读取后台参数
    return [self.infoManager allAppUpdatedTimesWithAppInfo:nil] >= maxTimesOneDay;
}

-(void)deleteExpiredPkgIfNeeded{
    [[BDPAppLoadManager shareService] deleteExpiredPkg];
}

@end
