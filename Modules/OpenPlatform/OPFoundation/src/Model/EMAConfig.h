//
//  EMAConfig.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/4/9.
//

#import <Foundation/Foundation.h>
#import "BDPUniqueID.h"
#import "BDPModuleEngineType.h"
NS_ASSUME_NONNULL_BEGIN

@class BDPBlankDetectConfig;
@class OPAPIFeatureConfig;
@class ECOConfig;

/// EMAConfig 即将弃用，将改造为 ECOConfigService (预计4.4)
///
/// 预期的使用方式 r.resovle(ECOConfigService.self)!.getConfigValue(for: key)
///
NS_CLASS_DEPRECATED_IOS(9_0, 10_0, "EMAConfig is deprecated. Please use ECOConfigService.getConfigValue(for:)")
@interface EMAConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithECOConfig:(ECOConfig *)config NS_DESIGNATED_INITIALIZER;

/// 小程序url路由配置
- (NSArray *)appRouteConfigList;

/// 是否开启小程序的调试页面
- (BOOL)isDebug;

/// 判断小程序是否需要灰度
- (BOOL)isMicroAppTestForUniqueID:(BDPUniqueID *)uniqueID;

//判断JSPAI是否在白名单内（新JSAPI注册机制）
-(BOOL)isJSAPIInAllowlist:(NSString *)jsapi;

/// 判断小程序是否需要检验域名白名单
- (BOOL)checkDomainsForUniqueID:(BDPUniqueID *)uniqueID;

// webview的cookie是否清除的域名黑名单
- (NSArray *)cookieUrlsForUniqueID:(BDPUniqueID *)uniqueID;

//是否开启更新小程序弹框逻辑
- (BOOL)updateMineAboutEnable;

/**
 *  检查小程序将要openURL的url是否在域名白名单内
 *  @param url 链接
 *  @param uniqueID uniqueID
 *  @param uniqueID 应用唯一标志，同一个appid可能对应不同的uniqueID
 *  @param interceptForWebView 是不是从webview打开
 *  @param external 是否打开外部app
 *  @return 是否能打开
 */
- (BOOL)isOpeningURLInWhiteList:(NSURL *)url
           uniqueID:(BDPUniqueID *)uniqueID
            interceptForWebView:(BOOL)interceptForWebView
                       external:(BOOL)external;

/**
 * webview同步cookie是否在白名单
 */
- (BOOL)isWebviewSynchronizeCookieInWhiteListOfUniqueID:(BDPUniqueID *)uniqueID;

- (BOOL)isVideoAvoidSameLayerRenderForUniqueID:(BDPUniqueID *)uniqueID;
- (BOOL)isMapUseSameLayerRenderForUniqueID:(BDPUniqueID *)uniqueID;

- (BOOL)isGetSystemInfoHeightInWhiteListOfUniqueID:(BDPUniqueID *)uniqueID;

/// 特定 Api 对指定小程序是否可用
- (BOOL)isApiAvailable:(NSString *)apiName forUniqueID:(BDPUniqueID *)uniqueID;

/// fix bug: 后续删掉
- (BOOL)setStorageLimitCheck;
/// 是否持续定位返回locations数组
- (BOOL)returnLocations;

/// 更新策略参数
- (NSUInteger)maxTimesOneDay;
- (NSTimeInterval)checkDelayAfterNetworkChange;
- (NSTimeInterval)checkDelayAfterLaunch;
- (NSTimeInterval)minTimeSinceLastCheck;
- (NSTimeInterval)minTimeSinceLastUpdate;
- (NSTimeInterval)minTimeSinceLastPullUpdateInfo;
- (NSDictionary *)getPreloadLocationParamsForUniqueID:(BDPUniqueID *)uniqueID;
- (NSDictionary *)getPreloadDNSParamsForUniqueID:(BDPUniqueID *)uniqueID;
- (NSDictionary *)getPreloadConnectedWifiParamsForUniqueID:(BDPUniqueID *)uniqueID;
- (NSTimeInterval)maxLocationCacheTime;

#pragma mark 对不同小程序定制动画时间
/// UI表现配置
- (NSTimeInterval)loadingDismissAnimationDurationForUniqueID:(BDPUniqueID *)uniqueID;
- (NSTimeInterval)loadingDismissScaleAnimationDurationForUniqueID:(BDPUniqueID *)uniqueID;

#pragma mark app切后台杀掉热缓存
// app切后台杀掉热缓存
- (BOOL)killBackgroundAppEnabled;
- (NSTimeInterval)backgroundAppAliveTimeInterval;

#pragma mark 启动埋点灰度
- (BOOL)enableAppLaunchDetailEvent;

#pragma mark Monitor
- (NSDictionary *)monitorConfig;
- (BOOL)networkMonitorEnable;
- (BOOL)shouldMonitorNetworkForUniqueID:(BDPUniqueID *)uniqueID domain:(NSString *)domain;
/// tea 转 slardar 列表s
- (NSArray<NSString *> *)tea2slardarList;

/// 性能埋点监控参数配置
- (NSDictionary *)performanceMonitorConfig;

/// jsRuntime对象超限的最大数量
- (NSUInteger)jsRuntimeOvercountNumber;

/// BDPAppPage对象超限的最大数量
- (NSUInteger)appPageOvercountNumber;

/// BDPTask对象超限的最大数量
- (NSUInteger)taskOvercountNumber;

#pragma mark 引擎开发者高级配置
- (BOOL)isSuperDeveloper;

/// 是否开启新版debugger调试（灰度：用户）
- (BOOL)enableDebugApp;

/// debugger小程序的AppID字符串
- (NSString *)debuggerAppID;

#pragma mark 是否特化分享裸链
- (BOOL)shouldShareOnlyLinkSpeciallyWithUniqueID:(BDPUniqueID *)uniqueID;

#pragma mark webview 白屏监测配置
- (BDPBlankDetectConfig *)getDetectConfig;

#pragma mark 动态启动参数下发相关配置[止血版本]
//{"cli_1232142":"1.3.3":xxxxxx}
- (NSArray *)configSchemeParameterAppList;

#pragma mark H5 应用API授权策略
- (BOOL)shouldAuthForWebAppWithUniqueID:(BDPUniqueID *)uniqueID;

#pragma mark API 全形态适配灰度策略
- (nullable NSDictionary *)apiDispatchConfig;
- (OPAPIFeatureConfig *)apiIDispatchConfig:(nullable NSDictionary *)config forAppType:(OPAppType)appType apiName:(NSString *)apiName;

- (BOOL)wkwebviewInput;

- (NSDictionary *)jssdkConfig;
- (NSDictionary *)blockJSSdkConfig; // block js sdk 配置
- (NSDictionary *)msgCardTemplateConfig; // 消息卡片 jssdk 配置

/// 迁移逻辑，FROM Commit message
/// 注册JSSDK完全预加载优化
- (void)registerBackgroundAppSettings;

/**
 迁移逻辑，FROM Commit message
 feature: [SUITE-3690] 让所有h5链接能跳小程序

 使用配置中心配置小程序路由规则。
 这里增加配置中心配置的缓存配置机制，在配置中心拉取失败时，可以选择使用缓存配置（可选），目前用于小程序路由规则。

 jira: https://jira.bytedance.com/browse/SUITE-3690
 测试用例：https://bytedance.feishu.cn/space/mindnote/bmncnbIzVC82C69BiCQrnn  小程序引擎-框架-小程序路由规则（Lark）
 */
- (void)checkTMASwitch;

/// 迁移逻辑
/// 将 JSSDK 版本、greyHash、下载地址透传至 BDPSDKConfig 内，用于真机调试时的 initWorker
- (void)updateJSSDKConfig;

@end

NS_ASSUME_NONNULL_END
