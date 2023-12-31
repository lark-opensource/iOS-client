//
//  BDPTimorClient+Business.m
//  TTMicroApp
//
//  Created by justin on 2022/12/17.
//

#import "BDPTimorClient+Business.h"
#import "BDPAppContainerController.h"
#import "BDPAppLoadManager+Clean.h"
#import "BDPAppLoadManager+Launch.h"
#import "BDPAppPageFactory.h"
#import <OPFoundation/BDPAppearanceConfiguration+Private.h>
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/BDPBootstrapKit.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPI18n.h>
#import "BDPJSRuntimePreloadManager.h"
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPNetworkManager.h>
#import <OPFoundation/BDPNetworkOperation.h>
#import <OPFoundation/BDPNetworking.h>
#import "BDPOfflineZipManager.h"
#import "BDPPresentAnimation.h"
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPRootNavigationController.h"
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPSchemaCodec+Private.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPStorageManager.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPTask.h"
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient+Private.h>
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPVersionManager.h>
#import "BDPWarmBootManager.h"
#import "BDPDeprecateUtils.h"
#import <OPFoundation/NSUUID+BDPExtension.h>
#import "BDPEngineAssembly.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <LKLoadable/Loadable.h>
#import "BDPJSRuntime.h"

LoadableMainFuncBegin(BDPTimorClientUpdateRelativeDataMain)
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    BDPTimorClient *client = [BDPTimorClient sharedClient];
    BOOL enableOptimize = [BDPTimorClient enableOptimizeUpdateRelativeData];
    if ([[client globalConfiguration] shouldAutoUpdateRelativeData] && !enableOptimize) {
        [client updateRelativeDataIfNeed];
    }
});
LoadableMainFuncEnd(BDPTimorClientUpdateRelativeDataMain)


@implementation BDPTimorClient (Business)

- (void)clearAllWarmBootCache { // 以下调用有顺序要求
    // 小程序所有热启动缓存
    [[BDPWarmBootManager sharedManager] clearAllWarmBootCache];
    // meta请求、下载任务、文件管理实例等先清理掉
    [[BDPAppLoadManager shareService] releaseMemoryCache];
    // 用于退出登陆时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
    [BDPStorageManager clearSharedManager];
    [BDPEngineAssembly clearAllSharedLocalFileManagers];
}

- (void)clearAllUserCache {
    [self clearAllWarmBootCache];
    [[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] cleanAllUserCacheExceptIdentifiers:nil];
}


@end


#pragma mark - Launcher
/*-----------------------------------------------*/
//              Launcher - 启动方法
/*-----------------------------------------------*/
@implementation BDPTimorClient (Launcher)

- (BOOL)openWithURL:(NSURL *)url openType:(BDPViewControllerOpenType)openType window:(UIWindow *)window
{
    return NO;
}

- (BOOL)openWithURL:(NSURL *)url userInfo:(NSDictionary *)userInfo openType:(BDPViewControllerOpenType)openType window:(UIWindow *)window
{
    return NO;
}

- (BOOL)openWithLaunchParam:(BDPTimorLaunchParam *)launchParam openType:(BDPViewControllerOpenType)openType window:(UIWindow *)window
{
    return NO;
}

- (UIViewController *)containerControllerWithLaunchParam:(BDPTimorLaunchParam *)launchParam window:(UIWindow *)window {
    return nil;
}

- (UIViewController *)containerControllerWithLaunchParam:(BDPTimorLaunchParam *)launchParam isExistedAndTopmost:(BOOL *)isExistedAndTopmost window:(UIWindow *)window
{
    return nil;
}

- (UIViewController *)containerControllerWithURL:(NSURL * _Nonnull)url window:(UIWindow *)window
{
    return nil;
}

- (void)moveAppFolderIfNeededWithUniqueID:(BDPUniqueID *)uniqueID {
}

- (void)setupBeforeLaunch:(OPAppUniqueID *)uniqueID {
    // 小程序appid目录迁移
    [self moveAppFolderIfNeededWithUniqueID:uniqueID];
    // 创建小程序/小游戏实例
    [self.appearanceConfiguration bdp_apply];
    
    // 注册所有的plugin(防止优化load方法后,plugin注册过晚导致问题)
    [BDPBootstrapKit launch];
    
    // 尝试设置默认jssdk
    [BDPVersionManager setupDefaultVersionIfNeed];
    
    // 网络连接性监控
    [BDPNetworking startReachabilityChangedNotifier];
    
    [self updateRelativeDataIfNeed];
    // 生成性能监控生命周期id
    [[BDPTracker sharedInstance] generateLifecycleIdIfNeededForUniqueId:uniqueID];
}

@end

#pragma mark - Preload
/*-----------------------------------------------*/
//              Preload - 预下载方法
/*-----------------------------------------------*/
@implementation BDPTimorClient (Preload)

+ (void)updatePreloadFrom:(NSString * _Nonnull)preloadFrom {
    [[BDPJSRuntimePreloadManager sharedManager] updatePreloadFrom:preloadFrom];
    [[BDPAppPageFactory sharedManager] updatePreloadFrom:preloadFrom];
}

+ (void)updatePreloadFromForPrepareTimor:(NSString * _Nonnull)preloadFrom {
    // prepareTimor 会先调用releasePreloadRuntimeIfNeed 导致先释放后预加载，需先更新释放原因
    [[BDPJSRuntimePreloadManager sharedManager] updateReleaseReason:preloadFrom];

    // 与prepareTimor 中判断逻辑保持一致
    if ([BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSABTestAppPreloadDisableTma]) {
        return;
    }
    [self updatePreloadFrom:preloadFrom];
}

- (void)prepareTimor
{
    //2019-8-25 这里只释放已经预创建的JSC,JSC的预创建时机挪到预下载接口调用时.
    [[BDPJSRuntimePreloadManager sharedManager] releasePreloadRuntimeIfNeed:BDPTypeNativeApp];

    if ([BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSABTestAppPreloadDisableTma]) {
        return;
    }

    [[BDPAppPageFactory sharedManager] reloadPreloadedAppPage];
    // 3.19版本合码之后，恢复老版本的JSCore预加载策略
    [[BDPJSRuntimePreloadManager sharedManager] setShouldPreloadRuntimeApp:YES];
    [[BDPJSRuntimePreloadManager sharedManager] preloadRuntimeIfNeed:BDPTypeNativeApp];
}

@end

#pragma mark - RuntimeEnvironment
/*-----------------------------------------------*/
//     RuntimeEnvironment - 运行环境相关方法
/*-----------------------------------------------*/
@implementation BDPTimorClient (RuntimeEnvironment)

+ (BOOL)enableOptimizeUpdateRelativeData {
    static dispatch_once_t onceToken;
    static BOOL enableOptimize = NO;
    dispatch_once(&onceToken, ^{
        enableOptimize = [[NSUserDefaults standardUserDefaults] boolForKey:@"kTimorEnableOptimizeRelativeDataUpdate"];
    });
    return  enableOptimize;
}

+ (void)setOptimizeRelativeDataUpdate:(BOOL)enableOptimize {
    [[NSUserDefaults standardUserDefaults] setBool:enableOptimize forKey:@"kTimorEnableOptimizeRelativeDataUpdate"];
}

- (void)updateRelativeDataIfNeed
{
    // 执行一次相关数据更新及预加载
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDPSettingsManager.sharedManager updateSettingsIfNeed:^(NSError * _Nonnull error) {
        }];
        [BDPSettingsManager.sharedManager setupObserver];
        [BDPOfflineZipManager updateOfflineZipIfNeed];
    });
}

- (void)updateServerConfiguration
{
    [BDPSettingsManager.sharedManager updateSettingsByForce:nil];
}

- (void)enableJSThreadCrashProtection:(BOOL)enabled
{
    BOOL hasEnabled = [OPMicroAppJSRuntime isJSContextThreadProtectionEnabled];
    if (enabled != hasEnabled) {
        [OPMicroAppJSRuntime enableJSContextThreadProtection:enabled];
        
        //2019-8-25 这里只释放已经预创建的JSC,JSC的预创建时机挪到预下载接口调用时.
        [[BDPJSRuntimePreloadManager sharedManager] updateReleaseReason:@"jsthread_crash_protect"];
        [[BDPJSRuntimePreloadManager sharedManager] releasePreloadRuntimeIfNeed:BDPTypeNativeApp];
    }
}

- (void)setJSThreadCrashHandler:(BDPJSThreadCrashHandler)handler
{
    [OPMicroAppJSRuntime setJSThreadCrashHandler:handler];
}

//- (BDPRuntimeGlobalConfiguration *)currentNativeGlobalConfiguration
//{
//    return self.globalConfiguration;
//}

@end
