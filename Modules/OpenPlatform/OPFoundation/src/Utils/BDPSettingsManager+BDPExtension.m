//
//  BDPSettingsKey.m
//  Timor
//
//  Created by 张朝杰 on 2019/7/25.
//

#import "BDPSettingsManager+BDPExtension.h"
#import "BDPI18n.h"
#import "BDPUniqueID.h"

// 基础库更新配置
BDPSettingsKey * const kBDPSJSLibVersion                        = @"tt_tma_sdk_config.sdkVersion";
BDPSettingsKey * const kBDPSJSLibUpdateVersion                  = @"tt_tma_sdk_config.sdkUpdateVersion";
BDPSettingsKey * const kBDPSJSLibLatestURL                      = @"tt_tma_sdk_config.latestSDKUrl";
BDPSettingsKey * const kBDPSJSLibTmaSwitch                      = @"tt_tma_sdk_config.tmaSwitch";

// H5 基础库更新配置 - TODO:后续删除,统一到VersionManager
BDPSettingsKey * const kBDPSH5JSLibVersion                      = @"tt_tma_h5_sdk_config.sdkVersion";
BDPSettingsKey * const kBDPSH5JSLibUpdateVersion                = @"tt_tma_h5_sdk_config.sdkUpdateVersion";
BDPSettingsKey * const kBDPSH5JSLibLatestURL                    = @"tt_tma_h5_sdk_config.latestSDKUrl";
BDPSettingsKey * const kBDPSH5JSLibCDNURL                       = @"tt_tma_h5_sdk_config.latestCDNUrl";

BDPSettingsKey * const kBDPDefaultPreloadMode                   = @"bdp_ttpkg_config.preload_mode";

// 离线包更新配置
BDPSettingsKey * const kBDPSOfflineZip                          = @"bdp_offline_zip";

// 黑名单
BDPSettingsKey * const kBDPSBlackListDeviceTma                  = @"tt_tma_blacklist.device.tma";
BDPSettingsKey * const kBDPSBlackListDeviceTmg                  = @"tt_tma_blacklist.device.tmg";

BDPSettingsKey * const kBDPCDNHostsAddGzip                      = @"bdp_ttpkg_config.hosts_add_gzip";

/** 禁用断断续传功能配置*/
BDPSettingsKey * const kBDPRangeDownloadDisableList           = @"bdp_range_download_disable_list";

BDPSettingsKey * const kBDPWebViewLoadDowngrade                 = @"tt_tma_switch.webviewStreamDowngrade";

// 更多面板
BDPSettingsKey * const kBDPMorePanelOn                          = @"tt_tma_switch.morePanel";

// tma&tmg预加载
BDPSettingsKey * const kBDPSJSLibPreloadUseManager              = @"bdp_jssdk_preload.useManager";
BDPSettingsKey * const kBDPSJSLibPreloadDisableTma              = @"bdp_jssdk_preload.disable.tma";
BDPSettingsKey * const kBDPSJSLibPreloadOptmizeTma              = @"bdp_jssdk_preload.optmize.tma";
BDPSettingsKey * const kBDPSJSLibPreloadRetryCountTma           = @"bdp_jssdk_preload.retry_count.tma";
BDPSettingsKey * const kBDPSJSLibPreloadTimeoutTma              = @"bdp_jssdk_preload.timeout.tma";
BDPSettingsKey * const kBDPSJSLibPreloadDelayAfterLaunchTma     = @"bdp_jssdk_preload.delay_after_launch.tma";      

// ABTest 预加载
/// 小程序预加载JSCore & WebView
BDPSettingsKey * const kBDPSABTestAppPreloadDisableTma          = @"tt_tma_abtest.appPreload.disable.tma";

// ABTest 授权弹窗
BDPSettingsKey * const kBDPSABTestAuthorizeListOn               = @"tt_tma_abtest.authorize_list.on";
BDPSettingsKey * const kBDPSABTestAuthorizeListMpid             = @"tt_tma_abtest.authorize_list.mpid";
BDPSettingsKey * const kBDPSABTestAuthorizeListDid              = @"tt_tma_abtest.authorize_list.did";

// app切后台杀掉热缓存
BDPSettingsKey * const kBDPSABTestBackGroundKillEnable          = @"tt_tma_abtest.backGroundKillConfig.enable";
BDPSettingsKey * const kBDPSABTestBackGroundAliveTime           = @"tt_tma_abtest.backGroundKillConfig.aliveTime";

BDPSettingsKey *const kBDPSSDKProtectionConfigName              = @"tt_sdk_protection";

// Meta
BDPSettingsKey * const kBDPSMetaURLs                            = @"bdp_meta_config.urls";

// TTPkg
/// 1 - 不使用br等压缩下载
BDPSettingsKey * const kBDPSTTPkgCompressDowngrade              = @"bdp_ttpkg_config.compress_downgrade";
BDPSettingsKey * const kBDPSTTPkgPreloadLimit                   = @"bdp_ttpkg_config.predownload_pkg_limit";
BDPSettingsKey * const kBDPSTTPkgNormalLimit                    = @"bdp_ttpkg_config.normal_launch_pkg_limit";

//  复玩
BDPSettingsKey * const kBDPSReenterTipsTmaCount                 = @"bdp_reenter_tips.tma.count";
BDPSettingsKey * const kBDPSReenterTipsTmaTitle                 = @"bdp_reenter_tips.tma.title";
BDPSettingsKey * const kBDPSReenterTipsTmaImage                 = @"bdp_reenter_tips.tma.image";
BDPSettingsKey * const kBDPSReenterTipsTmaButtonText            = @"bdp_reenter_tips.tma.buttonText";
BDPSettingsKey * const kBDPSReenterTipsTmaButtonColor           = @"bdp_reenter_tips.tma.buttonColor";
BDPSettingsKey * const kBDPSReenterTipsTmgCount                 = @"bdp_reenter_tips.tmg.count";
BDPSettingsKey * const kBDPSReenterTipsTmgTitle                 = @"bdp_reenter_tips.tmg.title";
BDPSettingsKey * const kBDPSReenterTipsTmgImage                 = @"bdp_reenter_tips.tmg.image";
BDPSettingsKey * const kBDPSReenterTipsTmgButtonText            = @"bdp_reenter_tips.tmg.buttonText";
BDPSettingsKey * const kBDPSReenterTipsTmgButtonColor           = @"bdp_reenter_tips.tmg.buttonColor";
BDPSettingsKey * const kBDPSReenterTipsTmgBlackList             = @"bdp_reenter_tips.tmg.blackList";

// 小游戏脱敏开关
BDPSettingsKey * const kBDPSABTestTmgStyleDefault               = @"tt_tma_abtest.tmgStyle.default";
BDPSettingsKey * const kBDPSABTestTmgStyleDefaultAppIDs         = @"tt_tma_abtest.tmgStyle.defaultStyle";
BDPSettingsKey * const kBDPSABTestTmgStyleNativeAppIDs          = @"tt_tma_abtest.tmgStyle.nativeStyle";

// 跳端
BDPSettingsKey * const kBDPSLaunchAppWiteList                   = @"bdp_launch_app_scene_list.white_list";
BDPSettingsKey * const kBDPSLaunchAppGrayList                   = @"bdp_launch_app_scene_list.gray_list";

// 小程序/小游戏入口控制
BDPSettingsKey * const kBDPSEntryControlSwitch                  = @"bdp_audit_ios.entry_control.switch";
BDPSettingsKey * const kBDPSEntryControlWhiteMpIDList           = @"bdp_audit_ios.entry_control.white_mpid_list";

// UI自动化测试开关
BDPSettingsKey * const kBDPUIAutoTestEnable                     = @"bdp_uiautotest_config.ui_auto_test_enable";
BDPSettingsKey * const kBDPUIAutoTestSocketServerPort           = @"bdp_uiautotest_config.socket_server_port";

// 数据预取配置
BDPSettingsKey * const kBDPSPrefetchMAXConcurrentRequestCount   = @"bdp_startpage_prefetch.max_concurrent_count";
BDPSettingsKey * const kBDPSPrefetchAppTypeOnlyDecodeURLs       = @"bdp_startpage_prefetch.apptype_only_decode_urls";
BDPSettingsKey * const kBDPSPrefetchAppTypeDecodeAndPrefetchURLs= @"bdp_startpage_prefetch.apptype_decode_and_prefetch_urls";
BDPSettingsKey * const kBDPSPrefetchAppLimit                    = @"bdp_startpage_prefetch.app_prefetch_limit";

// 白屏检测开关
BDPSettingsKey * const kBDPBlankScreenDetectEnable              = @"tt_tma_switch.bdp_blank_screen_detect_enable";

// 在线时长上报周期
BDPSettingsKey * const kBDPOnlineTimeReportedPeriod             = @"bdp_anti_addiction.task_polling_period";

//包下载完之后到commonready的最长时间，超时会包加载失败,单位：秒,值小于0时为关闭（暂时只有火山有）
BDPSettingsKey *const kBDPSABTestLoadMAXTime                   = @"tt_tma_abtest.load_maxtime";

// 小程序启动超时时间(ms)
BDPSettingsKey *const kBDPLaunchTimeout                        = @"bdp_launch.launch_timeout";

@implementation BDPSettingsManager (BDPExtension)

// 该方法命名务必与BDPSettingsManager中反射的命名一致, 要改两处一起改
+ (NSDictionary *)defaultSettings {
    // 默认配置, 请在该方法中补充
    return @{
        kBDPSBlackListDeviceTma: @(0),
        kBDPSBlackListDeviceTmg: @(0),
        kBDPMorePanelOn: @(1),
        kBDPSJSLibPreloadUseManager: @(0),
        kBDPSJSLibPreloadDisableTma: @(0),
        kBDPSJSLibPreloadOptmizeTma: @(0),
        kBDPSJSLibPreloadRetryCountTma: @(3),
        kBDPSJSLibPreloadDelayAfterLaunchTma: @(5),
        kBDPSJSLibPreloadTimeoutTma: @(20),
        kBDPSABTestAppPreloadDisableTma: @(0),
        kBDPWebViewLoadDowngrade: @1,
        kBDPSABTestBackGroundKillEnable: @(0),
        kBDPSReenterTipsTmaCount: @(0),
        kBDPSReenterTipsTmgCount: @(0),
        kBDPSABTestAuthorizeListOn: @(1),
        kBDPSPrefetchMAXConcurrentRequestCount: @(1),
        kBDPSABTestTmgStyleDefault : @"defaultStyle",
        kBDPSABTestTmgStyleNativeAppIDs: @[@"tt645512e8fb7fe9b8"],
        kBDPUIAutoTestEnable: @(0),
        kBDPBlankScreenDetectEnable: @(0),
        kBDPSEntryControlSwitch: @(0),    /* ----  小程序/小游戏入口控制开关  ---- */
        kBDPSEntryControlWhiteMpIDList: @[/* ---- 小程序/小游戏入口控制白名单 ---- */
                @"tt98fcee4107d61094",    // 眼睛眨眨
                @"ttfd2b8b96620145b3",    // 音跃球球
                @"tt2bdc5d61b4f69b9e",    // 西瓜视频
                @"tt977ee1c308541d59",    // 游戏达人推广
                @"ttacffda4233d51d45"],    // 抖音小游戏
        kBDPSTTPkgCompressDowngrade: @(1),
        kBDPOnlineTimeReportedPeriod: @(30),
        kBDPLaunchTimeout: @(15*1000)
    };
}

- (BOOL)enableNativeStyleWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return NO;
    }
    // 优先判断是否采用脱敏样式
    NSArray *nativeStyleAppIDList = [self s_arrayValueForKey:kBDPSABTestTmgStyleNativeAppIDs];
    if ([nativeStyleAppIDList containsObject:uniqueID.appID]) {
        return YES;
    }
    // 判断是否采用默认样式
    NSArray *defaultStyleAppIDList = [self s_arrayValueForKey:kBDPSABTestTmgStyleDefaultAppIDs];
    if ([defaultStyleAppIDList containsObject:uniqueID.appID]) {
        return NO;
    }
    // 采用默认值
    NSString *defaultValue = [self s_stringValueForKey:kBDPSABTestTmgStyleDefault];
    return [defaultValue isEqualToString:@"nativeStyle"];
}

@end
