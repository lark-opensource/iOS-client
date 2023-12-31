//
//  CJPaySettings.m
//  CJPay
//
//  Created by liyu on 2020/3/17.
//

#import "CJPaySettings.h"
#import "CJPaySDKMacro.h"
#import <stdlib.h>

@implementation CJPayBindCardUISettingsModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"isShowIDProfileCard": @"show_id_ocr",
        @"updateMerchantId": @"update_merchant_id",
        @"userInputCacheDuration": @"user_input_cache_duration"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayABSettingsModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"showAccountInsuracne": @"ab_account_insurance.show",
            @"isHiddenDouyinLogo": @"ab_account_insurance.is_no_show_douyin_logo",
            @"darkAccountInsuranceUrl" : @"ab_account_insurance.new_dark_icon",
            @"lightAccountInsuranceUrl": @"ab_account_insurance.new_light_icon",
            @"keyboardDenoiseIconUrl": @"ab_account_insurance.new_keyboard_denoise_icon",
            @"amountKeyboardInsuranceUrl": @"ab_account_insurance.light_amount_keyboard_icon",
            @"amountKeyboardDarkInsuranceUrl": @"ab_account_insurance.dark_amount_keyboard_icon",
            @"brandPromoteModel": @"ab_brand_promotion",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayBrandPromoteModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"showNewLoading": @"show_new_loading",
            @"showNewAlertType" : @"show_new_alert",
            @"halfInputPasswordTitle": @"half_input_password_title",
            @"fullVerifyPasswordTitle": @"full_verify_password_title",
            @"fullSetPasswordTitle": @"full_set_password_title",
            @"fullSetPasswordTitleAgain": @"full_set_password_title_again",
            @"cashierTitle": @"cashier_title",
            @"oneKeyQuickCashierTitle": @"one_key_quick_cashier_title",
            @"addCardTitle": @"add_card_title",
            @"addCardH1Title": @"add_card_h1",
            @"douyinLoadingUrlList": @"douyin_loading_url",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end


@implementation CJPayFalconDefaultConfigModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"enableDefaultConfig": @"falcon_open",
            @"prefixList": @"prefix",
            @"channelList": @"channels",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayFalconHtmlConfigModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"path": @"path",
            @"file": @"file",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end


@implementation CJPayFalconCustomConfigModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"enableCustomConfig": @"custom_open",
            @"interceptHtml": @"intercept_html",
            @"channel": @"channel",
            @"hostList": @"host",
            @"assetPath": @"asset_path",
            @"htmlFileList": @"html_files",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayFalconSettingsModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"enableIntercept": @"offline_open",
            @"falconConfigList": @"falcon_config",
            @"customConfigList": @"custom_config",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayGurdSettingsModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"offlineRollback": @"offline_rollback",
            @"isMergeRequest": @"merge_request",
            @"falconSettings": @"intercept_rules"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayGurdImgModel

+ (JSONKeyMapper *)keyMapper {
    NSString *enableGurdImg = [NSString stringWithFormat:@"enable_%@_img", DW_gecko];
    NSDictionary *dic = @{
            @"enableGurdImg":enableGurdImg,
            @"cdnUrl": @"cdn_url",
            @"iosImgChannelList": @"ios_img_channels"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayFastPayModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"timeOut": @"time_out",
            @"queryMaxTimes": @"query_max_times"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSInteger)maxQueryTimes {
    return self.queryMaxTimes > 0 ? self.queryMaxTimes : 2;
}

@end

@implementation CJPayAccountInsuranceEntrance : JSONModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"showInsuranceEntrance": @"show_insurance_entrance"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayDataSecurity

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"enableDataSecurity": @"enable_data_security",
            @"blurType" : @"blur_type"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}  

@end

@implementation CJPayWebViewCommonConfigModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"intergratedHostReplaceBlockList" : @"integrated_host_replace_block_list",
        @"useIESAuthManager" : @"use_ies_auth",
        @"offlineUseSchemeHandler" : @"offline_use_scheme_handler",
        @"offlineExcludeUrlList" : @"offline_exclude_url_list",
        @"showErrorViewTimeout" : @"show_error_view_timeout",
        @"showErrorViewDomainList" : @"show_error_view_domain_list"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
    
@implementation CJPayLoadingConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"enableHalfLoadingUseWindow" : @"enable_halfloading_use_window",
            @"halfLoadingTimeOut" : @"half_loading_time_out",
            @"superPayLoadingTimeOut" : @"super_pay_loading_time_out",
            @"superPayLoadingQueryInterval" : @"super_pay_loading_query_interval",
            @"superPayLoadingStayTime" : @"super_pay_loading_stay_time",
            @"isEcommerceDouyinLoadingAutoClose": @"is_ecommerce_douyin_loading_auto_close",
            @"loadingTimeOut": @"loading_time_out",
            @"superPayLoadingFailTitle": @"super_pay_loading_fail_title",
            @"superPayLoadingFailSubTitle": @"super_pay_loading_fail_sub_title"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySignPayConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"useNativeSignLogin": @"use_native_sign_login",
        @"useNativeSignAndPay": @"use_native_sign_and_pay",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayIAPConfigModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"useNewIAP": @"use_new_iap",
            @"enableSK2": @"enable_sk2",
            @"enableSK1Observer": @"enable_sk1_observer",
            @"isNeedPendingReturnFail": @"is_need_pending_return_fail",
            @"loadingDescription": @"loading_description",
            @"loadingDescriptionTime":@"loading_description_time"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayAlogReportConfigModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
            @"reportEnable": @"report_enable",
            @"reportTimeInterval": @"report_time_interval",
            @"reportEnableInterval": @"report_enable_interval",
            @"eventWhiteList": @"event_white_list"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayRDOptimizationConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"isPopupVCUseCoordinatorPop": @"is_popup_vc_use_coordinator_pop",
        @"isAddLoadingViewInTopHalfPage": @"is_add_loadingview_in_tophalfpage",
        @"isTransitionUseSnapshot": @"is_transition_use_snapshot",
        @"isDisableMonitorRequestBizResult": @"is_disable_monitor_request_biz_result"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayJHInformationConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"jhMerchantId": @"jh_merchant_id",
        @"jhAppId": @"jh_app_id",
        @"source": @"source",
        @"teaSourceNtv": @"tea_source_ntv",
        @"teaSourceLynx": @"tea_source_lynx"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSString *)jhMerchantId {
    return Check_ValidString(_jhMerchantId) ? _jhMerchantId : @"1200003766";
}

- (NSString *)jhAppId {
    return Check_ValidString(_jhAppId) ? _jhAppId : @"800037665481";
}

- (NSString *)source {
    return Check_ValidString(_source) ? _source : @"wallet_bcard_manage_add";
}

@end

@implementation CJPayStyleLoadingConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"dialogPreGif" : @"dialog_pre_gif",
        @"dialogRepeatGif" : @"dialog_repeat_gif",
        @"dialogCompleteSuccessGif" : @"dialog_complete_success_gif",
        @"panelPreGif" : @"panel_pre_gif",
        @"panelRepeatGif" : @"panel_repeat_gif",
        @"panelCompleteSuccessGif" : @"panel_complete_success_gif",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySecurityLoadingConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"cycleStyleLoadingConfig" : @"cycle",
        @"breatheStyleLoadingConfig" : @"breathe",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayMigrateH5PageToLynx : JSONModel

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"forgetpassSchema" : @"forgetpass_schema",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayLynxSchemaConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"myBankCard" : @"my_bank_card",
        @"retainPopup" : @"retain_popup",
        @"keepDialogStandardNew": @"keep_dialog_standard_new",
        @"loginInfo" : @"login_info",
        @"payUpgradeSchema": @"pay_upgrade_schema"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayKeepDialogStandard

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"scheme": @"scheme",
        @"fallbackWaitTimeMillis": @"fallback_wait_time_millis",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayContainerConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dic = @{
        @"enable" : @"enable",
        @"disableAlog" : @"disable_alog",
        @"colorDiff" : @"color_diff",
        @"disableBlankDetect" : @"disable_blank_detect",
        @"urlBlockList" : @"url_prefix_block_list",
        @"enableHybridkitUA" : @"enable_hybridkit_ua",
        @"cjwebEnable" : @"cjweb_hybrid_enable",
        @"cjwebUrlBlockList" : @"cjweb_hybrid_url_block_list",
        @"cjwebUrlAllowList" : @"cjweb_hybrid_url_allow_list"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSInteger)colorDiff {
    return _colorDiff > 0 ? _colorDiff : 75;
}

@end

@implementation CJPayUploadMediaConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dict = @{
        @"defaultMaxSize" : @"default_max_size",
        @"defaultMaxResolution" : @"default_max_resolution",
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayNativeBindCardConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dict = @{
        @"enableNativeBindCard" : @"enable_native_bind_card"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayLynxSchemaParamsRule

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dict = @{
        @"url" : @"url",
        @"keys" : @"ab_test"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayLynxSchemaParamsConfig

+ (JSONKeyMapper *)keyMapper {
    NSDictionary *dict = @{
        @"enable" : @"enable",
        @"paramsLimit" : @"ttpay_schema_params_limit",
        @"rules" : @"ttpay_schema_params"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end


@implementation CJPaySettings

+ (JSONKeyMapper *)keyMapper {
    NSString *cjpayGurdSettings = [NSString stringWithFormat:@"cjpay_%@_settings", DW_gecko];//cjpay_gecko_settings
    NSDictionary *dic = @{
            @"degradeModels": @"cjpay_degrade",
            @"themeModelDic": @"new_cjpay_theme_info",
            @"forceHttpsModel": @"cjpay_force_https_model",
            @"webviewMonitorConfigModel": @"cjpay_webview_monitor",
            @"secDomains": @"cjpay_sec_domain",
            @"loadingPath": @"cjpay_loading_path",
            @"webviewPrefetchConfig" : @"webview_prefetch_config",
            @"cjpayNewCustomHost": @"new_cjpay_host_domain",
            @"cjpayCustomHost": @"cjpay_host_domain",
            @"abSettingsModel": @"ab_settings",
            @"abSettingsDic": @"ab_settings",
            @"libraABSettingsDic": @"ab_settings_libra",
            @"gurdFalconModel": cjpayGurdSettings,
            @"fastPayModel": @"fast_pay",
            @"gurdImgModel": @"cjpay_img_settings",
            @"accountInsuranceEntrance": @"cjpay_account_insurance_entrance",
            @"bankParamsArray" : @"cjpay_bank_appparam",
            @"enableDataSecurity" : @"cjpay_data_security",
            @"performanceMonitorIsOpened" : @"event_upload_rules.is_opened",
            @"isHitEventUploadSampled" : @"event_upload_rules.is_hit_event_upload_sampled",
            @"webviewCommonConfigModel": @"webview_common_config",
            @"loadingConfig": @"cjpay_loading_config",
            @"signPayConfig": @"sign_and_pay_config",
            @"aid2PlatformIdMap" : @"cjpay_aid2PlatformIdMap",
            @"iapConfigModel" : @"cjpay_iap_config",
            @"jhConfig": @"cjpay_bindcard_jh_information",
            @"engimaVersion": @"engima_config.use_version",
            @"oneKeyAssemble": @"engima_config.one_key_assemble",
            @"disableViolentClickPrevent": @"disable_violent_click_prevent",
            @"rdOptimizationConfig" : @"cjpay_optimization_config",
            @"topVCV2" : @"topvc_config.use_v2",
            @"bindCardUISettings" : @"bind_card_ui_config",
            @"rechargeWithdrawConfig" : @"cjpay_balance_recharge_or_withdraw_config",
            @"securityLoadingConfig" : @"cjpay_security_loading_config.experiment",
            @"bindcardLynxUrl" : @"cjpay_lynx_bindcard_url",
            @"migrateH5PageToLynx" : @"migrate_h5_page_to_lynx",
            @"alogReportConfigModel" : @"alog_report_config",
            @"isVIP" : @"vip_tag.is_vip",
            @"lynxSchemaConfig" : @"lynx_schema_config",
            @"redpackBackgroundURL" : @"cjpay_get_redpack_background",
            @"nativeBindCardConfig" : @"native_bind_card_config",
            @"containerConfig" : @"new_container_config",
            @"uploadMediaConfig" : @"cjpay_upload_media_config",
            @"lynxSchemaParamsConfig" : @"lynx_schema_params_config"
    };
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (NSArray<NSString *> *)getThemedH5PathList {
    NSArray *h5ThemePathList = [self.themeModelDic cj_arrayValueForKey:@"is_support_multiple_h5_path"];
    return h5ThemePathList ?: [NSArray new];
}

@end
