//
//  EMAConfigManager.m
//  EEMicroAppSDK
//
//  Created by 殷源 on 2018/10/22.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "EMAConfigManager.h"
#import "ECOConfig.h"
#import "ECOConfigKeys.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPMacros.h>
#import <ECOInfra/OPMacroUtils.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOProbe/OPMonitor.h>
#import <ECOInfra/BDPLog.h>
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>
#import "EMAFeatureGating.h"

static NSString * const kEEMicroAppCachedConfigID = @"kEEMicroAppCachedConfig";

// 不要删，历史 settings 存储 UserDefault key 使用。
//static NSString * const kEESettingsConfigID = @"kEESettingsConfig";

static ECOSettingsFetchingServicProvider settingsFetchingServicProvider;

@interface EMAConfigManager ()

// 存储 config，config = settings_config
@property (nonatomic, strong, readwrite) ECOConfig *config;

@end

@implementation EMAConfigManager

#pragma mark - EMAConfigManager 接口实现

- (instancetype)init {
    if (self = [super init]) {
        _config = [[ECOConfig alloc] initWithConfigID:kEEMicroAppCachedConfigID];
    }
    return self;
}

- (ECOConfig *)minaConfig {
    return self.config;
}

/// config 更新入口
- (void)updateConfig {
    BDPLogInfo(@"start update config");
    // group：等待 settings 更新完成
    dispatch_group_t configFetchGroup = dispatch_group_create();
    ECOConfigFetchContext *context = [[ECOConfigFetchContext alloc] init];
    [self updateSettingsConfigWithGroup:configFetchGroup context: context];
    WeakSelf;
    dispatch_group_notify(configFetchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // settings 拉取结束
        StrongSelfIfNilReturn;
        OPMonitorEvent *monitor = OPNewMonitorEvent(EPMClientOpenPlatformCommonConfigCode.fetch_config_result).timing();
        if (context.shouldBreakUpdate) {
            monitor
                .setResultTypeFail()
                .addCategoryValue(@"is_settings_nil", @(context.settingsConfig == nil))
                .timing()
                .flush();
            return;
        }
        [self.config updateConfigData:context.settingsConfig];
        if ([self.delegate respondsToSelector:@selector(configDidUpdate:error:)]) {
            [self.delegate configDidUpdate:self.config error: nil];
        }
        monitor.timing().flush();
    });
}

+ (void)setSettingsFetchServiceProviderWith:(ECOSettingsFetchingServicProvider)provider {
    settingsFetchingServicProvider = provider;
}

//直接返回具体的 fetching service 对象
-(nullable ECOSettingsFetchingServicProvider) fetchServiceProvider {
    return settingsFetchingServicProvider;
}

+ (void)registeLegacyKey {
    NSArray *configKeys = @[
        @"ABTestConfig",
        @"apiFeatureWhiteList",
        @"appRouteConfigList",
        @"appWebEnable",
        @"appearanceConfig",
        @"checkDomains",
        @"componentFeatureWhiteList",
        @"cookieUrlBlackList",
        @"cookieUrlWhiteList",
        @"debug",
        @"internalapiWhiteList",
        @"jssdk",
        @"magicConfig",
        @"monitor",
        @"openSchemaWhiteList",
        @"openURLWhiteList",
        @"pList",
        @"setCustomUserAgent",
        @"setStorageLimitCheck",
        @"shareOnlyLinkApps",
        @"ttConfig",
        @"uniqueRequest",
        @"blank_detect",
        @"requestTraceWhiteList",
        @"web_app_api_auth_pass_list",
        @"snapshot_config",
        @"cookieSyncStrategy",
        @"configSchemaParameterLittleAppList",
        @"optrace_batch_config",
        @"universalAPI",
        @"meta_expiration_time_setting",
        @"cellular_can_download_appList",
        @"h5sdk_dynamic_api",
        @"js_worker_component",
        @"use_new_network_api",
        @"openplatform_gadget_preload", // only in settings
        @"bdp_settings_all_in_one", // only in settings
        @"tt_request_header_monitor", // only in settings
        @"opmonitor_heartbeat_conifg", // only in settings
        @"messagecard_style", // only in settings
        @"ecosystem_sandbox_standard_config", // only in settings
        @"op_feedback_config", // only in settings
        @"lark_web_enable_hybrid", // only in settings
        @"ecosystem_pure_color_detect", // only in settings
        @"webapp_auth_strategy", // only in settings
        @"open_split_package_config", // only in settings
        @"ttfile_crypto_config", // only in settings
        @"ecosystem_memory_warning", // only in settings
        @"api_code_release_list", // only in settings
        @"api_crossplatform_refactor", // only in settings
        @"gadget_shortcut_navigatorUrl", // only in settings
        @"op_appreview_config", // only in settings
        @"web_view_safedomain_effective_time", // only in settings
        @"preventAccessClipBoardInBackground", // only in settings
        @"openplatform_js_update",// only in settings code from taofengping
        @"openplatform_bio_auth_config",// only in settings code
        @"web_settings",// only in settings
        @"openplatform_error_page_info",
        @"message_card_action_timeout_ms",
        @"biz_api_blacklist",
        @"blockit_mobile_jssdk",
        @"op_js_worker_config",
        @"dynamic_component_config",
        @"messagecard_p_width_type_config",
        @"gadget_error_page_config",
        @"openplatform_gadget_memory_optimize",
        @"miniprogram_copyable_config", // only in settings
        @"package_prehandle", // only in settings
        @"openplatform_gadget_disable_preload_webviewruntime", // only in settings
        @"openplatform_gadget_prerun",
        @"custom_package_prehandle",
        @"op_degrade_attendance_h5", // only in settings
        @"openplatform_gadget_performance_profile",
        @"miniapp_disaster_recover_config",
        @"miniapp_disaster_recover_feature_switch",
        @"gadget_warm_boot_config",
        @"gadget_webview_scheme_handler_config"
    ];

    // 下线无用config keys
    if (![EMAFeatureGating boolValueForKey:@"lark.open_platform.ecoconfig.offline_useless_config_name"]) {
        configKeys = [configKeys arrayByAddingObjectsFromArray:@[
            @"appcenter2window", // 没拉取到，只有pc
            @"canHideCloseApp", // 没拉取到，没有配置
            @"downloadAppUrlWhiteList", // 没拉取到，只有pc
            @"hubInternalApiWhiteList", // 没拉取到，没有配置
            @"loggerDebug", // 没拉取到，只有android
            @"preRenderApp", // 没拉取到，没有配置
            @"preload", // 没拉取到，没有配置
            @"requestMaxCount", // 没拉取到，没有配置
            @"requestReportDelayTime", // 没拉取到，没有配置
            @"setStorageRecalculate", // 没拉取到，没有配置
            @"webStorageWhiteList", // 没拉取到，只有android
            @"v8portIds", // 没拉取到，没有配置
            @"gadget_fg_config", // 没拉取到，只有android
            @"checkRuntimeAliveConfig", // 没拉取到，只有pc
            @"choose_image_optimize" // 没拉取到，没有配置
        ]];
    }

    [ECOConfigKeys registerConfigKeys: configKeys];
}

#pragma mark - settings config update trace

/// settings 更新入口
/// @param group 用于等待 settings 更新任务结束
/// @param context 用于暂存请求结果
- (void)updateSettingsConfigWithGroup:(dispatch_group_t)group context:(ECOConfigFetchContext *)context {
    dispatch_group_enter(group);
    NSArray *keys = ECOConfigKeys.allRegistedKeys;
    BDPLogInfo(@"start fetch settings config, keys: %@.", keys);
    WeakSelf;
    [settingsFetchingServicProvider() fetchSettingsConfigWithKeys:keys completion:^(NSDictionary<NSString *, NSString *> * _Nonnull resultDic, BOOL success) {
        StrongSelfIfNilReturn;
        context.settingsConfig = resultDic;
        context.shouldBreakUpdate |= !success;
        BDPLogInfo(@"did fetched settings config, settings config count: %@", @(resultDic.count));
        dispatch_group_leave(group);
    }];
}

#pragma mark - ECOConfigService 实现

/// 同步 - 根据 key 获取当前配置数据 Array type
- (nullable NSArray *)getArrayValueForKey:(NSString *)key {
    return [self.config getArrayValueForKey:key];
}

/// 同步 - 根据 key 获取当前配置数据 Dictionary type
- (nullable NSDictionary<NSString *, id> *)getDictionaryValueForKey:(NSString *)key {
    return [self.config getDictionaryValueForKey:key];
}

/// 同步 - 根据 key 获取当前配置数据 String type
- (nullable NSString *)getStringValueForKey:(NSString *)key {
    return [self.config getStringValueForKey:key];
}

/// 同步 - 根据 key 获取当前配置数据 BOOL type
- (BOOL)getBoolValueForKey:(NSString *)key {
    return [self.config getBoolValueForKey:key];
}

/// 同步 - 根据 key 获取当前配置数据 Int type
- (int)getIntValueForKey:(NSString *)key {
    return [self.config getIntValueForKey:key];
}
/// 同步 - 根据 key 获取当前配置数据 double type
- (double)getDoubleValueForKey:(NSString *)key {
    return [self.config getDoubleValueForKey:key];
}

/// 同步 - 根据 key 获取当前配置数据 Dictionary type（最新）
- (nullable NSDictionary<NSString *, id> *)getLatestDictionaryValueForKey:(NSString *)key {
    return [self.config getLatestDictionaryValueForKey:key];
}

/// 同步 - 根据 key 获取当前配置数据 Dictionary type（最新）
- (nullable NSArray *)getLatestArrayValueForKey:(NSString *)key {
    return [self.config getLatestArrayValueForKey:key];
}

@end
