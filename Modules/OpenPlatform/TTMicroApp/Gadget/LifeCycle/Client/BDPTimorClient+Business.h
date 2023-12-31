//
//  BDPTimorClient+Business.h
//  TTMicroApp
//
//  Created by justin on 2022/12/17.
//

#import <OPFoundation/BDPTimorClient.h>
#import "BDPAppPreloadInfo.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import "BDPTimorLaunchParam.h"
#import <OPJSEngine/BDPJSRunningThread.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Client
/*-----------------------------------------------*/
//             Client - 小程序客户端
// SDK调用入口，根据schema创建BDPAppContainerController做小程序的UI容器。
/*-----------------------------------------------*/
@interface BDPTimorClient (Business)

/** 清理所有热缓存数据(小程序实例、数据库实例、下载/请求任务等) */
- (void)clearAllWarmBootCache;
/// 清理用户缓存
- (void)clearAllUserCache;

@end


#pragma mark - Launcher
/*-----------------------------------------------*/
//              Launcher - 启动方法
/*-----------------------------------------------*/
@interface BDPTimorClient (Launcher)

/**
 @brief         打开小程序(自定义打开方式Push/Present)
 @param         url 小程序Schema，格式：https://docs.bytedance.net/doc/WdnntDW5e5WKhQVyCB75zh
 @param         openType 打开方式(Push/Present)
 */
- (BOOL)openWithURL:(NSURL *)url openType:(BDPViewControllerOpenType)openType window:(UIWindow *)window;

/**
@brief         打开小程序(自定义打开方式Push/Present)
@param         url 小程序Schema，格式：https://docs.bytedance.net/doc/WdnntDW5e5WKhQVyCB75zh
@brief         携带的额外参数
@param         openType 打开方式(Push/Present)
*/
- (BOOL)openWithURL:(NSURL *)url userInfo:(NSDictionary *)userInfo openType:(BDPViewControllerOpenType)openType window:(UIWindow *)window;

/// 通过LaunchParam打开小程序
/// @param launchParam 启动参数 @see BDPTimorLaunchParam
/// @param openType 打开方式(Push/Present)
- (BOOL)openWithLaunchParam:(BDPTimorLaunchParam *)launchParam openType:(BDPViewControllerOpenType)openType window:(UIWindow *)window;

/// 新建小程序vc
/// @param url 小程序Schema，格式：https://docs.bytedance.net/doc/WdnntDW5e5WKhQVyCB75zh
- (UIViewController *)containerControllerWithURL:(NSURL * _Nonnull)url window:(UIWindow *)window;

/// 新建小程序vc
/// @param launchParam  小程序的启动参数
- (UIViewController *)containerControllerWithLaunchParam:(BDPTimorLaunchParam *)launchParam window:(UIWindow *)window;

/// 小程序冷热启动之前需要执行一些特殊操作
- (void)setupBeforeLaunch:(OPAppUniqueID *)uniqueID;

@end


#pragma mark - 预处理Api
@interface BDPTimorClient (Preload)

/// Timor 的一些准备工作，比如预加载小程序的jsc环境，
/// 你可以不调用，如果调用了加快小程序的启动速度。 可以重复调用。
- (void)prepareTimor;

/// 更新预加载来源信息
/// @param preloadFrom 预加载来源
+ (void)updatePreloadFrom:(NSString * _Nonnull)preloadFrom;

/// 调用prepareTimor 方法时，判断是否需要更新预加载来源
/// 由于prepareTimor 方法中有setting：kBDPSABTestAppPreloadDisableTma开关，更新前需要先check
/// @param preloadFrom 预加载来源
+ (void)updatePreloadFromForPrepareTimor:(NSString * _Nonnull)preloadFrom;

@end


#pragma mark - RuntimeEnvironment
/*-----------------------------------------------*/
//     RuntimeEnvironment - 运行环境相关方法
/*-----------------------------------------------*/
@interface BDPTimorClient (RuntimeEnvironment)


/// 飞书冷启动时 执行LoadableMainFuncBegin逻辑时，是否需要关闭`updateRelativeDataIfNeed`的调用
+ (BOOL)enableOptimizeUpdateRelativeData;

/// 更新本地缓存中 “kTimorGadgetCloseRelativeDataUpdate”中的值，记录是否需要关闭；FG取值过早可能会崩溃
/// @param enableOptimize 需要关闭值YES， 默认是NO
+ (void)setOptimizeRelativeDataUpdate:(BOOL)enableOptimize;

//@property (nonatomic, strong, readonly) BDPRuntimeGlobalConfiguration *currentNativeGlobalConfiguration;

/**
@brief         更新启动相关数据(基础库、Settings配置、离线包数据、预连接等)
*/
- (void)updateRelativeDataIfNeed;

/**
 @brief         更新服务端参数配置(包含机型黑名单等)
 */
- (void)updateServerConfiguration;

/**
 @brief         是否开启jsc线程的crash兜底保护，默认开启：推荐debug模式下关闭、release模式下开启，由于debug模式下EXC_BREAKPOINT也会触发保护，导致小程序无法正常调试，请在使用时根据DEBUG宏来关闭。
 */
- (void)enableJSThreadCrashProtection:(BOOL)enabled;

// 2019-5-24 为了解除BDPJSContext类对heimdallr的依赖,使用外部传入handler的方式实现(BDPExceptionMonitor中会在load的时候通过该方法向BDPJSContext传入handler)
// 目前作为单独头文件，是为了不让宿主引入过多的头文件，同时作为私有方法不建议对外暴露使用！
- (void)setJSThreadCrashHandler:(BDPJSThreadCrashHandler)handler;

@end

NS_ASSUME_NONNULL_END

