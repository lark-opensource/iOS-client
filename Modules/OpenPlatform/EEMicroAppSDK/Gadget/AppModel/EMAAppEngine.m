//
//  EMAAppEngine.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/18.
//

#import "EMAAppEngine.h"
#import "EMAAppDelegate.h"
#import "EMALifeCycleManager.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import <ECOProbe/OPMonitorService.h>
#import <ECOProbe/OPMonitorServiceConfig.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPVersionManager.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/BDPJSSDKForceUpdateManager.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <LarkUIKit/LarkUIKit-Swift.h>
#import <ECOInfra/EMAConfigManager.h>
#import <TTMicroApp/BDPMetaTTCodeFactory.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "EMAPreloadManagerImp.h"
#import <OPFoundation/OPFoundation-Swift.h>

@interface EMAAppEngine ()

@property (nonatomic, strong, nullable, readwrite) EMAAppDelegate *appDelegate;
@property (nonatomic, strong, nullable, readwrite) EMAAppEngineAccount *account;
@property (nonatomic, strong, nullable, readwrite) EMAAppEngineConfig *config;
@property (nonatomic, strong, nullable, readwrite) EMALibVersionManager *libVersionManager;
@property (nonatomic, strong, nullable, readwrite) EMAComponentsVersionManager *componentsVersionManager;
@property (nonatomic, strong, nullable, readwrite) OpenPluginCommnentJSManager *commnentVersionManager;
@property (nonatomic, strong, nullable, readwrite) CommonComponentResourceManager *componentResourceManager;
@property (nonatomic, strong, nullable, readwrite) OPPackageSilenceUpdateManager *silenceUpdateManager;
@end

@implementation EMAAppEngine


static EMAAppEngine *appEngine = nil;
+ (instancetype _Nullable)currentEngine {
    return appEngine;
}


+ (id<EMAAppEnginePluginDelegate>)sharedPlugin {
    return [self currentEngine];
}

- (instancetype)initWithAccount:(EMAAppEngineAccount *)account config:(EMAAppEngineConfig *)config
{
    self = [super init];
    if (self) {
        self.account = account;
        self.config = config;
        self.appDelegate = [[EMAAppDelegate alloc] init];
        self.libVersionManager = [[EMALibVersionManager alloc] init];
        self.componentsVersionManager = [[EMAComponentsVersionManager alloc] init];
        _commnentVersionManager = [[OpenPluginCommnentJSManager alloc] init];
        _componentResourceManager = [[CommonComponentResourceManager alloc] init];

        [self observeNotifications];
    }
    return self;
}

- (void)updateLibIfNeedWithConfig:(NSDictionary *)config
{
    [self.libVersionManager updateLibIfNeedWithConfig:config];
}

+ (void)loginWithAccount:(EMAAppEngineAccount *)account config:(EMAAppEngineConfig *)config {
    appEngine = [[EMAAppEngine alloc] initWithAccount:account config:config];
}

- (void)startup {

    // 初始化全局埋点配置
    [self setupMonitorConfig];
    // 注入必需的能力到外部模块中
    [self setupInjection];
    self.configManager.delegate = self.appDelegate;
    // 注入调试小程序配置 目的：在开启vConsole时过滤掉调试小程序，调试小程序不能打开vConsole
    BDPSDKConfig.sharedConfig.debuggerAppID = self.onlineConfig.debuggerAppID;

    BDPMonitorWithName(kEventName_mp_engine_start, nil)
    .bdpTracing(BDPTracingManager.sharedInstance.containerTrace)
    .kv(kEventKey_user_id, self.account.encyptedUserID)
    .kv(kEventKey_tenant_id, self.account.encyptedTenantID)
    .flush();

    // 发起更新配置
    [self.configManager updateConfig];

    // 预安装是否走重构逻辑
    if ([BDPPreloadHelper preloadEnable]) {
        [self fetchPreload];
    } else {
        // 预安装老逻辑会在init方法中去拉取配置
        self.updateManager = [[EMAAppUpdateManagerV2 alloc] init];
    }

    // 预安装重构-拉取过期信息
    if ([BDPPreloadHelper expiredEnable]) {
        [self fetchExpired];
    }

    self.preloadManager = [[EMAPreloadManagerImp alloc] init];
    self.silenceUpdateManager = [[OPPackageSilenceUpdateManager alloc] init];

    [EMALifeCycleManager.sharedInstance addListener:self.appDelegate];

    [self fetchSilenceUpdateInfo];

    // 启动后 n 秒钟之后检查是否已完成基础库预加载，如果没有进行补充预加载
    NSTimeInterval preloadDelayAfterLaunch = [BDPSettingsManager.sharedManager s_floatValueForKey:kBDPSJSLibPreloadDelayAfterLaunchTma];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(preloadDelayAfterLaunch * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // preloadLibIfNeed 中有setting 开关，更新预加载来源前需要先check
        [EMALibVersionManager updatePreloadForPreloadLibIfNeed:@"delay_after_lark_launch"];
        [EMAAppEngine.currentEngine.libVersionManager preloadLibIfNeed];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [BDPPreRunManager.sharedInstance startPreRunMonitor];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [BDPMemoryManager.sharedInstance startCleanMonitor];
    });

    [OPDynamicComponentBridge cleanComponents];
    /// 启动后，注入小程序菜单插件，就近原则注入
    [MenuPluginAssembly injectAppMenuPlugin];
    /// 提前在子线程生成TTCode，避免主线程卡顿产生ANR，分析见：https://bytedance.feishu.cn/docs/doccnHFbcig1yPP5tmP5oS7hc9f#
    [BDPMetaTTCodeFactory generateTTCodeIfNeeded];
}

+ (void)logout {
    BDPMonitorWithName(kEventName_mp_engine_stop, nil)
    .bdpTracing(BDPTracingManager.sharedInstance.containerTrace)
    .flush();

    // 清理所有 tracing
    [BDPTracingManager.sharedInstance clearAllTracing];

    appEngine = nil;
    
    [self clearCommonMonitorConfigWhenLogout];
}

- (void)dealloc
{
    [EMALifeCycleManager.sharedInstance removeListener:self.appDelegate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (EMAConfig *)onlineConfig {
    return [[EMAConfig alloc] initWithECOConfig:self.configManager.minaConfig];
}

- (EMAConfigManager *)configManager {
    return [ECOConfig service];
}

- (void)setupMonitorConfig {
    // 初始化全局埋点配置
    [OPMonitorServiceConfig.globalRemoteConfig buildConfigWithConfig: self.onlineConfig.monitorConfig];
    
    // 初始化全局公共字段
    NSMutableDictionary *commonCategories = OPMonitorService.defaultService.config.commonCatrgories.mutableCopy ?: NSMutableDictionary.dictionary;
    commonCategories[kEventKey_user_id] = appEngine.account.encyptedUserID;
    commonCategories[kEventKey_tenant_id] = appEngine.account.encyptedTenantID;
    [OPMonitorService.defaultService.config setCommonCatrgories:commonCategories.copy];

    commonCategories = GDMonitorService.gadgetMonitorService.config.commonCatrgories.mutableCopy ?: NSMutableDictionary.dictionary;
    commonCategories[kEventKey_user_id] = appEngine.account.encyptedUserID;
    commonCategories[kEventKey_tenant_id] = appEngine.account.encyptedTenantID;
    [GDMonitorService.gadgetMonitorService.config setCommonCatrgories:commonCategories.copy];
}

/// 将EMA中的部分能力注入到外部模块中
- (void)setupInjection {
    // 将获取配置的能力注入到OPSDK中
    [OPSDKConfigInjector inject];
    // 将获取配置的能力注入到OPPerformanceMonitorConfigProvider中
    [OPPerformanceMonitorConfigInjector inject];
    // 注入开放平台内存监控相关配置获取的能力
    [OPMemoryMonitorConfigInjector inject];
    // 注册LeakInfoAllocator: 对象内存泄漏信息收集器
    [OPMemoryInfoAllocatorRegister registerAllocators];
    // 注入TTMicroApp中需要的对象
    [OPTTMicroAppInjector inject];
}

+ (void)clearCommonMonitorConfigWhenLogout {
    NSMutableDictionary *commonCategories = OPMonitorService.defaultService.config.commonCatrgories.mutableCopy ?: NSMutableDictionary.dictionary;
    commonCategories[kEventKey_user_id] = nil;
    commonCategories[kEventKey_tenant_id] = nil;
    [OPMonitorService.defaultService.config setCommonCatrgories:commonCategories.copy];

    commonCategories = GDMonitorService.gadgetMonitorService.config.commonCatrgories.mutableCopy ?: NSMutableDictionary.dictionary;
    commonCategories[kEventKey_user_id] = nil;
    commonCategories[kEventKey_tenant_id] = nil;
    [GDMonitorService.gadgetMonitorService.config setCommonCatrgories:commonCategories.copy];
}

- (void)observeNotifications {
    //UIApplicationWillEnterForegroundNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)applicationWillEnterForeground {
    [self fetchSilenceUpdateInfo];
    [self delayFetchPreUpdateInfo];
    [self deleteOPLaunchInfoTableDBOldData];
}

// 删除OPLaunchInfoTable数据库老数据(支持debug页面中配置时间来验证)
- (void)deleteOPLaunchInfoTableDBOldData {
    if (![BDPPreloadHelper clientStrategyEnable]) {
        return;
    }

    BDPExecuteOnGlobalQueue(^{
        [[LaunchInfoAccessorFactory launchInfoAccessorWithType:OPAppTypeGadget] deleteOldData];
    });
}
static NSString * const kLastFetchPreUpdateInfoTimestamp = @"kLastFetchPreUpdateInfoTimestamp";
// 拉取止血配置
- (void)fetchSilenceUpdateInfo {
    if([OPSDKFeatureGating enablePrehandleOptimizing]) {
        BDPLogInfo(@"enablePrehandleOptimizing on, checking silence pull request");
        TMAKVStorage *storage = [BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager].kvStorage;
        id lastFetchTimestamp = [storage objectForKey:kLastFetchPreUpdateInfoTimestamp];
        //检查上一次进入预安装的时间，如果间隔小于设置的阀值。直接退出
        if(lastFetchTimestamp != nil && [lastFetchTimestamp isKindOfClass:[NSNumber class]] && [lastFetchTimestamp doubleValue]>0){
            NSTimeInterval timepassed = [[NSDate date] timeIntervalSince1970] - [lastFetchTimestamp doubleValue];
            //还在有效时间范围内，直接return
            if(timepassed < [BDPPreloadHelper minPullSilenceInAppFront]) {
                BDPLogWarn(@"delayFetchPreUpdateInfo check still valid, preload pull action shoud stop");
                return;
            }
        }
        //每次执行预安装拉取操作时，更新一下时间戳
        [storage setObject:@([[NSDate date] timeIntervalSince1970]) forKey:kLastFetchPreUpdateInfoTimestamp];
    }
    // 预安装重构-产品化止血
    if ([BDPPreloadHelper silenceEnable]) {
        [self fetchSilence];
        return;
    }

    // 产品化止血老逻辑
    if (self.silenceUpdateManager) {
        [self.silenceUpdateManager fetchSilenceUpdateInfo];
    } else {// 不会发生
        BDPLogError(@"[silenceUpdate] silenceUpdateManager is nil");
    }
}

// 延迟拉取预安装信息(前后台切换)
- (void)delayFetchPreUpdateInfo {
    if (![BDPPreloadHelper preloadEnable]) {
        return;
    }
    NSInteger delaySeconds = [BDPBatchMetaHelperBridge batchMetaDelaySeconds];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * delaySeconds), dispatch_get_global_queue(0, 0), ^{
        [self fetchPreload];
    });
}

// 预安装重构-拉取预安装信息
- (void)fetchPreload {
    [EMAPreloadAPI preloadWithScene:EMAAppPreloadScenePreUpdate appTypes:@[@(OPAppTypeGadget), @(OPAppTypeWebApp)]];
}

// 预安装重构-拉取过期配置信息
- (void)fetchExpired {
    [EMAPreloadAPI preloadWithScene:EMAAppPreloadSceneExpired appTypes:@[@(OPAppTypeGadget)]];
}

// 预安装重构-拉取止血配置信息
- (void)fetchSilence {
    [EMAPreloadAPI preloadWithScene:EMAAppPreloadSceneSilence appTypes:@[@(OPAppTypeGadget), @(OPAppTypeWebApp)]];
}
@end
