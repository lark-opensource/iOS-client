//
//  BDPSettingsKey.h
//  Timor
//
//  Created by 张朝杰 on 2019/7/25.
//

#import "BDPSettingsManager.h"
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

// 基础库更新配置
extern BDPSettingsKey * const kBDPSJSLibVersion;
extern BDPSettingsKey * const kBDPSJSLibUpdateVersion;
extern BDPSettingsKey * const kBDPSJSLibLatestURL;
extern BDPSettingsKey * const kBDPSJSLibTmaSwitch;

// H5 基础库更新配置 - TODO:后续删除,统一到VersionManager
extern BDPSettingsKey * const kBDPSH5JSLibVersion;
extern BDPSettingsKey * const kBDPSH5JSLibUpdateVersion;
extern BDPSettingsKey * const kBDPSH5JSLibLatestURL;
extern BDPSettingsKey * const kBDPSH5JSLibCDNURL;

// 预下载默认模式
extern BDPSettingsKey * const kBDPDefaultPreloadMode;

// 离线包更新配置
extern BDPSettingsKey * const kBDPSOfflineZip;

// 黑名单
extern BDPSettingsKey * const kBDPSBlackListDeviceTma;
extern BDPSettingsKey * const kBDPSBlackListDeviceTmg;

/** CDN预下载请求头要加gzip的域名列表 */
extern BDPSettingsKey * const kBDPCDNHostsAddGzip;

/** 禁用断断续传功能配置*/
extern BDPSettingsKey * const kBDPRangeDownloadDisableList;

/** 小程序Webview加载方式降级开关 */
extern BDPSettingsKey * const kBDPWebViewLoadDowngrade;

// 更多面板
extern BDPSettingsKey * _Nonnull const kBDPMorePanelOn;

// tma&tmg预加载
extern BDPSettingsKey * const kBDPSJSLibPreloadUseManager;
extern BDPSettingsKey * const kBDPSJSLibPreloadDisableTma;
extern BDPSettingsKey * const kBDPSJSLibPreloadOptmizeTma;                 // 使用补充预加载优化
extern BDPSettingsKey * const kBDPSJSLibPreloadRetryCountTma;              // 预加载重试次数
extern BDPSettingsKey * const kBDPSJSLibPreloadTimeoutTma;                 // 预加载超时判定时间
extern BDPSettingsKey * const kBDPSJSLibPreloadDelayAfterLaunchTma;        // 启动后延迟开始预加载的时间

// ABTest 预加载
/// 小程序预加载JSCore & WebViews
extern BDPSettingsKey * const kBDPSABTestAppPreloadDisableTma;

// ABTest
// 授权弹窗
extern BDPSettingsKey * const kBDPSABTestAuthorizeListOn;
extern BDPSettingsKey * const kBDPSABTestAuthorizeListMpid;
extern BDPSettingsKey * const kBDPSABTestAuthorizeListDid;

// app切后台杀掉热缓存
extern BDPSettingsKey * const kBDPSABTestBackGroundKillEnable;
extern BDPSettingsKey * const kBDPSABTestBackGroundAliveTime;

/** SDK/App启动保护策略配置项名称 */
extern BDPSettingsKey *const kBDPSSDKProtectionConfigName;

// Meta
extern BDPSettingsKey * const kBDPSMetaURLs;

// TTPkg
extern BDPSettingsKey * const kBDPSTTPkgCompressDowngrade;
/// pkg预下载缓存数量限制
extern BDPSettingsKey * const kBDPSTTPkgPreloadLimit;
/// pkg使用中的缓存数量限制
extern BDPSettingsKey * const kBDPSTTPkgNormalLimit;

//  复玩
extern BDPSettingsKey * const kBDPSReenterTipsTmaCount;
extern BDPSettingsKey * const kBDPSReenterTipsTmaTitle;
extern BDPSettingsKey * const kBDPSReenterTipsTmaImage;
extern BDPSettingsKey * const kBDPSReenterTipsTmaButtonText;
extern BDPSettingsKey * const kBDPSReenterTipsTmaButtonColor;
extern BDPSettingsKey * const kBDPSReenterTipsTmgCount;
extern BDPSettingsKey * const kBDPSReenterTipsTmgTitle;
extern BDPSettingsKey * const kBDPSReenterTipsTmgImage;
extern BDPSettingsKey * const kBDPSReenterTipsTmgButtonText;
extern BDPSettingsKey * const kBDPSReenterTipsTmgButtonColor;
extern BDPSettingsKey * const kBDPSReenterTipsTmgBlackList;

// 小游戏脱敏开关
extern BDPSettingsKey * const kBDPSABTestTmgStyleDefault;
extern BDPSettingsKey * const kBDPSABTestTmgStyleDefaultAppIDs;
extern BDPSettingsKey * const kBDPSABTestTmgStyleNativeAppIDs;

// 跳端
extern BDPSettingsKey * const kBDPSLaunchAppWiteList;
extern BDPSettingsKey * const kBDPSLaunchAppGrayList;

// 小程序/小游戏入口控制
extern BDPSettingsKey * const kBDPSEntryControlSwitch;
extern BDPSettingsKey * const kBDPSEntryControlWhiteMpIDList;

// UI自动化测试开关
extern BDPSettingsKey * const kBDPUIAutoTestEnable;
// UI自动化测试端口配置
extern BDPSettingsKey * const kBDPUIAutoTestSocketServerPort;

// 预拉取CP数据最大并发数
extern BDPSettingsKey * const kBDPSPrefetchMAXConcurrentRequestCount;
// 包下载完成时，只进行prefetch urls的解析，不预取的App类型
extern BDPSettingsKey * const kBDPSPrefetchAppTypeOnlyDecodeURLs;
// 包下载完成时，prefetch urls的解析并预取的App类型
extern BDPSettingsKey * const kBDPSPrefetchAppTypeDecodeAndPrefetchURLs;
// 数据预取限制
extern BDPSettingsKey * const kBDPSPrefetchAppLimit;

// 白屏检测开关
extern BDPSettingsKey * const kBDPBlankScreenDetectEnable;

// 在线时长上报周期
extern BDPSettingsKey * const kBDPOnlineTimeReportedPeriod;

//包下载完之后到commonready的最长时间，超时会包加载失败,单位：秒,值小于0时为关闭（暂时只有火山有）
extern BDPSettingsKey *const kBDPSABTestLoadMAXTime;

// 小程序启动超时时间(ms)
extern BDPSettingsKey *const kBDPLaunchTimeout;

@interface BDPSettingsManager (BDPExtension)

// 检查是否开启小游戏脱敏样式，由于判断逻辑比较繁琐，故添加在这里
- (BOOL)enableNativeStyleWithUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
