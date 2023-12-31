//
//  FeatureSwitchKey.swift
//  AppContainer
//
//  Created by kongkaikai on 2020/1/9.
//

import Foundation

extension FeatureSwitch {
    /// https://bytedance.feishu.cn/docs/doccn80ddvo7ogLMTOEGcM9Tw7e
    /// https://bytedance.feishu.cn/sheets/shtcnQbJtsJI9CFE7ub4q628JMe
    public enum SwitchKey: String, CaseIterable {
        public typealias RawValue = String

        /// 启动引导页显示开关，默认为true(开)
        case launchGuide = "launch_guide"

        /// Android热修
        case suiteAndroidHotfix = "suite_android_hotfix"

        /// Android插件
        case suiteAndroidPlugin = "suite_android_plugin"

        /// 切换租户
        case suiteTransferFunction = "suite_transfer_function"

        /// "加入/创建团队"
        case suiteJoinFunction = "suite_join_function"

        /// 最佳实践
        case suiteBestPractice = "suite_best_practice"

        /// “文件下载”功能是否支持（仅移动端，不包括PC）
        case suiteFileDownload = "suite_file_download"

        /// 设置页面“获取最新客户端版本”是否显示（目前 仅PC有这个功能）
        case suiteGetTheLatestVersion = "suite_get_the_latest_version"

        /// 隐藏帮助与服务入口，默认为true(显示)
        case suiteHelpService = "suite_help_service"

        /// 隐藏“帮助与客服”消息内入口
        case suiteHelpServiceMessage = "suite_help_service_message"

        /// 隐藏“帮助与客服”联系人入口
        case suiteHelpServiceContact = "suite_help_service_contact"

        /// 隐藏“帮助与客服”搜索入口
        case suiteHelpServiceSearch = "suite_help_service_search"

        /// “关于”-发现新版本
        case suiteAboutSoftwareupdate = "suite_about_softwareupdate"

        /// "关于"-更新日志
        case suiteAboutReleasenote = "suite_about_releasenote"

        /// "关于"-安全白皮书
        case suiteAboutWhitepaper = "suite_about_whitepaper"

        /// "关于"-应用权限说明
        case suiteAboutAppPermission = "suite_about_app_permission"

        /// "关于"-第三方SDK列表
        case suiteAboutThirdpartySdk = "suite_about_thirdparty_sdk"

        /// 客户端隐藏PoweredBy，默认为true（隐藏）
        case suitePoweredBy = "suite_powered_by"

        /// RustSDK probe metrics上传的开关
        case suiteProbe = "suite_probe"

        /// 举报功能开关：PC、移动端群设置页面底部
        ///  移动个人名片右上角...里
        ///  PC、移动端单聊设置页面
        ///  日程详情
        ///  docs举报入口
        case suiteReport = "suite_report"

        /// “软件隐私协议” 是否需要关闭
        case suiteSoftwarePrivacyAgreement = "suite_software_privacy_agreement"

        /// "软件用户协议" 是否需要关闭
        case suiteSoftwareUserAgreement = "suite_software_user_agreement"

        /// 特色功能介绍
        case suiteSpecialFunction = "suite_special_function"

        /// ➕下拉选项里的“添加朋友” 功能是否显示
        case suiteToCEnable = "suite_to_c_enable"

        /// 翻译开关
        case suiteTranslation = "suite_translation"

        /// VC功能
        case suiteVc = "suite_vc"

        /// “视频下载”功能是否支持（仅移动端，不包括PC）
        case suiteVideoDownload = "suite_video_download"

        /// 语音转文字开关
        case suiteVoice2Text = "suite_voice2text"

        /// AbTest
        case ttAbTest = "tt_ab_test"

        /// RustSDK获取device_id是否使用老加密算法，SaaS使用老加密，私有化使用新加密
        case ttDeviceOldCryption = "tt_device_old_cryption"

        /// fabric上报开关
        case ttFabric = "tt_fabric"

        /// Gecko资源热更开关
        case ttGeckoHotfix = "tt_gecko_hotfix"

        /// graylog上报开关，passport登录前发的log，only for passport
        case ttGraylog = "tt_graylog"

        /// 是否打开log settings, iOS/Android使用，默认true
        case ttLogSettings = "tt_log_settings"

        /// RustSDK metrics上传的开关
        case ttMetrics = "tt_metrics"

        /// npth(Slardar内的crash上报)上报开关，only for Android
        case ttNpth = "tt_npth"

        /// 头条钱包、红包
        case ttPay = "tt_pay"

        /// RustSDK日志流上传的开关
        case ttSdklog = "tt_sdklog"

        /// sentry上报开关
        case ttSentry = "tt_sentry"

        /// Slardar上报开关
        case ttSlardar = "tt_slardar"

        /// iOS/Android的Slardar是否使用老加密，SaaS使用老加密，私有化使用新加密
        case ttSlardarOldCryption = "tt_slardar_old_cryption"

        /// TEA上报开关
        case ttTea = "tt_tea"

        /// Ttpush sdk 开关
        case ttTtpush = "tt_ttpush"

        /// 自研WebView，开关控制是否通过字节服务获取配置。
        case ttTtwebview = "tt_ttwebview"

        /// 群链接功能开关
        case shareLink = "share_link_enable"
    }

    /// https://bytedance.feishu.cn/docs/doccn80ddvo7ogLMTOEGcM9Tw7e
    public enum ConfigKey: String, CaseIterable {
        public typealias RawValue = String

        /// RustSDK probe metrics上传的域名
        case suiteProbeEndpoints = "suite_probe_endpoints"

        /// applog acitve服务uri，计激活安装，算DAU的，iOS/Android使用
        case ttActiveUri = "tt_active_uri"

        /// device服务域名, RustSDK使用
        case ttDeviceDomain = "tt_device_domain"

        /// device服务uri，iOS/Android的applog使用
        case ttDeviceUri = "tt_device_uri"

        /// graylog上报域名，only for passport
        case ttGraylogDomain = "tt_graylog_domain"

        /// RustSDK metrics上传的域名
        case ttMetricsEndpoints = "tt_metrics_endpoints"

        /// npth上报域名，only for Android
        case ttNpthDomain = "tt_npth_domain"

        /// RustSDK日志流上传的域名
        case ttSdklogEndpoints = "tt_sdklog_endpoints"

        /// sentry上报域名
        case ttSentryDomain = "tt_sentry_domain"

        /// Android: 卡顿、安全气垫、慢函数等异常数据的上报的域名iOS: crashUploadHost(Crash上报),
        ///  exceptionUploadHost(ANR 等异常事件上报),
        ///  userExceptionUploadHost
        case ttSlardarExceptionDomain = "tt_slardar_exception_domain"

        /// Android: Slardar性能、网络、事件等数据的上报域名iOS: performanceUploadHost(CPU性能),
        ///  fileUploadHost(文件上传)
        case ttSlardarLogDomain = "tt_slardar_log_domain"

        /// Android/iOS: Slardar拉取配置的域名
        case ttSlardarSettingDomain = "tt_slardar_setting_domain"

        /// TEA上报域名，只给rust用，客户端使用tt_tea_endpoints
        case ttTeaDomain = "tt_tea_domain"

        /// TEA上报的endpoints，给客户端使用。
        ///  iOS需要有2个元素，第2个元素是备用地址，否则会读sdk内的备用地址；Android无此要求，不过建议在设置上和iOS统一
        case ttTeaEndpoints = "tt_tea_endpoints"

        case docFrontierAppKey = "doc_frontier_app_key"

        case suiteSoftwareUserAgreementLink = "suite_software_user_agreement_link"

        case suiteSoftwarePrivacyAgreementLink = "suite_software_privacy_agreement_link"
    }
}
