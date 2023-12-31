//
//  EERoute.m
//  EEMicroAppSDK
//
//  Created by fanlv on 2018/4/14.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EERoute.h"
#import "BDPPluginLoadingViewCustomImpl.h"
#import "EMAAppDelegate.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMAAppEngineAccount.h>
#import <OPFoundation/EMAAppEngineConfig.h>
#import "EMAAppUpdateManager.h"
#import <OPFoundation/OPBundle.h>
#import "EMADebugUtil+Business.h"
#import "EMADebuggerManager.h"
#import <OPFoundation/EMADeviceHelper.h>
#import <OPFoundation/EMAFeatureGating.h>
#import "EMAI18n.h"
#import "EMALifeCycleAuthorizationManager.h"
#import "EMALifeCycleManager.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <ECOInfra/EMANetworkManager.h>
#import "BDPRouteMediatorDelegate.h"
#import <OPFoundation/EMARouteMediator.h>
#import "EMAUserAuthorizationSynchronizer.h"
#import <OPFoundation/NSURL+EMA.h>
#import <OPFoundation/NSURLComponents+EMA.h>
#import "SSLocalModel.h"
#import "TMAPluginCustomImplRegister.h"
#import <ECOInfra/ECOInfra-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <LKTracing/LKTracing-Swift.h>
#import <OPGadget/OPGadget-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <TTRoute/TTRoute.h>
#import <TTMicroApp/BDPAppPageFactory.h>
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPBootstrapHeader.h>
#import <TTMicroApp/BDPCPUMonitor.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <TTMicroApp/BDPFPSMonitor.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <OPFoundation/BDPI18n.h>
#import <OPJSEngine/BDPJSRuntimeSocketConnection.h>
#import <TTMicroApp/BDPLocalFileManager.h>
#import <TTMicroApp/BDPMemoryMonitor.h>
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <TTMicroApp/BDPPackageModuleProtocol.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <TTMicroApp/BDPStorageManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPTracker.h>
#import <TTMicroApp/BDPURLProtocolManager.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/BDPWarmBootManager.h>
#import <TTMicroApp/BDPWebAppEngine.h>
#import <OPFoundation/EEFeatureGating.h>
#import <TTMicroApp/BDPAppLoadManager+Util.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/EMAConfigManager.h>
#import <ECOInfra/TMAKVDatabase.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPEnvTypeHelper.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/BDPAppPagePrefetchManager.h>
#import <TTMicroApp/BDPGadgetPreLoginManager.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <TTMicroApp/BDPTask.h>
#import <TTMicroApp/BDPSubPackageManager.h>
#import <ECOInfra/ECOInfra.h>
#import <ECOInfra/ECOConfigService.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <OPFoundation/UIColor+OPExtension.h>
#import <TTMicroApp/OPLoadingView.h>
#import <TTMicroApp/BDPEngineAssembly.h>
#import <OPFoundation/BDPVersionManager.h>
#import <TTMicroApp/BDPJSRuntimePreloadManager.h>
#import <TTMicroApp/OPVersionDirHandler.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/BDPSchemaCodec+Private.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/OPUtils.h>
#import "EMAPermissionManager.h"

static const NSInteger EESceneUndefinedCode = 1000;
static NSString *EEAppearanceColor = @"#3377FF";
/// tabBar badge red dot color
static NSString *EETabBarRedDotColor = @"#F54A45";
static const NSTimeInterval kLoadingDismissAnimationDuration = 0.2f;
static NSString * kBDPPreLoadUANoti = @"kBDPPreLoadUANoti";

@interface EERoute ()

/// 需要Lark提供对应能力的代理
@property (nonatomic, weak, readwrite, nullable) id<EMAProtocol> delegate;

@property (nonatomic, assign, readwrite) BOOL isFinishLogin;
@end

@implementation EERoute
@synthesize liveFaceDelegate = _liveFaceDelegate;

#pragma mark - life cycle

+ (instancetype _Nonnull)sharedRoute
{
    static EERoute *sharedRoute;

    BOOL needSetup = !sharedRoute;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRoute = [[EERoute alloc] init];
    });
    // 分开初始化是因为避免setupConfig中调用sharedRoute造成onceTokenBlock重入异常
    if (needSetup) {
        [sharedRoute setupConfig];
    }
    return sharedRoute;
}

/// 只会执行一次，这里可以进行一些全局的静态注册和绑定
- (void)setupConfig {
    /*-----------------------------------------------------------------------*/
    //    ⚠️此处代码请谨慎处理，请尽量进行简单纯碎的静态注册和绑定操作，避免文件操作⚠️
    /*-----------------------------------------------------------------------*/

    // 绑定tracing生成算法
    [BDPTracingManager.sharedInstance registerTracing:[LKTracing identifier]
                                         generateFunc:^NSString *(NSString * parentTraceId) {
        return [LKTracing newSpanWithTraceId:parentTraceId];
    }];

    // 注册生命周期监听
    [EMALifeCycleManager.sharedInstance addListener:[EMALifeCycleAuthorizationManager sharedInstance]];

    [[BDPRouteMediatorDelegate shared] setDelegate];

    BDPRouteMediator.sharedManager.isAppTestForUniqueID = ^BOOL(BDPUniqueID *uniqueID) {
        return [EMAAppEngine.currentEngine.onlineConfig isMicroAppTestForUniqueID:uniqueID];
    };
    BDPRouteMediator.sharedManager.checkDomainsForUniqueID = ^BOOL(BDPUniqueID *uniqueID) {
        return [EMAAppEngine.currentEngine.onlineConfig checkDomainsForUniqueID:uniqueID];
    };
    BDPRouteMediator.sharedManager.isJSAPIInAllowlist = ^BOOL(NSString * jsapiName){
        return [EMAAppEngine.currentEngine.onlineConfig isJSAPIInAllowlist:jsapiName];
    };
    BDPRouteMediator.sharedManager.setStorageLimitCheck = ^BOOL() {
        return [EMAAppEngine.currentEngine.onlineConfig setStorageLimitCheck];
    };

    BDPRouteMediator.sharedManager.isVideoAvoidSameLayerRenderForUniqueID = ^BOOL(BDPUniqueID *uniqueID){
        return [EMAAppEngine.currentEngine.onlineConfig isVideoAvoidSameLayerRenderForUniqueID:uniqueID];
    };
    BDPRouteMediator.sharedManager.getSystemInfoHeightInWhiteListForUniqueID = ^BOOL(BDPUniqueID *uniqueID){
        return [EMAAppEngine.currentEngine.onlineConfig isGetSystemInfoHeightInWhiteListOfUniqueID:uniqueID];
    };
    BDPRouteMediator.sharedManager.allowHttpForUniqueID = ^BOOL(BDPUniqueID *uniqueID) {
        return YES;
    };
    BDPRouteMediator.sharedManager.configSchemeParameterAppListFetch = ^NSDictionary *{
        return [EMAAppEngine.currentEngine.onlineConfig configSchemeParameterAppList];
    };

    BDPTimorClient *client = [BDPTimorClient sharedClient];
    client.appearanceConfg.positiveTextColor = [UIColor colorWithHexString:(NSString *)EEAppearanceColor];
    client.appearanceConfg.positiveColor = [UIColor colorWithHexString:(NSString *)EEAppearanceColor];
    client.appearanceConfg.tabBarRedDotColor = UDOCColor.functionDanger500;

    /// 针对DEBUG模式，关闭JSContext线程保护
#ifdef DEBUG
    [[BDPTimorClient sharedClient] enableJSThreadCrashProtection:NO];
#else
    [[BDPTimorClient sharedClient] enableJSThreadCrashProtection:YES];
#endif
}

// TODO: 这种一次性的代码需要重构，需要实现可复用的AB-Settings同步逻辑
- (NSDictionary *)preloadABTestDicWith:(nullable id<EMAProtocol>)delegate
{
    NSDictionary * flagDic = @{@"use": @(YES)}; // 默认配置
    if ([delegate respondsToSelector:@selector(getExperimentValueForKey:withExposure:)]) {
        flagDic = [delegate getExperimentValueForKey:@"preload"
                                        withExposure:YES];
    }

    // TDDO: 这种每次都要手工导入AB-Key和Settings-Key的映射，AB和Settings的关系需要重构。需要考虑命名空间问题，避免随意命名的冲突（因此这里没有直接全部导入）。
    NSMutableDictionary *preloadSettings = NSMutableDictionary.dictionary;
    preloadSettings[kBDPSABTestAppPreloadDisableTma] = @(![flagDic bdp_boolValueForKey:@"use"]);    // 之前的配置 AB-Key 和 Settings-Key 没有对齐
    preloadSettings[kBDPSJSLibPreloadOptmizeTma] = flagDic[kBDPSJSLibPreloadOptmizeTma];
    preloadSettings[kBDPSJSLibPreloadRetryCountTma] = flagDic[kBDPSJSLibPreloadRetryCountTma];
    preloadSettings[kBDPSJSLibPreloadTimeoutTma] = flagDic[kBDPSJSLibPreloadTimeoutTma];
    preloadSettings[kBDPSJSLibPreloadDelayAfterLaunchTma] = flagDic[kBDPSJSLibPreloadDelayAfterLaunchTma];
    return preloadSettings.copy;
}

- (void)loginWithDelegate:(id<EMAProtocol> _Nullable)delegate
              accoutToken:(NSString * _Nonnull)accountToken
                   userID:(NSString * _Nonnull)userID
              userSession:(NSString * _Nonnull)userSession
                  envType:(OPEnvType)envType
             domainConfig:(MicroAppDomainConfig * _Nonnull)domainConfig
                  channel:(NSString * _Nonnull)channel
                 tenantID:(NSString * _Nonnull)tenantID {
    //  Lark能力注入，所有调用Lark能力需要在这一行之后(包括日志)
    self.delegate = delegate;
    self.userID = userID;
    // 这行代码后续迁移到 OpenPlatform 统一的初始化入口(暂时没有待建设)
    OPEnvTypeHelper.envType = envType;

    EMAAppEngineAccount *account = [[EMAAppEngineAccount alloc] initWithAccount:accountToken
                                                                         userID:userID
                                                                    userSession:userSession
                                                                       tenantID:tenantID];

    EMAAppEngineConfig *config = [[EMAAppEngineConfig alloc] initWithEnvType:envType
                                                                domainConfig:domainConfig
                                                                     channel:channel];

    BDPLogTagInfo(BDPTag.gadget, @"gadget engine login")
    [EMAAppEngine loginWithAccount:account config:config];
    [BDPSettingsManager.sharedManager addSettings:[self preloadABTestDicWith:delegate]];
    //获取settings配置，如果存在，添加到BDPSettings里
    //检查 bdp_settings_all_in_one 配置存在与否，如果存在合并 BDPSettingsManager 中原有的配置
    id<ECOConfigService> configService = [ECOConfig service];
    NSDictionary * bdp_settings_all_in_one = [configService getLatestDictionaryValueForKey:@"bdp_settings_all_in_one"];
    [BDPSettingsManager.sharedManager addSettings:BDPSafeDictionary(bdp_settings_all_in_one)];
    
    // 读取 BDPPluginNetworkImpl注入时机优化 兜底开关逻辑 (稳定一段时间后会删除这段逻辑)
    [BDPPluginNetworkImpl refreshNetworkPluginBugfixFGOnce];

    //开关打开，早点注入 protocolClass
    if ([OPSDKFeatureGating enableRustInGetAppMeta] == YES) {
        [self turnOnNetworkTransmitOverRust];
    }
    
    /*----------------------------------------------------------*/
    //      ⚠️下面这段代码请谨慎处理，保证尽早调用初始化文件路径⚠️
    /*----------------------------------------------------------*/
    // 设置支持多用户存储的小程序相关文件存放路径，需要尽早设置路径
    // 用于退出登录时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
    [BDPStorageManager clearSharedManager];
    [BDPEngineAssembly clearAllSharedLocalFileManagers];
    [BDPURLProtocolManager clearSharedInstance];
    /*----------------------------------------------------------*/
    //      ⚠️上面这段代码请谨慎处理，保证尽早调用初始化文件路径⚠️
    /*----------------------------------------------------------*/
    
    //小程序JSSDK检查沙箱缓存，如果有必要则进行清理
    [EMALibVersionManager checkJSSDKCacheAndCleanIfNeeded];
    ///切换租户的时候，清理JSSDK 全局变量存储的缓存版本，否则切换租户后容易拿到lark启动时候的租户的JSSDK版本，导致切换后的租户JSSDK获取本地版本错误，造成JSSDK版本无法更新的问题
    [BDPVersionManager resetLocalLibVersionCache:OPAppTypeGadget];
    [BDPVersionManager resetLocalLibVersionCache:OPAppTypeBlock];
    /// 切换租户时，清理所有预安装任务里的待办
    if ([BDPPreloadHelper preloadEnable]) {
        [BDPPreloadHandlerManagerBridge cancelAndCleanAllTasks];
    }

    BDPLogInfo(@"login, userId=%@, envType=%@, channel=%@", userID, @(envType), channel);

    // KA Cookie migration
    [KACookieMigration migrateWithUserId: userID];

    //开关关闭，保持原有逻辑
    if ([OPSDKFeatureGating enableRustInGetAppMeta] == NO) {
        [self turnOnNetworkTransmitOverRust];
    }
    
    BDPSDKConfig.sharedConfig.shouldUseNewBridge = YES;
    
    [BDPSDKConfig sharedConfig].userLoginURL = [EMAAPI userLoginURL];
    [BDPSDKConfig sharedConfig].userInfoURL = [EMAAPI userInfoURL];
    [BDPSDKConfig sharedConfig].userInfoH5URL = [EMAAPI userInfoH5URL];
    [BDPSDKConfig sharedConfig].appMetaURL = [EMAAPI appMetaURL];
    [BDPSDKConfig sharedConfig].batchAppMetaURL = [EMAAPI batchAppMetaURL];
    BDPSDKConfig.sharedConfig.cardMetaUrls = EMAAPI.cardMetaUrls;
    [BDPSDKConfig sharedConfig].unsupportedUnconfigDomainURL = EMAAPI.webviewURLNotSupportPage;
    [BDPSDKConfig sharedConfig].serviceRefererURL = EMAAPI.serviceRefererURL;
    [BDPSDKConfig sharedConfig].checkSessionURL = EMAAPI.checkSessionURL;

    [BDPSDKConfig sharedConfig].unsupportedContextURL = EMAAPI.unsupportedContextURL;
    [BDPJSRuntimePreloadManager releaseAllPreloadRuntimeWithReason:@"route_for_login"];
    [BDPAppPageFactory releaseAllPreloadedAppPageWithReason:@"route_for_login"];

    // app安装后首次启动先使用内置的js sdk
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //JSSDK准备阶段有耗时操作，移入子线程实现
        [BDPVersionManager setupBundleVersionIfNeed:OPAppTypeGadget];
        if (![OPVersionDirHandler sharedInstance].enableFixBlockCopyBundleIssue) {
            [BDPVersionManager setupBundleVersionIfNeed:OPAppTypeBlock];
        }
        //准备消息卡片的预置包资源
        [BDPVersionManager setupBundleVersionIfNeed:OPAppTypeSDKMsgCard];
    });

    [[self class] clearAppModelsWhenAppLanguageChanged];

    BDPTimorClient *client = [BDPTimorClient sharedClient];
    client.loadingViewPlugin = [BDPPluginLoadingViewCustomImpl class];
    client.appearanceConfg.loadingViewDismissAnimationDuration = kLoadingDismissAnimationDuration;
    client.appearanceConfg.hideAppWhenLaunchError = YES;

    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigForceOpenAppDebug].boolValue) {
        // 强制开启小程序调试(VConsole)
        BDPSDKConfig.sharedConfig.forceAppDebugOpen = YES;
    }
    BDPSDKConfig.sharedConfig.debugRuntimeType = OPRuntimeTypeUnknown;

    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDWorkerDonotUseNetSetting].boolValue) {
        if ([EMADebugUtil.sharedInstance debugConfigForID: kEMADebugConfigIDUseVmsdk].boolValue) {
            BDPSDKConfig.sharedConfig.debugRuntimeType = OPRuntimeTypeVmsdkJscore;
            if ([EMADebugUtil.sharedInstance debugConfigForID: kEMADebugConfigIDUseVmsdkQjs].boolValue) {
                BDPSDKConfig.sharedConfig.debugRuntimeType = OPRuntimeTypeVmsdkQjs;
            }
        } else {
            BDPSDKConfig.sharedConfig.debugRuntimeType = OPRuntimeTypeJscore;
        }
    }
    BDPSDKConfig.sharedConfig.showDebugWorkerTypeToast = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDShowWorkerTypeTips].boolValue;
    BDPSDKConfig.sharedConfig.appLaunchInfoDeleteOldDataDays = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDOPAppLaunchDataDeleteOld].stringValue;
    [TMAPluginCustomImplRegister.sharedInstance applyAllCustomPlugin];

    [EMAAppEngine.currentEngine startup];

    [self didEngineLogined];
    
    OPGadgetDRManager *drManager = [OPGadgetDRManager shareManager];
    drManager.isFinishLogin = YES;
    // 更新容灾配置开关
    [drManager updateDRSwitch];
    if ([drManager enableServerSettingsDR]) {
        //Setting下发容灾
        NSDictionary<NSString *, id> *recoverConfig = [[OPGadgetDRManager safeConfigService] getLatestDictionaryValueForKey:@"miniapp_disaster_recover_config"];
        NSString *configMD5 = OPSafeString([[recoverConfig bdp_jsonString] bdp_md5String]);
        NSString *safeUserID = OPSafeString([userID bdp_md5String]);
        [[OPGadgetDRManager shareManager] settingUpdateForDR:recoverConfig md5:configMD5 userID:safeUserID];
    }

    // 注入js worker的解释器
    if ([delegate respondsToSelector:@selector(registerWorkerInterpreters)]) {
        NSDictionary *interpreters = [delegate registerWorkerInterpreters];
        [[OpenJSWorkerInterpreterManager shared] registerWithConfigs:interpreters];
    }
    
    // 执行一次相关数据更新及预加载
    [self updateRelativeData];

    /**
     主端调用小程序登录接口时机可能会早于loginWithDelegate时机, 进而导致loginURL还没来得及同步导致网络请求异常;
     这边使用这个状态进行控制;(这个逻辑作为临时解决方案;后续有其他完整解决方案进行替换)
     */
    self.isFinishLogin = YES;
    if (self.loginFinishCallback) {
        self.loginFinishCallback();
        self.loginFinishCallback = nil;
    }

    // 发送EERoute登录成功通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kEERouteLoginFinishedNotification" object:nil userInfo:nil];
    /*----------------------------------------------------------*/
    //      ⚠️上面这行是本函数最后一行⚠️
    /*----------------------------------------------------------*/
}

- (void)updateRelativeData {
    BOOL cacheEnableOptimize = [BDPTimorClient enableOptimizeUpdateRelativeData];
    if(cacheEnableOptimize) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            BDPTimorClient *client = [BDPTimorClient sharedClient];
            if ([[client globalConfiguration] shouldAutoUpdateRelativeData]) {
                [client updateRelativeDataIfNeed];
            }
        });
    }
    BOOL enableOptimizeUpdate = [OPSDKFeatureGating enableOptimizeUpdateRelativeData];
    [BDPTimorClient setOptimizeRelativeDataUpdate: enableOptimizeUpdate];
    BDPLogInfo(@"updateRelativeDataIfNeed, cacheEnableOptimize:%@, FGEnableOptimize :%@",@(cacheEnableOptimize),@(enableOptimizeUpdate));
}

-(void)turnOnNetworkTransmitOverRust{
    // 注册网络请求sharedSession
    BOOL shouldNetworkTransmitOverRustChannel = [EMAFeatureGating boolValueForKey:EMAFeatureGatingKeyMicroAppNetworkRust];
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDForcePrimitiveNetworkChannel].boolValue) {
        shouldNetworkTransmitOverRustChannel = NO;
    }

    BDPLogDebug(@"shouldNetworkTransmitOverRustChannel: %@", shouldNetworkTransmitOverRustChannel ? @"YES" : @"NO");
    [EMANetworkManager.shared configSharedURLSessionConfigurationOverRustChannel:shouldNetworkTransmitOverRustChannel];
}

/// 已完成登录，执行启动后的一些不重要的工作
- (void)didEngineLogined {

    [EMAAppUpdateManager.sharedInstance checkCachedPush];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(_preloadUA)
                                                   name:kBDPPreLoadUANoti
                                                 object:nil];
    NSNotification *notification = [NSNotification notificationWithName:kBDPPreLoadUANoti
                                                                    object:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                   postingStyle:NSPostWhenIdle
                                                   coalesceMask:kBDPPreLoadUANoti
                                                       forModes:nil];
}

- (void)logout {
    //默认在3.46上不允许 EMAppEngine的logout，解决华润配置首屏tab小程序时session秒空获取meta异常的问题
    //（login会重新初始化，理论上不会存在问题）
    BDPLogTagInfo(BDPTag.gadget, @"gadget engine logout");
    [EMAAppEngine logout];
    // 切换租户或者登出，修改状态
    [OPGadgetDRManager shareManager].isFinishLogin = NO;

    [[BDPAppPagePrefetchManager sharedManager] logout];
    [[BDPSubPackageManager sharedManager] cleanAllReaders];
    /**
     主端调用小程序登录接口时机可能会早于loginWithDelegate时机, 进而导致loginURL还没来得及同步导致网络请求异常;
     这边使用这个状态进行控制;(这个逻辑后续有其他完整解决方案进行替换)
     */
    self.isFinishLogin = NO;
}

#pragma mark - Delegate

- (nullable id<EMALiveFaceProtocol>)liveFaceDelegate {
    return _liveFaceDelegate;
}

#pragma mark - route

- (void)clearTaskCache {
    BDPLogTagInfo(BDPTag.gadget, @"clear task cache");
    [BDPTimorClient.sharedClient clearAllWarmBootCache];
}

- (void)clearTaskCacheWithUniqueID:(BDPUniqueID *)uniqueID {
    BDPLogTagInfo(BDPTag.gadget, @"clearTaskCacheWithUniqueID, uniqueID=%@", uniqueID);
    [BDPWarmBootManager.sharedManager cleanCacheWithUniqueID:uniqueID];
}

- (void)setJSSDKUrlString:(NSString *)urlString{
    BDPLogTagInfo(BDPTag.gadget, @"setJSSDKUrlString, url=%@", urlString);
    if (urlString) {
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificJSSDKURL].stringValue = urlString;
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL].boolValue = YES;
    } else {
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificJSSDKURL].boolValue = NO;
    }
    [EMAAppEngine.currentEngine.configManager updateConfig];
}

- (void)setBlockJSSDKUrlString:(NSString *)urlString {
    BDPLogTagInfo(BDPTag.gadget, @"setJSSDKUrlString, url=%@", urlString);
    if (urlString) {
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDSpecificBlockJSSDKURL].stringValue = urlString;
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificBlockJSSDKURL].boolValue = YES;
    }else{
        [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDUseSpecificBlockJSSDKURL].boolValue = NO;
    }
}

- (BOOL)openURLByPushViewController:(NSURL *)url window:(UIWindow *)window {
    BDPLogInfo(@"openURLByPushViewController, url=%@", url);
    return [self openURLByPushViewController:url scene:EESceneUndefinedCode window:window];
}

- (void)realMatchineDebugOpenURL:(NSURL *)url window:(UIWindow *)window {
    // 已经在真机调试，则跳过
    if ([BDPJSRuntimeSocketConnection hasConnection]) {
        BDPLogWarn(@"has connection");
        return;
    }

    WeakSelf;
    [EMALarkAlert showAlertWithTitle:EMAI18n.sure_to_test_on_device
                             content:nil
                             confirm:BDPI18n.confirm
                      fromController:[OPNavigatorHelper topMostAppControllerWithWindow:window]
                     confirmCallback:^{
        StrongSelfIfNilReturn
        [self _openURLByPushViewController:url realMatchineDebug:YES scene:EESceneUndefinedCode window:window channel:@"" applinkTraceId:@"" extra:nil];
    } showCancel:YES];
}

- (BOOL)openURLByPushViewController:(NSURL *)url
                              scene:(NSInteger)scene
                             window:(UIWindow *)window {
    return [self _openURLByPushViewController:url
                            realMatchineDebug:NO
                                        scene:scene
                                       window:window
                                      channel:@""
                               applinkTraceId:@""
                                        extra:nil];
}

- (BOOL)openURLByPushViewController:(NSURL *)url
                              scene:(NSInteger)scene
                             window:(UIWindow *)window
                            channel:(NSString *)channel
                     applinkTraceId: (NSString *)applinkTraceId {
    return [self _openURLByPushViewController:url
                            realMatchineDebug:NO
                                        scene:scene
                                       window:window
                                        channel:channel
                               applinkTraceId:applinkTraceId
                                        extra:nil];
}

- (BOOL)openURLByPushViewController:(NSURL *)url
                              scene:(NSInteger)scene
                             window:(UIWindow *)window
                            channel:(NSString *)channel
                     applinkTraceId: (NSString *)applinkTraceId
                              extra:(MiniProgramExtraParam *)extra {
    return [self _openURLByPushViewController:url
                            realMatchineDebug:NO
                                        scene:scene
                                       window:window
                                        channel:channel
                               applinkTraceId:applinkTraceId
                                        extra:extra];
}


/// 打开小程序
/// @param url schema
/// @param realMatchineDebug 是否真机调试
/// @param scene 场景值
- (BOOL)_openURLByPushViewController:(NSURL *)url
                   realMatchineDebug:(BOOL)realMatchineDebug
                               scene:(NSInteger)scene
                              window:(UIWindow *)window
                             channel:(NSString *)channel
                      applinkTraceId:(NSString *)applinkTraceId
                               extra:(MiniProgramExtraParam *)extra {
    BDPTracing *tracing = [BDPTracingManager.sharedInstance generateTracingWithParent:nil];
    [BDPTracingManager bindCurrentThreadTracing:tracing];
    BDPLogInfo(@"openViewController url=%@, scene=%@", url, @(scene));
    NSError *error = nil;
    BDPSchema *schema = [BDPSchemaCodec schemaFromURL:url appType:OPAppTypeGadget error:&error];
    //打开小程序的入口处进行prelogin 预登陆逻辑
    if (schema && !error && schema.uniqueID) {
        BDPUniqueID * uniqueId = schema.uniqueID;
        BDPTask * existedTask =  [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueId];
        //在这里做一些只在冷启动时进行的预热优化
        //如果 existedTask 是空的，则执行一些冷启动预任务
        if (existedTask==nil) {
            [[BDPGadgetPreLoginManager sharedInstance] preloginWithUniqueId:uniqueId
                                                                   callback:nil];
        }
    }

    if (schema && !error) {
        [[RouteOCBadge gadgetContainerServiceFrom: OPApplicationService.current] fastMountByPushWithUrl:url scene:scene window:window channel: channel applinkTraceId: applinkTraceId extra: extra];
        return YES;
    }
    
    SSLocalModel *sslocalMode = [[SSLocalModel alloc] initWithURL:url];
    [self preprocessBySSLocalModel:sslocalMode];
    [self gadgetReportStart:sslocalMode schema:url scene:scene];
    url = [self joinUrl:url scene:scene];
    
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    params[kTargetWindowKey] = window;
    
    /// 对于真机调试需要传递真机调试参数
    /// 原 `realMatchineDebugOpenURL` 方法已经无从调用，这里根据扫码的 schema 内容判定：isdev && ws_for_debug 的情况下，认为是真机调试
    if (sslocalMode.isdev && !BDPIsEmptyString(sslocalMode.ws_for_debug)) {
        params[kRealMachineDebugAddressKey] = sslocalMode.ws_for_debug;
        BDPLogInfo(@"enable RealMachineDebug for url: %@", url);
    }
    
    TTRouteUserInfo *userInfo = [[TTRouteUserInfo alloc] initWithInfo:params];
    
    /// 正常启动
    return [[TTRoute sharedRoute] openURLByPushViewController:url userInfo:userInfo];
}


- (UIViewController *)getViewControllerByURL:(NSURL *)url scene:(NSInteger)scene window:(UIWindow *)window {
    BDPLogInfo(@"getViewControllerByURL, url=%@, scene=%@", url, @(scene));
    SSLocalModel *sslocalMode = [[SSLocalModel alloc] initWithURL:url];
    [self preprocessBySSLocalModel:sslocalMode];
    [self gadgetReportStart:sslocalMode schema:url scene:scene];
    url = [self joinUrl:url scene:scene];
    BDPTimorClient *client = [BDPTimorClient sharedClient];
    return [client containerControllerWithURL:url window:window];
}

- (void)preprocessBySSLocalModel:(SSLocalModel *)model {
    EMADebugConfig *config = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDForceColdStartMicroApp];
    if (config.boolValue) {
        // 强制冷启动小程序
        [EMADebugUtil.sharedInstance clearMicroAppProcesses];
    }

    NSString *app_id = model.app_id;
    if (app_id && [model.useCache isEqualToString:@"0"]) {
        
        // 老的VC可能正在显示，需要首先清理掉老的VC
        BDPTask *task = BDPTaskFromUniqueID(model.uniqueID);
        UIViewController *containerVC = task.containerVC;
        if (containerVC.navigationController) {
            NSMutableArray *viewControllers = containerVC.navigationController.viewControllers.mutableCopy;
            [viewControllers removeObject:containerVC];
            [containerVC.navigationController setViewControllers:viewControllers.copy animated:NO];
        }
        
        // 然后再清理热缓存（该方法无法做到自动清理VC）
        [BDPWarmBootManager.sharedManager cleanCacheWithUniqueID:model.uniqueID];
    }

    if (BDPIsEmptyString(app_id) || model.ws_for_debug || model.isdev == 1) {
        EMADebugUtil.sharedInstance.usedDebugApp = YES;  // 调试过小程序
    }
}

- (NSURL *)joinUrl:(NSURL *)url scene:(NSInteger)scene {
    if ([url.query containsString:@"scene"]) {
        NSURLComponents *component = [NSURLComponents componentsWithString:url.absoluteString];
        [component setQueryItemWithKey:@"scene" value:@(scene).stringValue];
        return component.URL;
    } else {
        NSString *string = [url.absoluteString stringByAppendingString:[NSString stringWithFormat:@"&scene=%d", scene]];
        return [NSURL URLWithString:string];
    }
}

- (EMAConfig *)onlineConfig {
    return EMAAppEngine.currentEngine.onlineConfig;
}

- (void)updateDebug {
    [EMADebugUtil.sharedInstance updateDebug];
}

#pragma mark --H5 JsApi
- (void)invokeWebMethod:(NSString *)method
                 params:(NSDictionary *)params
                 engine:(id)engine
             controller: (UIViewController *)controller
               needAuth:(BOOL)needAuth
shouldUseNewbridgeProtocol:(BOOL)shouldUseNewbridgeProtocol
                  trace: (OPTrace *)trace
               webTrace: (OPTrace *)webTrace {
    BDPTracing *tracing = [BDPTracingManager.sharedInstance generateTracingWithParent:nil];
    [BDPTracingManager bindCurrentThreadTracing:tracing];
    //  增加一个shouldUseNewbridgeProtocol用于灰度
    BDPWebAppEngine *instance = [BDPWebAppEngine getInstance:controller
                                                       jsImp:engine
                                  shouldUseNewbridgeProtocol:shouldUseNewbridgeProtocol];
    [instance invokeMethod:method params:params jsImp:engine controller:controller needAuth:needAuth trace:trace webTrace:webTrace];
    BDPLogTagInfo(@"H5JSAPI", @"recieve h5api invoke, method=%@, app=%@|%@", method, instance.uniqueID, @(instance.uniqueID.appType));
    BDPAuthorization *auth = instance.authorization;
    if (auth) {
        [EMAPermissionManager.sharedManager setWebAppAuthProviderForUniqueID:instance.uniqueID authProvider:auth];
    }
}

#pragma mark - mock

- (BOOL)debugEnable {
    return EMADebugUtil.sharedInstance.enable;
}

- (void)setDebugEnable:(BOOL)debugEnable {
    BDPLogInfo(@"setDebugEnable = %@", @(debugEnable));
    [EMADebugUtil.sharedInstance setEnable:debugEnable];
}

#pragma mark - Permission

/**
 获取应用权限数据
 
 @param uniqueID uniqueID
 @return 权限数组
 */
- (NSArray<EMAPermissionData *> *)getPermissionDataArrayWithUniqueID:(BDPUniqueID *)uniqueID {
    EMAPermissionManager *manager = [EMAPermissionManager sharedManager];
    return [manager getPermissionDataArrayWithUniqueID:uniqueID];
}

/**
 设置应用权限

 @param permissons 标识授权状态的键值对：@{(NSString *)scopeKey: @((BOOL)approved)}
 @param uniqueID uniqueID
 */
- (void)setPermissons:(NSDictionary<NSString *, NSNumber *> *)permissons uniqueID:(BDPUniqueID *)uniqueID {
    EMAPermissionManager *manager = [EMAPermissionManager sharedManager];
    [manager setPermissons:permissons uniqueID:uniqueID];
}

/// 处理 wsURL 调用
- (void)handleDebuggerWSURL:(NSString * _Nonnull)wsURL {
    [EMADebuggerManager.sharedInstance handleDebuggerWSURL:wsURL];
}

- (void)fetchAuthorizeData:(BDPUniqueID *)uniqueID storage:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion {
    EMAPermissionManager *manager = [EMAPermissionManager sharedManager];
    [manager fetchAuthorizeData:uniqueID storage:storage completion:completion];
}

#pragma mark - language

static NSString *const kLocalAppLanguage = @"kLocalAppLanguage";

/// 飞书国际化语言更改后，删除缓存的meta，强制先拉取最新的meta，以在loading界面显示对应语言的小程序名称
+ (void)clearAppModelsWhenAppLanguageChanged {
    TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
    NSString *localAppLanguage = [storage objectForKey:kLocalAppLanguage];
    NSString *currentAppLanguage = [BDPApplicationManager language];
    if (BDPIsEmptyString(localAppLanguage)) {
        /// 更新本地语言
        [storage setObject:currentAppLanguage forKey:kLocalAppLanguage];
        return;
    }
    if ([localAppLanguage isEqualToString:currentAppLanguage]) {
        return;
    }
    BDPLogInfo(@"clearAppModelsWhenAppLanguageChanged from %@ to %@", localAppLanguage, currentAppLanguage)
    /// 更新本地语言
    [storage setObject:currentAppLanguage forKey:kLocalAppLanguage];

    //  更新语言需要删除meta
    [self deleteMeta];
}

/// 删除meta
+ (void)deleteMeta {
    BDPLogInfo(@"change language, delete all meta")

    // 小程序meta删除
    [BDPAppLoadManager clearAllMetas];
    
    //  卡片的meta删除
    [BDPGetResolvedModule(MetaInfoModuleProtocol, BDPTypeNativeCard) removeAllMetas];
}

- (void)_preloadUA {
    [BDPUserAgent getUserAgentString];
}

#pragma mark - report
- (void)gadgetReportStart:(SSLocalModel *)model schema:(NSURL *)schema scene:(NSInteger)scene {
    BDPType appType = BDPTypeNativeApp;
    BDPUniqueID *uniqueID = model.uniqueID;
    OPMonitorEvent *event = BDPMonitorWithName(kEventName_mp_app_launch_start, uniqueID).timing();

    BDPTask *task = BDPTaskFromUniqueID(uniqueID);

    BDPTracing *trace = [BDPTracingManager.sharedInstance getTracingByUniqueID:model.uniqueID];
    if (!task) {
        if (trace) {
            BDPLogWarn(@"clearTracing for last launch: %@", trace.traceId);
            [BDPTracingManager.sharedInstance clearTracingByUniqueID:model.uniqueID];
        }
        trace = [BDPTracingManager.sharedInstance generateTracingByUniqueID:model.uniqueID];
        [trace clientDurationTagStart:kEventName_mp_app_launch_start];
    }

    id<BDPPackageInfoManagerProtocol> packageInfoManager = BDPGetResolvedModule(BDPPackageModuleProtocol, uniqueID.appType).packageInfoManager;
    NSInteger firstOpen = [packageInfoManager queryCountOfPkgInfoWithUniqueID:model.uniqueID readType:BDPPkgFileReadTypeNormal] == 0;
    [self mpReportStart:uniqueID trace:trace schema:schema scene:scene startPagePath:model.start_page_no_query firstOpen:firstOpen];
}
- (void)mpReportStart:(BDPUniqueID *)uniqueID
                trace:(BDPTracing *)trace
               schema:(NSURL *)schema
                scene:(NSInteger)scene
        startPagePath:(NSString *)startPagePath
            firstOpen:(BOOL)firstOpen {
    OPMonitorEvent *event = BDPMonitorWithName(kEventName_mp_app_launch_start, uniqueID).timing();
    event.bdpTracing(trace)
    .kv(kEventKey_scene, @(scene).stringValue)
    .kv(kEventKey_user_id, EMAAppEngine.currentEngine.account.encyptedUserID)
    .kv(kEventKey_tenant_id, EMAAppEngine.currentEngine.account.encyptedTenantID)
    .kv(@"app_launch_time", @((unsigned long long)([EMAAppDelegate appLaunchTime] * 1000)))
    .kv(@"cpu_max", (NSInteger)BDPCPUMonitor.cpuUsage)
    .kv(@"memory_usage", @(BDPMemoryMonitor.currentMemoryUsageInBytes))
    .kv(@"fps_min", @(BDPFPSMonitor.fps))
    .kv(@"schema", schema.absoluteString)
    .kv(@"start_page_path", startPagePath)
    .kv(@"isNewBridge", BDPSDKConfig.sharedConfig.shouldUseNewBridge)
    .kv(@"first_launch", @(firstOpen));
    
    UIViewController *topMostVC = [OPNavigatorHelper topMostVCWithSearchSubViews:NO window:uniqueID.window];
    if (topMostVC) {
        NSString *vcClassName = NSStringFromClass(topMostVC.class);
        event.kv(@"from", vcClassName);
    }
    event.flush();
}

@end

FOUNDATION_EXTERN id<EMAProtocol> _Nullable getEERouteDelegate(void) {
    return [EERoute sharedRoute].delegate;
}
