//
//  EMALibVersionManager.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/4/20.
//

#import "EMALibVersionManager.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMADebugUtil.h>

#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

#import <OPSDK/OPSDK-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPTracker.h>
#import <TTMicroApp/BDPAppPageFactory.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/BDPJSSDKForceUpdateManager.h>
#import <TTMicroApp/BDPVersionManagerV2.h>

NSString * const kAppCenterViewDidLoadNotification = @"kAppCenterViewDidLoad";

@interface EMALibVersionManager ()

@property (nonatomic, assign) NSInteger *appPagePreloadRetryCount;
@property (nonatomic, assign) NSInteger *jsRuntimePreloadRetryCount;

@property (nonatomic, strong) id activeObserverToken;
@property (nonatomic, strong) id acLoadObserverToken;

@end

@implementation EMALibVersionManager

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    if (self.activeObserverToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.activeObserverToken];
    }

    if (self.acLoadObserverToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.acLoadObserverToken];
    }
}

- (void)setup {
    WeakSelf;
    self.activeObserverToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        StrongSelfIfNilReturn;
        // 从后台返回前台需要检查是否需要预加载(等 2 秒后再检查)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // preloadLibIfNeed 中有setting 开关，更新预加载来源前需要先check
            [EMALibVersionManager updatePreloadForPreloadLibIfNeed:@"did_become_active"];
            [self preloadLibIfNeed];
        });
    }];

    self.acLoadObserverToken = [[NSNotificationCenter defaultCenter] addObserverForName:kAppCenterViewDidLoadNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        StrongSelfIfNilReturn;
        // preloadLibIfNeed 中有setting 开关，更新预加载来源前需要先check
        [EMALibVersionManager updatePreloadForPreloadLibIfNeed:@"appcenter_view_did_load"];
        // 应用中心加载时需要检查是否预加载
        [self preloadLibIfNeed];
    }];
}

- (void)updateBlockLibIfNeed
{
    BDPLogInfo(@"block js sdk update: updateLibIfNeed");
    [self updateLibIfNeededWithAppType:OPAppTypeBlock
                             libConfig:[EMAAppEngine.currentEngine.onlineConfig blockJSSdkConfig] complete:nil];
}

- (BOOL)updateCardMsgLibIfNeedWithComplete:(void (^)(NSString *__nullable errorMsg, BOOL success))complete
{
    BDPLogInfo(@"updateCardMsgLibIfNeedWith: config:%@", [EMAAppEngine currentEngine].onlineConfig.msgCardTemplateConfig);
    return [self updateLibIfNeededWithAppType:OPAppTypeSDKMsgCard
                                    libConfig:[EMAAppEngine currentEngine].onlineConfig.msgCardTemplateConfig
                                     complete:complete];
}
- (BOOL)updateLibIfNeededWithAppType:(OPAppType)appType libConfig:(NSDictionary *)config complete:(void (^)(NSString *__nullable errorMsg, BOOL success))complete;
{
    if (!config) {
        BDPLogWarn(@"%@ js sdk update: !config", OPAppTypeToString(appType));
        return NO;
    }

    // Get New SDK Version
    NSString *latestUpdateVersionString = [config bdp_stringValueForKey:@"sdkUpdateVersion"];
    NSString *latestBaseVersionString = [config bdp_stringValueForKey:@"sdkVersion"];
    NSString *jsLibGreyHash = [config bdp_stringValueForKey:@"greyHash"];
    NSString *url = [config bdp_stringValueForKey:@"latestSDKUrl"];
    NSString *from = [config bdp_stringValueForKey:@"from"];
    BOOL useSpecificJSSDKURL = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificBlockJSSDKURL].boolValue;
    NSString *specificJSSDKURL = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificBlockJSSDKURL].stringValue;
    if(appType != OPAppTypeBlock) {
        useSpecificJSSDKURL = NO;
        specificJSSDKURL = nil;
    }
    // Event - Request Success
    [BDPVersionManager eventV3WithLibEvent:@"mp_lib_request_result"
                                      from:from
                             latestVersion:latestUpdateVersionString
                            latestGreyHash:jsLibGreyHash
                                resultType:@"success"
                                    errMsg:nil
                                  duration:0
                                   appType:appType];
    BDPLogInfo(@"block js sdk update: %@", BDPParamStr(latestUpdateVersionString, latestBaseVersionString, url, useSpecificJSSDKURL, specificJSSDKURL));
    if (useSpecificJSSDKURL && specificJSSDKURL && specificJSSDKURL.length > 0) {
        url = specificJSSDKURL;
        latestBaseVersionString = @"99.99.99";
        latestUpdateVersionString = @"99.99.99.99";
        jsLibGreyHash = @"";
        BDPLogInfo(@"block js sdk update: use specificJSSDKURL %@", BDPParamStr(url, latestBaseVersionString, latestUpdateVersionString));
    } else if (![BDPVersionManager isNeedUpdateLib:latestUpdateVersionString greyHash:jsLibGreyHash appType:appType]) {
        // Event - Don't Need Update SDK
        [BDPVersionManager eventV3WithLibEvent:@"mp_lib_validation_result"
                                          from:nil
                                 latestVersion:latestUpdateVersionString
                                latestGreyHash:jsLibGreyHash
                                    resultType:@"no_update"
                                        errMsg:nil
                                      duration:0
                                       appType:appType];
        BDPLogInfo(@"block js sdk update: JSSDK is up to date %@", BDPParamStr(latestUpdateVersionString));
        return NO;
    }


    // Event - Need Update SDK
    [BDPVersionManager eventV3WithLibEvent:@"mp_lib_validation_result"
                                      from:nil
                             latestVersion:latestUpdateVersionString
                            latestGreyHash:jsLibGreyHash
                                resultType:@"need_update"
                                    errMsg:nil
                                  duration:0
                                   appType:appType];

    if (!url || !url.length) {
        // Event - Download Failure
        [BDPVersionManager eventV3WithLibEvent:@"mp_lib_download_result"
                                          from:nil
                                 latestVersion:latestUpdateVersionString
                                latestGreyHash:jsLibGreyHash
                                    resultType:@"fail"
                                        errMsg:@"Download URL is NULL."
                                      duration:0
                                       appType:appType];
        return NO;
    }

    BDPLogInfo(@"block js sdk update: downloadLibWithURL %@", BDPParamStr(url, latestUpdateVersionString, latestBaseVersionString));
    [BDPVersionManager downloadLibWithURL:url
                            updateVersion:latestUpdateVersionString
                              baseVersion:latestBaseVersionString
                                 greyHash:jsLibGreyHash
                                  appType:appType
                               completion:^(BOOL result, NSString *errorMsg) {
        if(complete != nil){
            complete(errorMsg, result);
        }
    }];
    return YES;
}

- (void)updateLibIfNeed
{
    [self updateLibIfNeedWithConfig:[EMAAppEngine.currentEngine.onlineConfig jssdkConfig]];
}
- (void)updateLibIfNeedWithConfig:(NSDictionary *)config
{
    BDPLogInfo(@"updateLibIfNeed");
    if (!config) {
        BDPLogWarn(@"!config");
        [self updateLibComplete:NO];
        return;
    }

    // 指定使用内置JSSDK包，不用更新
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseBuildInJSSDK].boolValue) {
        BDPLogInfo(@"UseBuildInJSSDK");
        [self updateLibComplete:NO];
        return;
    }

    // Get New SDK Version
    NSString *latestUpdateVersionString = [config bdp_stringValueForKey:@"sdkUpdateVersion"];
    NSString *latestBaseVersionString = [config bdp_stringValueForKey:@"sdkVersion"];
    NSString *jsLibGreyHash = [config bdp_stringValueForKey:@"greyHash"];
    NSString *url = [config bdp_stringValueForKey:@"latestSDKUrl"];
    BOOL useSpecificJSSDKURL = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL].boolValue;
    NSString *specificJSSDKURL = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificJSSDKURL].stringValue;
    BOOL forceUpdateJSSDK = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDForceUpdateJSSDK].boolValue;
    NSString *from = [config bdp_stringValueForKey:@"from"];
    // Event - Request Success
    [BDPVersionManager eventV3WithLibEvent:@"mp_lib_request_result"
                                      from:from
                             latestVersion:latestUpdateVersionString
                            latestGreyHash:jsLibGreyHash
                                resultType:@"success"
                                    errMsg:nil
                                  duration:0
                                   appType:OPAppTypeGadget];
    BDPLogInfo(@"%@", BDPParamStr(forceUpdateJSSDK, latestUpdateVersionString, latestBaseVersionString, url, useSpecificJSSDKURL, specificJSSDKURL));

    if (useSpecificJSSDKURL && specificJSSDKURL && specificJSSDKURL.length > 0) {
        url = specificJSSDKURL;
        latestBaseVersionString = @"99.99.99";
        latestUpdateVersionString = @"99.99.99.99";
        jsLibGreyHash = @"";
        BDPLogInfo(@"use specificJSSDKURL %@", BDPParamStr(url, latestBaseVersionString, latestUpdateVersionString));
    } else if (!forceUpdateJSSDK
               && ![BDPVersionManager isNeedUpdateLib:latestUpdateVersionString greyHash:jsLibGreyHash appType:OPAppTypeGadget]) {
        // Event - Don't Need Update SDK
        [BDPVersionManager eventV3WithLibEvent:@"mp_lib_validation_result"
                                          from:nil
                                 latestVersion:latestUpdateVersionString
                                latestGreyHash:jsLibGreyHash
                                    resultType:@"no_update"
                                        errMsg:nil
                                      duration:0
                                       appType:OPAppTypeGadget];
        [self updateLibComplete:NO];
        [self onLibUpdateCompleteWithUrl:nil latestUpdateVersionString:BDPVersionManager.localLibVersionString result:YES errorMsg:nil];
        BDPLogInfo(@"JSSDK is up to date %@", BDPParamStr(@(forceUpdateJSSDK), latestUpdateVersionString));
        return;
    }


    // Event - Need Update SDK
    [BDPVersionManager eventV3WithLibEvent:@"mp_lib_validation_result"
                                      from:nil
                             latestVersion:latestUpdateVersionString
                            latestGreyHash:jsLibGreyHash
                                resultType:@"need_update"
                                    errMsg:nil
                                  duration:0
                                   appType:OPAppTypeGadget];

    if (!url || !url.length) {
        // Event - Download Failure
        [BDPVersionManager eventV3WithLibEvent:@"mp_lib_download_result"
                                          from:nil
                                 latestVersion:latestUpdateVersionString
                                latestGreyHash:jsLibGreyHash
                                    resultType:@"fail"
                                        errMsg:@"Download URL is NULL."
                                      duration:0
                                       appType:OPAppTypeGadget];
        [self updateLibComplete:NO];
        return;
    }

    // url = @"http://127.0.0.1/__dev__.zip"
    BDPLogInfo(@"downloadLibWithURL %@", BDPParamStr(url, latestUpdateVersionString, latestBaseVersionString));
    WeakSelf;
    [BDPVersionManager downloadLibWithURL:url
                            updateVersion:latestUpdateVersionString
                              baseVersion:latestBaseVersionString
                                 greyHash:jsLibGreyHash
                                  appType:OPAppTypeGadget
                               completion:^(BOOL result, NSString *errorMsg) {
        StrongSelfIfNilReturn;
        [self updateLibComplete:result];
        //更新成功，把成功更新的jssdk在settings上配置的信息存下来
        if([OPSDKFeatureGating enableWaitJSSDKLoaded]){
            TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
            [storage setObject:config forKey:@"jssdk_setting_config"];
        }
        [self onLibUpdateCompleteWithUrl:url latestUpdateVersionString:latestBaseVersionString result:result errorMsg:errorMsg];
    }];
}

+ (void)checkJSSDKCacheAndCleanIfNeeded
{
    if([OPSDKFeatureGating enableWaitJSSDKLoaded]){
        BDPLogInfo(@"checkJSSDKCacheAndCleanIfNeeded");
        TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
        NSDictionary * config = [storage objectForKey:@"jssdk_setting_config"];
        //比较飞书版本和config里的 larkVersion，如果前者大于后者。需要清理
        NSString* bundleShortVersion = BDPDeviceTool.bundleShortVersion;
        NSString* larVersionInConfig = config[@"larkVersion"];
        BDPLogInfo(@"checkJSSDKCacheAndCleanIfNeeded compare with bundleShortVersion:%@ larVersionInConfig:%@", bundleShortVersion, larVersionInConfig);
        //飞书本身的版本比要大，则需要清空jssdk缓存
        if([BDPVersionManagerV2 compareVersion:bundleShortVersion with:larVersionInConfig] > 0) {
            BDPLogInfo(@"try to clean local lib cache");
            [BDPVersionManagerV2 resetLocalLibCache];
        }
    }
}

- (void)onLibUpdateCompleteWithUrl:(NSString *)url latestUpdateVersionString:(NSString *)latestUpdateVersionString result:(BOOL)result errorMsg:(NSString *)errorMsg {
    if (errorMsg) {
        BDPLogError(@"downloadLibWithURL error %@", BDPParamStr(@(result), errorMsg));
    }else {
        BDPLogInfo(@"downloadLibWithURL result %@", BDPParamStr(url, latestUpdateVersionString, @(result)));
    }

    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDShowJSSDKUpdateTips].boolValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                [UDToastForOC showSuccessWith:[NSString stringWithFormat:@"JSSDK updated successfully\n%@", latestUpdateVersionString]  on:OPWindowHelper.fincMainSceneWindow];
            }else {
                [UDToastForOC showFailureWith:[NSString stringWithFormat:@"JSSDK update failed\n%@", errorMsg] on:OPWindowHelper.fincMainSceneWindow];
            }
        });
    }
}

- (void)updateLibComplete:(BOOL)isSuccess {
    BDPLogInfo(@"updateLibComplete, isSuccess=%@", @(isSuccess));
    [BDPVersionManager updateLibComplete:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPJSSDKSyncForceUpdateFinishNoti
                                                        object:nil userInfo:@{@"isSuccess":@(isSuccess)}];
    BOOL useOptmize = [BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSJSLibPreloadOptmizeTma];
    if (!useOptmize) {
        // A/B 不使用优化后补充预加载
        BDPLogInfo(@"!useOptmize");
        // prepareTimor 中有setting 开关，判断是否要更新预加载来源
        [BDPTimorClient updatePreloadFromForPrepareTimor:@"lib_update"];
        [BDPTimorClient.sharedClient prepareTimor];
        return;
    }

    // A/B 使用优化后补充预加载
    if (isSuccess) {
        // 成功更新了JSSDK情况下，需要先清理已经完成的预加载缓存
        WeakSelf;
        BDPExecuteOnMainQueue(^{
            StrongSelfIfNilReturn;
            // 先清理已经预加载，需要在主线程才能保证同步执行清理
            [[BDPJSRuntimePreloadManager sharedManager] updateReleaseReason:@"optmize_lib_update_sucess"];
            [[BDPJSRuntimePreloadManager sharedManager] releasePreloadRuntimeIfNeed:BDPTypeNativeApp];
            [BDPAppPageFactory releaseAllPreloadedAppPageWithReason:@"optmize_lib_update_sucess"];

            [BDPTimorClient updatePreloadFrom:@"optmize_lib_update_sucess"];
            // 重新预加载
            [self preloadLibIfNeed];
        });
    } else {
        [BDPTimorClient updatePreloadFrom:@"optmize_lib_update_fail"];
        [self preloadLibIfNeed];
    }
}

+ (void)updatePreloadForPreloadLibIfNeed:(NSString * _Nonnull)preloadFrom {
    // 与preloadLibIfNeed 中判断逻辑保持一致，报纸真正触发预加载
    BOOL useOptmize = [BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSJSLibPreloadOptmizeTma];
    if (!useOptmize) {
        return;
    }
    [BDPTimorClient updatePreloadFrom:preloadFrom];
}

/// 在合适的时机检查是否需要预加载，如果需要，则立即开始预加载
- (void)preloadLibIfNeed {
    BOOL useOptmize = [BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSJSLibPreloadOptmizeTma];
    if (!useOptmize) {
        // A/B 不使用优化后补充预加载
        BDPLogInfo(@"!useOptmize");
        return;
    }

    BDPLogInfo(@"preloadLibIfNeed");
    // 检查 AppPage 的预加载
    [self preloadAppPageLibIfNeed];

    // 检查 JSRuntime 的预加载
    [self preloadJSRuntimeLibIfNeed];
}

/// 检查 AppPage 的预加载
- (void)preloadAppPageLibIfNeed {
    BOOL needCheckPreload = NO;
    NSTimeInterval preloadLibTimout = [BDPSettingsManager.sharedManager s_floatValueForKey:kBDPSJSLibPreloadTimeoutTma] ?: 20;
    NSInteger preloadLibRetryCount = [BDPSettingsManager.sharedManager s_integerValueForKey:kBDPSJSLibPreloadRetryCountTma] ?: 3;
    if (!BDPAppPageFactory.sharedManager.preloadAppPage) {
        BDPLogInfo(@"preload app page");
        // 如果尚未开始预加载，则开始预加载
        [BDPAppPageFactory.sharedManager reloadPreloadedAppPage];
        needCheckPreload = YES;
    } else {
        // 如果已经开始预加载，检查距离开始预加载是否已经超时/失败
        if (BDPAppPageFactory.sharedManager.preloadAppPage.isAppPageReady) {
            // 已经 Ready
            self.appPagePreloadRetryCount = 0;
        } else if (BDPAppPageFactory.sharedManager.preloadAppPage.bap_loadHtmlBegin && [NSDate.date timeIntervalSinceDate:BDPAppPageFactory.sharedManager.preloadAppPage.bap_loadHtmlBegin] < preloadLibTimout) {
            // 还在加载中但并未超时
            BDPLogInfo(@"app page preloading");
        } else {
            BDPLogWarn(@"preload app page timeout %@", BDPParamStr(self.appPagePreloadRetryCount));
            // 加载超时
            if (self.appPagePreloadRetryCount <= preloadLibRetryCount) {
                self.appPagePreloadRetryCount++;

                BDPLogInfo(@"preload app page (retry)");

                // 开始预加载
                [BDPAppPageFactory.sharedManager reloadPreloadedAppPage];
                needCheckPreload = YES;
            }
        }
    }
    if (needCheckPreload) {
        // 一段时间后再检查是否已经加载完成
        BDPLogInfo(@"delay check app page preload %@", BDPParamStr(preloadLibTimout));
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(preloadLibTimout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            BDPLogInfo(@"check app page preload");
            [self preloadAppPageLibIfNeed];
        });
    }
}

/// 检查 JSRuntime 的预加载
- (void)preloadJSRuntimeLibIfNeed {
    [[BDPJSRuntimePreloadManager sharedManager] setShouldPreloadRuntimeApp:YES];

    BOOL needCheckPreload = NO;
    NSTimeInterval preloadLibTimout = [BDPSettingsManager.sharedManager s_floatValueForKey:kBDPSJSLibPreloadTimeoutTma] ?: 20;
    NSInteger preloadLibRetryCount = [BDPSettingsManager.sharedManager s_integerValueForKey:kBDPSJSLibPreloadRetryCountTma] ?: 3;
    if (!BDPJSRuntimePreloadManager.sharedManager.preloadRuntimeApp) {
        BDPLogInfo(@"preload js runtime");
        // 如果尚未开始预加载，则开始预加载
        [BDPJSRuntimePreloadManager.sharedManager preloadRuntimeIfNeed:BDPTypeNativeApp];
        needCheckPreload = YES;
    } else {
        // 如果已经开始预加载，检查距离开始预加载是否已经超时/失败
        if (BDPJSRuntimePreloadManager.sharedManager.preloadRuntimeApp.loadTmaCoreEnd) {
            // 已经 Ready
            self.jsRuntimePreloadRetryCount = 0;
        } else if (BDPJSRuntimePreloadManager.sharedManager.preloadRuntimeApp.loadTmaCoreBegin && [NSDate.date timeIntervalSinceDate:BDPJSRuntimePreloadManager.sharedManager.preloadRuntimeApp.loadTmaCoreBegin] < preloadLibTimout) {
            // 还在加载中但并未超时
            BDPLogInfo(@"js runtime preloading");
        } else {
            BDPLogWarn(@"preload js runtime timeout %@", BDPParamStr(self.jsRuntimePreloadRetryCount));
            // 加载超时
            if (self.jsRuntimePreloadRetryCount < preloadLibRetryCount) {
                self.jsRuntimePreloadRetryCount++;

                BDPLogInfo(@"preload js runtime (retry)");

                // 开始预加载
                [BDPJSRuntimePreloadManager.sharedManager preloadRuntimeIfNeed:BDPTypeNativeApp];
                needCheckPreload = YES;
            }
        }
    }
    if (needCheckPreload) {
        // 一段时间后再检查是否已经加载完成
        BDPLogInfo(@"delay check js runtime preload %@", BDPParamStr(preloadLibTimout));
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(preloadLibTimout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            BDPLogInfo(@"check js runtime preload");
            [self preloadJSRuntimeLibIfNeed];
        });
    }
}

@end
