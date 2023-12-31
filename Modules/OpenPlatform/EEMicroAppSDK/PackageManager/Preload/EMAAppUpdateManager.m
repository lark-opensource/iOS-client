//
//  EMAAppUpdateManager.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/6/11.
//

#import "EMAAppUpdateManager.h"
#import <TTMicroApp/BDPStorageManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "EMALifeCycleManager.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import "EMAAppEngine.h"
#import <TTMicroApp/BDPTaskManager.h>
#import <OPFoundation/BDPCommonManager.h>
#import <TTMicroApp/BDPTask.h>
#import <TTMicroApp/BDPAppLoadContext.h>
#import "EMAAppEngine.h"

@interface EMAAppUpdateManager()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *cachedPushInfos;

@end

@implementation EMAAppUpdateManager

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)onReceiveUpdatePushForAppID:(NSString *)appID
                            latency:(NSInteger)latency
                          extraInfo:(NSString *)extraJson
{
    BDPLogInfo(@"onReceiveUpdatePush, appId=%@, latency=%@", appID, @(latency));
    if (!appID) {
        return;
    }

    if (!EMAAppEngine.currentEngine.account.accountToken) {    // 引擎还没有初始化
        if (!self.cachedPushInfos) {
            self.cachedPushInfos = NSMutableDictionary.dictionary;
        }
        self.cachedPushInfos[appID] = @{@"latency":@(latency), @"extraJson":extraJson?:@""};
        return;
    }

    // 预安装重构逻辑
    if ([BDPPreloadHelper preloadEnable]) {
        [self preUpdateByPush:appID latency:latency extraInfo:extraJson];
        return;
    }

    // 预安装老逻辑
    if (EMAAppEngine.currentEngine.updateManager) {
        [EMAAppEngine.currentEngine.updateManager onReceiveUpdatePushForAppID:appID latency:latency extraInfo:extraJson];
        return;
    }
}

- (void)onReceiveSilenceUpdateAppID:(NSString *)appID extra:(NSString *)extra {
    BDPLogInfo(@"[silenceUpdate] receive silence update by push appID: %@", appID);

    // 预安装-止血重构逻辑
    if ([BDPPreloadHelper silenceEnable]) {
        if (EMAAppEngine.currentEngine.account.accountToken) {
            [self silenceUpdateByPush:appID extra:extra];
        } else {
            BDPLogWarn(@"[silenceUpdate] EMAAppEngine not ready");
        }
        return;
    }

    // 产品化止血推送老逻辑
    if (EMAAppEngine.currentEngine.silenceUpdateManager) {
        [EMAAppEngine.currentEngine.silenceUpdateManager onReciveSilenceUpdate:BDPSafeString(appID) extra:BDPSafeString(extra)];
    } else { // 如果引擎还没有初始化, 这边不需要进行缓存, 因为引擎初始化的时候会主动pull一次
        BDPLogWarn(@"[silenceUpdate] EMAAppEngine silenceUpdateManager is nil");
    }
}

- (void)checkCachedPush {
    if (!EMAAppEngine.currentEngine.account.accountToken) {    // 引擎还没有初始化
        return;
    }

    NSDictionary<NSString *, NSDictionary *> *cachedPushInfos = self.cachedPushInfos.copy;
    [self.cachedPushInfos removeAllObjects];
    [cachedPushInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                                         NSDictionary * _Nonnull obj,
                                                         BOOL * _Nonnull stop) {
        [self onReceiveUpdatePushForAppID:key
                                  latency:[obj bdp_intValueForKey:@"latency"]
                                extraInfo:[obj bdp_objectForKey:@"extraJson"]];
    }];
}

/// 预安装重构逻辑
- (void)preUpdateByPush:(NSString *)appID
                latency:(NSInteger)latency
              extraInfo:(NSString *)extraJson {
    NSDictionary *pushInfo = @{
        @"appID" : BDPSafeString(appID),
        @"latency" : @(latency),
        @"extraJson" : BDPSafeString(extraJson)
    };

    [EMAPreloadAPI onReceivePreloadPushWithScene:EMAAppPreloadScenePreUpdate appTypes:@[@(OPAppTypeGadget), @(OPAppTypeWebApp)] pushInfo:pushInfo];
}

/// 产品化止血重构推送逻辑
- (void)silenceUpdateByPush:(NSString *)appID extra:(NSString *)extra {
    NSDictionary *pushInfo = @{
        @"appID" : BDPSafeString(appID),
        @"extra" : BDPSafeString(extra)
    };

    [EMAPreloadAPI onReceivePreloadPushWithScene:EMAAppPreloadSceneSilence appTypes:@[@(OPAppTypeGadget), @(OPAppTypeWebApp)] pushInfo:pushInfo];
}
@end
