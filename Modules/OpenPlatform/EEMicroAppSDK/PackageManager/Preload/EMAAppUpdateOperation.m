//
//  EMAAppUpdateOperation.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import "EMAAppUpdateOperation.h"
#import "EMAAppUpdateInfo.h"
#import "EMAAppUpdateInfoManager.h"
#import <TTMicroApp/BDPStorageManager.h>
#import <TTMicroApp/BDPPackageModuleProtocol.h>
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPNetworking.h>
#import <TTMicroApp/BDPAppLoadManager+Load.h>
#import <TTMicroApp/BDPAppLoadManager+Util.h>
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/EMANetworkAPI.h>
#import "EMAAppUpdateManagerV2.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMARequestUtil.h>

#import <ECOInfra/OPError.h>
#import <ECOInfra/NSError+OP.h>
#import <OPFoundation/BDPUniqueID.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ECOProbe/OPTrace.h>
#import <ECOProbe/OPTraceService.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

static NSString * const kUpdateLogTag = @"EMAUpdate";

@interface EMAAppUpdateOperation()

@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, strong) id<BDPCommonUpdateModelProtocol> currentModel;
@property (nonatomic, weak) EMAAppUpdateManagerV2 *updateManager;

@end

@interface BDPModel(UpdateModelAdapter) <BDPCommonUpdateModelProtocol>
@end

@implementation BDPModel(UpdateModelAdapter)
///BDPModel 原生已经实现该协议，这里是为了避免警告
@end


@implementation EMAAppUpdateOperation

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID updateManager:(EMAAppUpdateManagerV2 *)updateManager
{
    self = [super init];
    if (self) {
        self.uniqueID = uniqueID;
        self.updateManager = updateManager;
        BDPLogTagInfo(kUpdateLogTag, @"newAppUpdateOperation %@", uniqueID);
    }
    return self;
}

- (void)main {
    BDPLogTagInfo(kUpdateLogTag, @"AppUpdateOperation start %@", self.uniqueID);
    if (self.updateManager) {
        [self syncHandelUpdate];
    } else {
        [self reportCustomIntercepted:@"updateManager is nil"];
    }
    BDPLogTagInfo(kUpdateLogTag, @"AppUpdateOperation end %@", self.uniqueID);
}

- (EMAAppUpdateInfoManager *)infoManager {
    return self.updateManager.infoManager;
}

- (void)syncHandelUpdate {
    BDPUniqueID *uniqueID = self.uniqueID;
    if (!uniqueID) {
        [self reportCustomIntercepted:@"uniqueID is nil"];
        return;
    }
    
    if (EMAAppEngine.currentEngine.updateManager != self.updateManager) {    // 引擎还没有初始化
        [self reportCustomIntercepted:@"updateManager is invalid"];
        return;
    }

    if (!self.infoManager) {
        [self reportCustomIntercepted:@"infoManager is nil"];
        return;
    }

    if (!uniqueID.isValid) {
        [self reportCustomIntercepted:@"uniqueID is invalid"];
        return;
    }

    EMAAppUpdateInfo *info = [self.infoManager appUpdateInfoForUniqueID:uniqueID];
    if (!info) {
        [self reportCustomIntercepted:@"updateInfo is nil"];
        return;
    }

    //  下面先取inuse再取update就是为了取最新的，@yinyuan
    id<BDPCommonUpdateModelProtocol> inUseAppModel = [EMABridgeFromWebapp getModelWithUniqueID:uniqueID];
    if (inUseAppModel) {
        BDPPkgFileLoadStatus pkgStatus = [BDPGetResolvedModule(BDPPackageModuleProtocol, inUseAppModel.uniqueID.appType).packageInfoManager queryPkgInfoStatusOfUniqueID:inUseAppModel.uniqueID pkgName:inUseAppModel.pkgName];
        if (pkgStatus == BDPPkgFileLoadStatusDownloaded) {
            self.currentModel = inUseAppModel;
        }
        BDPLogTagInfo(kUpdateLogTag, @"%@ pkgStatus: %zd", uniqueID.fullString, pkgStatus);
    }

    // 检查是否需要更新
    BOOL needUpdate = NO;
    if (self.currentModel) {
        BDPLogTagInfo(kUpdateLogTag, @"%@ info.app_version_code: %zd app_version: %@, currentModel.version_code: %lld version: %@",
                      uniqueID.fullString,
                      info.app_version_code,
                      info.app_version,
                      self.currentModel.version_code,
                      self.currentModel.version);
        if (info.app_version_code && self.currentModel.version_code) {
            if (info.app_version_code > self.currentModel.version_code) {
                needUpdate = YES;
            }
        } else if (![self.currentModel.version isEqualToString:info.app_version]) {
            needUpdate = YES;
        }
    } else {
        BDPLogTagInfo(kUpdateLogTag, @"%@ current model is nil", uniqueID.fullString);
        needUpdate = YES;
    }
    if (!needUpdate) {
        if (info.need_update) {
            info.app_version = self.currentModel.version;
            info.app_version_code = self.currentModel.version_code;
            info.need_update = NO;
            [self.infoManager markInfoChanged];
            [self.infoManager saveAll];         // 持久化
        }
        [self reportInterceptedType:OPPreInstallInterceptedCached appUpdateInfo:info];
        BDPLogTagInfo(kUpdateLogTag, @"已经是最新版本 %@ %@", uniqueID, info.app_version);
        return;
    }

    if (info.need_clear_cache) {
        // 删除小程序meta缓存，不论后续meta请求成功还是失败，下次冷启动都会使用新版本
        BDPLogTagInfo(kUpdateLogTag, @"clear cache %@", uniqueID);
        [BDPAppLoadManager clearMetaWithUniqueID:uniqueID];
    }

    if ([self shouldUpdate:info]) {
        BDPMonitorWithName(kEventName_mp_push_meta_hit, uniqueID)
        .kv(@"hit_type", @"keeped")
        .kv(@"app_id", info.app_id)
        .kv(@"app_version", info.app_version)
        .kv(@"ext_type", info.ext_type)
        .kv(@"source_from", info.sourceFrom)
        .flush();
        BDPLogTagInfo(kUpdateLogTag, @"Update start %@", BDPParamStr(uniqueID, info.app_version, self.currentModel.version));
        return [self syncUpdate:info];
    }
}

- (BOOL)shouldUpdate:(EMAAppUpdateInfo *)info {
    if (!info.need_update) {    // 不需要更新
        [self reportInterceptedType:OPPreInstallInterceptedNotNeedUpdate appUpdateInfo:info];
        return NO;
    }

    if (BDPIsEmptyString(info.app_version)) {
        BDPLogWarn(@"app_version isEmpty");
        [self reportCustomIntercepted:@"app_version isEmpty"];
        return NO;
    }

    if (!BDPNetworking.isNetworkConnected) {
        [self reportInterceptedType:OPPreInstallInterceptedNetworkUnavailable appUpdateInfo:info];
        return NO;
    }

    if (info.force_update) {    // 强制更新
        [self reportInterceptedType:OPPreInstallInterceptedServerForceUpdate appUpdateInfo:info];
        return YES;
    }

    BOOL canCellularDownload = [EMAAppUpdateManagerV2 canCellularDownloadFor:info.app_id];
    BOOL isWifi = (BOOL)(([BDPNetworking networkType] & BDPNetworkTypeWifi) > 0);
    if(!isWifi && !canCellularDownload) { // 检查wifi下更新
        BDPLogTagInfo(kUpdateLogTag, @"checkShouldPreLoadForApp Wifi is not connected and not in canCellarDownload list");
        [self reportInterceptedType:OPPreInstallInterceptedNotWifiAllow appUpdateInfo:info];
        return NO;
    }

    if (info.updated_times >= info.max_update_times) {  // 应用最大下载次数
        BDPLogTagInfo(kUpdateLogTag, @"updated_times > max_update_times");
        [self reportInterceptedType:OPPreInstallInterceptedExceedMaxUpdateTimes appUpdateInfo:info];
        return NO;
    }
    
    if (info.update_failed_times >= info.max_update_failed_times) {  // 应用最大下载失败次数(兜底保护，避免无限重试)
        BDPMonitorWithCode(GDMonitorCode.app_update_failed_too_many_times, info.uniqueID)
        .addMetricValue(@"update_failed_times", @(info.update_failed_times))
        .addCategoryValue(kEventKey_app_version, info.app_version)
        .flush();
        [self reportCustomIntercepted:@"failed too many"];
        return NO;
    }

    NSTimeInterval maxTimesOneDay = EMAAppEngine.currentEngine.onlineConfig.maxTimesOneDay;    // 读取后台参数
    if ([self.infoManager allAppUpdatedTimesWithAppInfo:nil] >= maxTimesOneDay) {    // 所有应用最大下载次数
        BDPLogTagInfo(kUpdateLogTag, @"maxTimesOneDay limit");
        [self reportInterceptedType:OPPreInstallInterceptedExceedMaxCountPerDay appUpdateInfo:info];
        return NO;
    }

    return YES;
}

- (void)syncUpdate:(EMAAppUpdateInfo *)updateInfo {
    BDPLogTagInfo(kUpdateLogTag, @"update start %@", updateInfo.app_id);
    if (EMAAppEngine.currentEngine.updateManager != self.updateManager) {    // 引擎还没有初始化
        return;
    }

    if (updateInfo.need_update == NO) {
        updateInfo.need_update = YES;
        [self.infoManager markInfoChanged];
        [self saveInfo];
    }

    BOOL canCellularDownload = [EMAAppUpdateManagerV2 canCellularDownloadFor:updateInfo.app_id];
    BOOL isWifi = (BOOL)(([BDPNetworking networkType] & BDPNetworkTypeWifi) > 0);
    
    if (updateInfo.force_update || isWifi) {
        NSString *updateReason =  updateInfo.force_update ? @"force_update":@"wifi";
        BDPLogTagInfo(kUpdateLogTag, @"update trigger by %@ or wifi with id %@", updateReason , updateInfo.app_id);
    } else if(canCellularDownload){
        BDPLogTagInfo(kUpdateLogTag, @"update trigger by settings with id %@", updateInfo.app_id);
    } else {
        BDPLogTagInfo(kUpdateLogTag, @"update stoped not wifi with id %@", updateInfo.app_id);
        return ;
    }
    
    

    // 如果当前正在进行load任务，则取消本次更新
    if ([[BDPAppLoadManager shareService] isExecutingTaskForUniqueID:self.uniqueID]) {
        BDPLogTagInfo(kUpdateLogTag, @"App task is runnning.");
        return;
    }


    BDPLogTagInfo(kUpdateLogTag, @"App update start %@.", updateInfo.uniqueID);

    BDPMonitorWithName(kEventName_mp_push_meta_hit, updateInfo.uniqueID)
    .kv(@"preload_type", @"preload_start")
    .kv(@"app_version", updateInfo.app_version)
    .kv(@"ext_type", updateInfo.ext_type)
    .flush();

    NSTimeInterval minTimeSinceLastUpdate = EMAAppEngine.currentEngine.onlineConfig.minTimeSinceLastUpdate;    // 读取后台参数

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    WeakSelf;
    void (^EMAAppPreloadCallback) (NSError* _Nullable, id<BDPCommonUpdateModelProtocol> _Nullable) = ^(NSError * _Nullable error, id<BDPCommonUpdateModelProtocol> _Nullable model) {
        BDPLogTagInfo(kUpdateLogTag, @"App update preloadCompletion %@ error:%@", model, error);
        // TODO：经验证，StrongSelfIfNotNil内部表达式出现的self仍然会被闭包捕获，所以这个宏是不安全的，此处考虑是否修改
        StrongSelfIfNotNil({
            [self updateTaskCompleteUpdateInfo:updateInfo error:error oldModel:self.currentModel model:model];
        })
        // 等待30秒再开始下一个任务
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(minTimeSinceLastUpdate * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_semaphore_signal(semaphore);
        });
    };
    //区分类型
    if (self.uniqueID.appType == OPAppTypeWebApp) {
        [EMABridgeFromWebapp preloadWebappWith:self.uniqueID completeCallback:EMAAppPreloadCallback];
    } else {
        BDPAppPreloadInfo *preloadInfo = [BDPAppPreloadInfo preloadInfoWithUniqueID:self.uniqueID priority:BDPAppLoadPriorityHigh];
        preloadInfo.preloadCompletion = ^(NSError * _Nullable error, BDPModel * _Nullable model) {
            EMAAppPreloadCallback(error, model);
        };
        [BDPAppLoadManager.shareService preloadAppWithInfo:preloadInfo];
    }
    // 同步等待完成
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC))); // 最长等待60s

    return;
}

- (void)updateTaskCompleteUpdateInfo:(EMAAppUpdateInfo*)updateInfo
                               error:(NSError * _Nullable)error
                            oldModel:(id<BDPCommonUpdateModelProtocol>  _Nullable)oldModel
                               model:(id<BDPCommonUpdateModelProtocol>  _Nullable)model {
    BDPLogTagInfo(kUpdateLogTag, @"App update complete %@ error:%@", updateInfo.app_id, error);
    if (updateInfo) {
        // 不管成功失败，都直接+1，因为已经消耗了资源
        updateInfo.updated_times = updateInfo.updated_times + 1;
    }

    if (updateInfo.need_update && !error && model) {
        // 更新上报
        BDPMonitorWithName(kEventName_mp_push_meta_hit, updateInfo.uniqueID)
        .kv(@"preload_type", @"preload_success")
        .kv(@"hit_type", @"updated")
        .kv(@"app_id", updateInfo.app_id)
        .kv(@"app_version", updateInfo.app_version)
        .kv(@"ext_type", updateInfo.ext_type)
        .flush();

        NSMutableDictionary *params = NSMutableDictionary.dictionary;
        params[@"app_id"] = model.uniqueID.appID;
        params[@"app_version"] = model.version;
        params[@"from_app_version"] = oldModel.version;
        params[@"force_update"] = @(updateInfo.force_update);
        params[@"strategy_version"] = updateInfo.strategy_version;
        //TODO: 网络专用 Trace, 派生了一级,勿直接使用.目前网络层级混乱,直接调了底层网络类,所以只能在这里派生(否者会和 EMARequestUtil 的封装冲突),网络重构后会统一修改 --majiaxin
        OPTrace *tracing = [EMARequestUtil generateRequestTracing:model.uniqueID];
        // 更新完成上报
        [EMANetworkManager.shared postUrl:EMAAPI.uploadAppInstallInfo params:params.copy completionWithJsonData:^(NSDictionary * _Nullable json, NSError * _Nullable error) {
            if (error) {
                BDPLogError(@"[Update]postUrl uploadAppInstallInfo error:%@", error);
            }
        } eventName:@"uploadAppInstallInfo" requestTracing:tracing];

        // 更新 updateInfo
        updateInfo.app_version = model.version;
        updateInfo.app_version_code = model.version_code;
        updateInfo.update_failed_times = 0; //连续更新失败次数重置
        updateInfo.need_update = NO;
        [self.infoManager markInfoChanged];
    } else {
        // 预加载/更新失败
        if (updateInfo) {
            // 连续更新失败次数+1
            updateInfo.update_failed_times = updateInfo.update_failed_times + 1;
        }
        if (![error.opError.originError.domain isEqualToString:NSURLErrorDomain] && ![error.domain isEqualToString:NSURLErrorDomain]) {
            // 非网络异常，不必重试, 不然可能无限重试
            updateInfo.need_update = NO;
            [self.infoManager markInfoChanged];
        }
    }
    [self saveInfo];
}

- (void)saveInfo {
    __strong EMAAppUpdateManagerV2 *updateManager = self.updateManager;
    if (updateManager) {
        WeakSelf;
        dispatch_async(updateManager.updateSerialQueue, ^{
            StrongSelfIfNilReturn;
            [self.infoManager saveAll];    // 持久化
        });
    }
}

// 上报'intercepted'情况
- (void)reportInterceptedType:(OPPreInstallInterceptedType)type
                appUpdateInfo:(EMAAppUpdateInfo *)info{
    BDPMonitorWithName(kEventName_mp_push_meta_hit, info.uniqueID)
    .kv(@"hit_type", @"intercepted")
    .kv(@"intercept_type", type)
    .kv(@"app_id", info.app_id)
    .kv(@"app_version", info.app_version)
    .kv(@"ext_type", info.ext_type)
    .kv(@"source_from", info.sourceFrom)
    .flush();
}

// 'intercepted'自定义拦截类型case上报
- (void)reportCustomIntercepted:(NSString *)customInfo {
    if (!customInfo) {
        BDPLogInfo(@"custom info is nil, need not report");
        return;
    }

    BDPMonitorWithName(kEventName_mp_push_meta_hit, nil)
    .kv(@"hit_type", @"intercepted")
    .kv(@"intercept_type", OPPreInstallInterceptedCustom)
    .kv(@"custom_info", customInfo)
    .flush();
}
@end
