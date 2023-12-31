//
//  SettingConfig.swift
//  LarkSetting
//
//  Created by liuzhangchi on 2021/7/18.
//
//  swiftlint:disable file_length

import Foundation
import LarkSetting
import SKInfra

extension SettingConfig {

    ///ConfigKey---------

    @Setting(key: .make(userKeyLiteral: "requestTraceWhiteList"))
    public static var teststr: [String]?

    @Setting(key: .make(userKeyLiteral: "editor_pool_max_use_count_per_item"))
    public static var editorPoolMaxUsedCountPerItem: Int?

    @Setting(key: .make(userKeyLiteral: "doc_open_event_match_str"))
    public static var docOpenEventMatchStr: String?

    @Setting(key: .make(userKeyLiteral: "comment_voice_button_style")) // Android端没有使用这个key了，就不从mina迁移了，@zhaolexi
    public static var commentVoiceButtonStyle: Int?

    @Setting(key: .make(userKeyLiteral: "newYear_survey_duration"))
    public static var newYearSurveyDuration: String?

    @Setting(key: .make(userKeyLiteral: "docs_preload_client_var_config"))
    public static var preloadRecentCount: Int?

    @Setting(key: .make(userKeyLiteral: "timeForDelayLoadRN"))
    public static var timeForDelayLoadRN: Int?

    @Setting(key: .make(userKeyLiteral: "timeForDelayLoadURL"))
    public static var timeForDelayURL: Int?

    @Setting(key: .make(userKeyLiteral: "list_request_timeout"))
    public static var listRequestTimeout: Int?

    @Setting(key: .make(userKeyLiteral: "loading_delay_time"))
    public static var loadingDelayMilliscond: Int?

    @Setting(key: .make(userKeyLiteral: "meta_sync_config"))
    public static var numOfFilesSyncMeta: Int?

    @Setting(key: .make(userKeyLiteral: "drive_convert_file_size_limit"))
    public static var convertFileSizeLimit: Int?

    @Setting(key: .make(userKeyLiteral: "carrier_timeout"))
    public static var carrierTimeout: Double?

    @Setting(key: .make(userKeyLiteral: "wifi_timeout"))
    public static var wifiTimeout: Double?

    @Setting(key: .make(userKeyLiteral: "disabled_onboardings"))
    public static var disabledOnboardingsOri: [String]?

    @Setting(key: .make(userKeyLiteral: "editor_addView_time"))
    public static var editorAddViewTime: String?

    @Setting(key: .make(userKeyLiteral: "disabled_onboardings"))
    public static var disabledOnboardingList: [String]?

    @Setting(key: .make(userKeyLiteral: "drive_cache_config"))
    public static var driveAutoCleanRemainPercentage: Double?

    @Setting(key: .make(userKeyLiteral: "isv_meta_timeout"))
    public static var isvMetaTimeout: Double?

    @Setting(key: .make(userKeyLiteral: "drive_wps_domain"))
    public static var driveWPSDomain: String?

    @Setting(key: .make(userKeyLiteral: "preload_jsmodule_config"))
    public static var preloadJsmoduleConfig: [String: Bool]?

    @Setting(key: .make(userKeyLiteral: "preload_jsmodule_sequencing_config"))
    public static var preloadJsmoduleSequeceConfig: [String]?

    @Setting(key: .make(userKeyLiteral: "docx_i18n_name"))
    public static var docxMinaName: [String: String]?

    @Setting(key: .make(userKeyLiteral: "folder_permission_help_config"))
    public static var folderPermissionHelpConfigOri: [String: String]?

    @Setting(key: .make(userKeyLiteral: "wiki_migration_help_document"))
    public static var wikiMigrationHelpCenterURL: String?

    // ------如果返回值有字典的需要自己创建对应结构体
    public static var appConfigForFrontEnd: [String: Any]? {
        return try? SettingManager.shared.setting(with: .make(userKeyLiteral: "app_config"))
    }

    public static var domainConfig: [String: Any]? {
        return try? SettingManager.shared.setting(with: .make(userKeyLiteral: "domain_config"))
    }

    public static var retentionDomainConfig: String? {
        return DomainSettingManager.shared.currentSetting["scs_data"]?.first
    }
    
    public static var DocsPreloadPriorityConfig: [String: Any]? {
        return try? SettingManager.shared.setting(with: .make(userKeyLiteral: "docs_preload_priority"))
    }

    @Setting(key: .make(userKeyLiteral: "LauncherV2Config"))
    public static var launcherV2Config: StructLauncherV2Config?

    @Setting(key: .make(userKeyLiteral: "more_new_items"), .useDefaultKeys)
    public static var moreNewItems: [String: Bool]?
    // 先直接调用SettingManager的方法，等后续改为warpper
    // @Setting(key: "drive_sdk_config")
    public static var driveSDKConfigData: [String: Any]? {
        return try? SettingManager.shared.setting(with: .make(userKeyLiteral: "drive_sdk_config"))
    }
    
    public static var workspaceConfig: [String: Any]? {
        return try? SettingManager.shared.setting(with: .make(userKeyLiteral: "ccm_mobile_workspace_config"))
    }

    // -------如果返回值字典中的Key为非法变量名需要用以下方法

    @Setting(.useDefaultKeys)
    public static var editorPoolMaxCount: EditorPoolMaxCount?

    @Setting(.useDefaultKeys)
    public static var docsPreloadTimeOut: DocsPreloadPermissionCacheTimeOut?
    
    @Setting(.useDefaultKeys)
    public static var docsPreloadTaskArchvied: DocsPreloadTaskArchvied?

    @Setting(.useDefaultKeys)
    public static var spaceRustPushConfig: SpaceRustPushConfig?

    @Setting(.useDefaultKeys)
    public static var drivePreviewConfigKey: StructDrivePreviewConfigKey?

    @Setting(.useDefaultKeys)
    public static var driveRustConfig: StructDriveRustConfig?

    @Setting(.useDefaultKeys)
    public static var timeoutForOpenDoc: StructWiFiTimeoutForOpenDoc?
    
    @Setting(.useDefaultKeys)
    public static var timeoutForOpenDocNew: StructTimeoutForOpenDoc?

//    @Setting(.useDefaultKeys)
//    public static var folderPermissionHelpConfigOri: StructFolderPermissionHelpConfigOri?

    @Setting(.useDefaultKeys)
    public static var drivePreloadConfig: StructDrivePreloadConfig?

    @Setting(.useDefaultKeys)
    public static var policyConfig: StructPolicyConfig?

    @Setting(.useDefaultKeys)
    public static var externalShareConfig: StructExternalShareConfig?

    @Setting(.useDefaultKeys)
    public static var manualOfflineConfig: StructManuOfflieConfig?

    @Setting(.useDefaultKeys)
    public static var offlineCacheConfig: StructOfflineCacheConfig?

    @Setting(.useDefaultKeys)
    public static var offlineDbConfig: StructOfflineDbConfig?

    @Setting(.useDefaultKeys)
    public static var viewCapturePreventingConfig: CapturePreventingConfig?

    @Setting(.useDefaultKeys)
    public static var commentDraftConfig: CommentDraftSettingConfig?

    @Setting(.useDefaultKeys)
    public static var docsWebViewConfig: DocsWebViewConfig?

    @Setting(.useDefaultKeys)
    public static var openDocsConfig: OpenDocsConfig?

    /// 单容器改造 v4.3
    @RealTimeFeatureGatingProvider(key: "spacekit.mobile.single_container_enable")
    public static var singleContainerEnable: Bool
    ///云空间大文件上传兜底
    @RealTimeFeatureGatingProvider(key: "ccm.drive.size_limit_enable")
    public static var sizeLimitEnable: Bool

    @Setting(.useDefaultKeys)
    public static var clipBlackList: StructClipBlackList?

    @Setting(.useDefaultKeys)
    public static var secretBannerConfig: SecretBannerConfig?

    @Setting(.useDefaultKeys)
    public static var thumbImageConfig: ThumbnailPreviewConfig?

    @Setting(.useDefaultKeys)
    public static var approveRecordProcessUrlConfig: ApproveRecordProcessUrlConfig?

    @Setting(.useDefaultKeys)
    public static var cookieCompensationConfig: CookieCompensationConfig?

    @Setting(.useDefaultKeys)
    public static var dlpBannerConfig: DLPBannerConfig?

    @Setting(.useDefaultKeys)
    public static var shareWithPasswordConfig: ShareWithPasswordConfig?

    @Setting(.useDefaultKeys)
    public static var ccmRegengBlackListConfig: CcmRegengBlackListConfig?
    
    // 创建文件夹后，由于后端主从延迟问题，需要延迟后再打开文件夹，单位 ms
    @Setting(key: .make(userKeyLiteral: "create_folder_delay"))
    public static var createFolderDelay: Int?

    @Setting(.useDefaultKeys)
    public static var docsURLRegexConfig: DocsURLRegexConfig?

    @Setting(.useDefaultKeys)
    public static var magicShareFloatingWinConfig: MagicShareFloatingWinConfig?
    
    @Setting(.useDefaultKeys)
    public static var tnsReportConfig: TnsReportConfig?
    
    @Setting(.useDefaultKeys)
    public static var docsFeedPushPreloadConfig: DocsFeedPushPreloadConfig?

    @Setting(key: .make(userKeyLiteral: "email_validate_regular"))
    public static var emailValidateRegular: [String:String]?
    
    @Setting(.useDefaultKeys)
    public static var commentPerformanceConfig: CommentPerformanceConfig?

    @Setting(.useDefaultKeys)
    public static var leaderPermConfig: LeaderPermConfig?
    
    @Setting(.useDefaultKeys)
    public static var docsForecastConfig: DocsForecastConfig?
    
    @Setting(.useDefaultKeys)
    public static var ssrWebviewConfig: SSRWebViewConfig?
    
    @Setting(key: .make(userKeyLiteral: "token_pattern"))
    public static var tokenPattern: String?
    
    @Setting(.useDefaultKeys)
    public static var ios17CompatibleConfig: iOS17CompatibleConfig?
    public static var docComponentConfig: [String: Any]? {
        return try? SettingManager.shared.setting(with: .make(userKeyLiteral: "doc_component_config_mobile_all"))
    }
    
    @Setting(.useDefaultKeys)
    public static var myAIChatModeConfig: MyAIChatModeSetting?

    @Setting(.useDefaultKeys)
    public static var disablePreloadConfig: DisablePreloadStrategy?

    @Setting(.useDefaultKeys)
    public static var pdfInlineAIMenuConfig: PDFInlineAIMenuConfig?

    @Setting(key: .make(userKeyLiteral: "ccm_mobile_block_menu_max_line"))
    public static var blockMenuMaxLine: Int?
}

//----由于Any类型以及字典类型不能实现Decodable，所以要自定义与返回值类型相关的结构体----//

public struct StructLauncherV2Config: Decodable {
    public let isEnableLauncherV2: Bool
    public let monitorInterval: Double
    public let leisureCondition: Double
    public let leisureTimes: Int
}

//----如果返回的字典Key有不能作为变量名的情况使用以下方案----//

public struct StructWiFiTimeoutForOpenDoc: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "open_doc_timeout")
    public let wifi: Int
    public let wwan4G: Int
    public let backGround: Int
    public let templateWaitTime: Int

    enum CodingKeys: String, CodingKey {
        case wifi = "Wi-Fi"
        case wwan4G = "4G"
        case backGround = "backGround"
        case templateWaitTime = "templateWaitTime"
    }
}

public struct StructTimeoutForOpenDoc: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_open_timeout")
    let highDevice: SettingConfig
    let midDevice: SettingConfig
    let lowDevice: SettingConfig
    public let maxUnresposiveTime: Int  //最大无响应时间

    enum CodingKeys: String, CodingKey {
        case highDevice = "high_conf"
        case midDevice = "mid_conf"
        case lowDevice = "low_conf"
        case maxUnresposiveTime = "max_unresposive_time"
    }
    struct SettingConfig: Codable {
        let wifi: Int
        let wwan4G: Int
        let backGround: Int
        let templateWaitTime: Int
    }
}

public struct StructManuOfflieConfig: SettingDecodable{
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "manual_offline_config")
    let manualOfflineEnabled: Bool
    let manualOfflineWatchMaxNum: Int
    let manualOfflineSuspendTime: Int
    let docEnabled: Bool
    let driveEnabled: Bool
    let sheetEnabled: Bool
    let bitableEnabled: Bool
    let slideEnabled: Bool
    let mindnoteEnabled: Bool
    let guideEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case manualOfflineEnabled = "manual_offline_enabled"
        case manualOfflineWatchMaxNum = "manual_offline_watch_max_num"
        case manualOfflineSuspendTime = "manual_offline_suspend_time"
        case docEnabled = "doc_enabled"
        case driveEnabled = "drive_enabled"
        case sheetEnabled = "sheet_enabled"
        case bitableEnabled = "bitable_enabled"
        case slideEnabled = "slide_enabled"
        case mindnoteEnabled = "mindnote_enabled"
        case guideEnabled = "guide_enabled"
    }

}

public struct StructOfflineDbConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "offline_db_config")
    let clientVarCacheSize: Int
    let docsPicCacheSize: Int
    let docsDelayToClean: Int

    enum CodingKeys: String, CodingKey {
        case clientVarCacheSize = "offline_db_size"
        case docsPicCacheSize = "offline_pic_cache_size"
        case docsDelayToClean = "offline_clean_delay"
    }

}

//public struct StructFolderPermissionHelpConfigOri: SettingDecodable {
//    public static let settingKey: String = "folder_permission_help_config"
//    let cnurl: String
//    let enurl: String
//
//    enum CodingKeys: String, CodingKey {
//        case cnurl = "cn_url"
//        case enurl = "en_url"
//    }
//}

public struct StructDrivePreloadConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "drive_preload_config")
    let recent: Int
    let pin: Int
    let favorite: Int
    let filemaxsize: Int
    let cachevideosize: Int

    enum CodingKeys: String, CodingKey {
        case recent = "recent"
        case pin = "pin"
        case favorite = "favorite"
        case filemaxsize = "file_max_size"
        case cachevideosize = "cache_video_size"
    }
}

public struct StructDrivePreviewConfigKey: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "drive_preview_config")
    let textPreviewMaxSize: UInt64
    let highLightMaxSize: UInt64
    let partPDFMaxSize: UInt64
    let fetchPartPdfMinPage: UInt64
    let webpMaxSize: UInt64
    let renderHtmlFileMaxSize: UInt64
    let excelTabDataMaxSize: UInt64
    let downloadOriginFileMaxSize: UInt64
    let localArchiveMaxSize: UInt64
    // pdfkit支持渲染的单页最大文件大小，超过可能OOM
    let pdfkitMaxSizePerPage: UInt64
    // iOS 横竖屏有问题的系统版本
    let orientationBugSystems: [String]
    /// WPS webview 因内存问题回收时重试加载次数
    let wpsRenderTerminateRetryCount: UInt64
    /// WPS 模版加载超时时间，单位秒
    let wpsTemplateTimeout: UInt64
    /// 是否开启 tt_video Outlet 线程 CPU 优化
    let ttVideoOutletThreadOptimizeEnable: Bool?
    /// 转码中小视频降级预览的阈值(默认20M)单位KB
    let smallVideoSize: UInt64?
    /// 转码中原视频在线播放的码率阈值，单位bps
    let littleBitRate: UInt64?
    /// 转码中原视频在线播放的编码类型，默认为h265/h264和hevc
    let videoSupportSourcePreviewTypes: [String]?
    
    // PDF 缩放大小限制
    let pdfMaxScale: Float?
    let pdfMinScale: Float?


    enum CodingKeys: String, CodingKey {
        case textPreviewMaxSize = "text_preview_max_size"
        case highLightMaxSize = "highlight_max_size"
        case partPDFMaxSize = "part_pdf_max_size"
        case fetchPartPdfMinPage = "fetch_part_pdf_min_page"
        case webpMaxSize = "webp_max_size"
        case renderHtmlFileMaxSize = "render_html_file_max_size"
        case excelTabDataMaxSize = "excel_tab_data_max_size"
        case downloadOriginFileMaxSize = "download_origin_file_max_size"
        case localArchiveMaxSize = "local_archive_max_size"
        case pdfkitMaxSizePerPage = "pdfkit_max_size_per_page"
        case orientationBugSystems = "orientation_bug_systems"
        case wpsRenderTerminateRetryCount = "wps_render_gone_retry_count"
        case wpsTemplateTimeout = "wps_template_timeout"
        case ttVideoOutletThreadOptimizeEnable = "tt_video_outlet_thread_optimize_enable"
        case smallVideoSize = "small_video_size"
        case littleBitRate = "little_bit_rate"
        case videoSupportSourcePreviewTypes = "video_support_source_preview_type"
        case pdfMaxScale = "pdf_max_scale"
        case pdfMinScale = "pdf_min_scale"
    }
}

public struct StructDriveRustConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "drive_rust_config")
    public let disableCdnDownload: Bool
    public let newCdnDomainSelect: Bool
    public let multiTask: Bool
    public let useRangeInPart: Bool
    public let weakOptimize: Bool
    public let smartClearDB: Bool
    public let maxThreadSize: Int
    public let maxDownloadPartSize: Int
    public let smallUploadFileSize: Int

    enum CodingKeys: String, CodingKey {
        case disableCdnDownload = "disable_cdn_download"
        case newCdnDomainSelect = "new_cdn_domain_select"
        case multiTask = "multi_task"
        case useRangeInPart = "use_range_in_part"
        case weakOptimize = "weak_optimize"
        case smartClearDB = "smart_clear_db"
        case maxThreadSize = "max_thread_size"
        case maxDownloadPartSize = "max_download_part_size"
        case smallUploadFileSize = "small_upload_file_size"
    }
}

public struct StructPolicyConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "policy_config")
    public let serviceTermUrl: String
    public let privacyUrl: String

    public enum CodingKeys: String, CodingKey {
        case serviceTermUrl = "service_term_url"
        case privacyUrl = "privacy_url"
    }
}

public struct SecretBannerConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "key_set_secure_lable")
    public let enUrl: String
    public let cnUrl: String
    public enum CodingKeys: String, CodingKey {
        case enUrl = "en_url"
        case cnUrl = "cn_url"
    }
}

public struct ApproveRecordProcessUrlConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "approve_record_process_url")
    public let url: String
    public enum CodingKeys: String, CodingKey {
        case url = "approve_record_process_url"

    }
}
public struct DLPBannerConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_gpe_dlp_banner_more")
    public let enUrl: String
    public let cnUrl: String
    public enum CodingKeys: String, CodingKey {
        case enUrl = "en_url"
        case cnUrl = "cn_url"
    }
}

public struct LeaderPermConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "leader_perm_center")
    public let enUrl: String
    public let cnUrl: String
    public let jpUrl: String
    public enum CodingKeys: String, CodingKey {
        case enUrl = "en_url"
        case cnUrl = "cn_url"
        case jpUrl = "jp_url"
    }
}

public struct ShareWithPasswordConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_folder_ShareWithPasswordEnable")
    public let docEnable: Bool
    public let folderEnable: Bool
    public enum CodingKeys: String, CodingKey {
        case docEnable = "doc_enable"
        case folderEnable = "folder_enable"
    }
}

public struct StructOfflineCacheConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "offline_cache_config")
    public let offlineCacheEnable: Bool
    public let onlyWifi: Bool
    public let recentListPreloadClientvarNumber: Int
    public let preloadImageOnlyWifi: Bool
    public let updateClientVarFrequency: Int
    public let ssrPreloadCount: Int
    public let ssrPreloadQueryMaxCount: Int
    public let ssrPreloadQueryDays: Int
    public let lowDeviceCanPrelaod: Bool

    enum CodingKeys: String, CodingKey {
        case offlineCacheEnable = "offline_cache_enabled"
        case onlyWifi = "only_wifi"
        case recentListPreloadClientvarNumber = "recent_list_preload_clientvar_number"
        case preloadImageOnlyWifi = "preload_image_only_wifi"
        case updateClientVarFrequency = "update_clientvar_frequency"
        case ssrPreloadCount = "docx_ssr_preload_count"
        case ssrPreloadQueryMaxCount = "docx_ssr_preload_look_db_limit"
        case ssrPreloadQueryDays = "docx_ssr_preload_uptime"
        case lowDeviceCanPrelaod = "docs_low_device_can_preload"
    }
}

public struct StructExternalShareConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "external_share_config")
    let qq: Config
    let wb: Config
    let wx: Config
    let enableShareMiniApp: Bool

    enum CodingKeys: String, CodingKey {
        case qq = "QQConfig"
        case wb = "WBConfig"
        case wx = "WXConfig"
        case enableShareMiniApp = "enableShareMiniApp"
    }

    struct Config: Codable {
        let isShareChannelBanned: Bool
        let isShareDomainBanned: Bool
    }
}

public struct SpaceRustPushConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "list_push_sync_config")

    public let shouldShowRefreshTips: Bool
    public let registerSize: Int
    // 单位 ms
    public let allowedTimeOffset: TimeInterval
    public let firstScreenItemCount: Int
    public let backgroundRefreshSize: Int
    // tip 持续时间，单位 ms
    public let refreshTipDuration: TimeInterval
    // 两次 tip 间隔，单位 ms
    public let minimumTipInterval: TimeInterval
    // space 列表自动拉取的间隔，单位 s
    public let refreshInterval: Int

    enum CodingKeys: String, CodingKey {
        case shouldShowRefreshTips = "show_refresh_tips_ui"
        case registerSize = "register_size"
        case allowedTimeOffset = "allowed_time_offset"
        case firstScreenItemCount = "first_screen_item_count"
        case backgroundRefreshSize = "background_refresh_size"
        case refreshTipDuration = "refresh_tip_duration"
        case minimumTipInterval = "minimum_tip_interval"
        case refreshInterval = "refresh_interval"
    }

    // nolint: magic number
    public static let `default` = Self(shouldShowRefreshTips: true,
                                       registerSize: 100,
                                       allowedTimeOffset: 180_000, // 默认 3分钟
                                       firstScreenItemCount: -1,
                                       backgroundRefreshSize: 50,
                                       refreshTipDuration: 5000, // 5s
                                       minimumTipInterval: 10_000, // 10s
                                       refreshInterval: 30) // 30s
    // enable-lint
}

public struct EditorPoolMaxCount: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "editor_pool_max_count")
    public let maxCount: Int
    public let maxCountForPhone: Int
    public let maxCountForPad: Int
    public let memoryRatio: Float
    enum CodingKeys: String, CodingKey {
        case maxCount = "editor_pool_max_count"
        case memoryRatio = "ms_max_memory_ratio"
        case maxCountForPhone = "iphone_editor_pool_max_count"
        case maxCountForPad = "ipad_editor_pool_max_count"
    }
}

/// 预加载权限缓存文件有效期
public struct DocsPreloadPermissionCacheTimeOut: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "preload_permission_cache_max_time")
    public let timeOut: Double
    public let ssrRetry: Int
    public let memoryWarningLevel: Int
    public let webviewMemorySize: Int //WebView预加载后预估的内存大小
    public let minRemainPreloadWebViewMemorySize: Int //可预加载webview的最小剩余内存大小
    enum CodingKeys: String, CodingKey {
        case timeOut = "preload_permission_cache_max_time"
        case ssrRetry = "preload_ssr_retry_max_count"
        case memoryWarningLevel = "preload_webview_memory_warning_level"
        case webviewMemorySize = "preload_webview_memory_size"
        case minRemainPreloadWebViewMemorySize = "min_remain_preload_webView_memory_size"
    }
}

public struct DocsPreloadTaskArchvied: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_preload_archvied")
    public let supportTypes: [String]
    public let supportFroms: [String]
    public let validityTime: Double
    public let maxCount: Int
    enum CodingKeys: String, CodingKey {
        case supportTypes = "support_types"
        case supportFroms = "support_froms"
        case validityTime = "validity_time"
        case maxCount = "max_count"
    }
}

/// 防截图配置
public struct CapturePreventingConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_screen_capture_prevent_config")
    /// iOS 和 iPadOS 不支持防截图的版本(黑名单)
    public let ios_version_blacklist: [String]
}

/// 评论草稿配置
public struct CommentDraftSettingConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_comment_draft_config")
    /// 草稿有效期，单位：秒
    public let draftValidityPeriod: Int
}

/// DocsWebView配置
public struct DocsWebViewConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_webview_config")
    //无响应超时阈值
    public let responsiveness_timeout: Double
    //最大连续加载失败次数，超过则任务无响应
    public let maxContinuousFailCount: Int?
    //当连续加载失败次数达到时，尝试reload
    public let tryReloadContinuousFailCount: Int?
    //调用preloadJsModule的超时设置
    public let preloadJsModuleTimeOut: Double?
    //重置WKProcessPool failCount
    public let resetWKProcessPoolContinuousFailCount: Int?
    //低端机禁止预加载
    public let disableLowMobilePreload: Bool
    //重置WebView策略
    public let resetWebViewPolicy: ResetWebViewPolicy
    //连续错误达到一定次数后，停止自动预加载webview
    public let stopAutoPreloadWebViewContinuousFailCount: Int?
    //是否优先移除Pool中的webview
    public let removePoolWebViewFirst: Bool?
    //clear后存活秒数
    public let aliveAfterClearSeconds: Int?
    //是复用池时，是否挂载到window上
    public let attachOnWindowWhenInPool: Bool?
    //attach到window的秒数
    public let attachOnWindowSeconds: Int?
    //自动刷新最大次数
    public let autoReloadMaxCount: Int?
    //刷新tips的间隔（每N次弹一次）
    public let reloadTipsInterval: Int?

    
    public struct ResetWebViewPolicy: Codable {
        //是否终止网络进程
        public let shouldKillNetworkProcess: Bool
        //是否终止所有进程
        public let shouldKillAllWebContentProcess: Bool
        //是否清理WebView缓存
        public let shouldClearWebCache: Bool
        //重置WKProcessPool
        public let resetWKProcessPool: Bool
        //当重置WebView错误达到一定次数后，停止自动重置webview
        public let resetWebViewMaxCount: Int?
    }
}

public struct OpenDocsConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "open_docs_config")
    //打开文档忽略重复失败Event
    public let ignoreRepeatFailEvent: Bool
    public let ignoreRepeatLoadStatus: Bool
    //WebView hideLoading等待didFinish的最大时长，-1一直wait，0马上，>0延时
    public let hideLoadingWaitFinishMaxTime: Double
}

public struct StructClipBlackList: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "clip_black_list")

    let blackList: [String]
}

public struct ThumbnailPreviewConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "drive_image_thumb_config")
    static let defaultMin: UInt64 = 1 * 1024 * 1024
    public let typesConfig: [String: UInt64]
    public let suppotedApps: [String]
    public let minSize: UInt64
    public let enable: Bool
    enum CodingKeys: String, CodingKey {
        case typesConfig = "typesConfig"
        case minSize = "minSize"
        case suppotedApps = "supportAppID"
        case enable = "enable"
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let configs = (try? container.decodeIfPresent([String: UInt64].self, forKey: .typesConfig)) ?? [:]
        typesConfig = Dictionary(uniqueKeysWithValues: configs.map { key, value in (key.uppercased(), value) })
        suppotedApps = (try? container.decode([String].self, forKey: .suppotedApps)) ?? []
        minSize = (try? container.decode(UInt64.self, forKey: .minSize)) ?? Self.defaultMin
        enable = (try? container.decode(Bool.self, forKey: .enable)) ?? false
    }
}

// https://bytedance.feishu.cn/docx/S3rMdf5q1oLzjLx7u3WcEevqnue
public struct CookieCompensationConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_cookie_compensation_config")

    enum CodingKeys: String, CodingKey {
        case canHookSetCookie = "can_hook_set_cookie"
        case needAuthUrls = "need_auth_urls"
        case slardarEnable = "slardar_enable"
    }

    public let canHookSetCookie: Bool
    public let needAuthUrls: [String]
    public let slardarEnable: Bool?
}

///  邮箱、URL正则匹配规则
public struct DocsURLRegexConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_at_regex_config")
    let linkRegex: String
    let newRuleEnable: Bool
    let blackSuffixList: [String]
}

/// MS小窗配置
public struct MagicShareFloatingWinConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_ms_floating_win_config")

    enum CodingKeys: String, CodingKey {
        case keepWebviewActiveTime = "Keep_webview_active_time"
        case rnAggregationInterval = "rn_aggregation_interval"
        case debounceTime = "debounce_time"
        case maxAggregationSize = "max_aggregation_size"
        case enableInAppBackground = "enable_in_appbackground"
        case monitorThermalState = "monitor_thermal_state"
    }

    public let keepWebviewActiveTime: Int
    public let rnAggregationInterval: Int
    public let debounceTime: Int
    public let maxAggregationSize: Int
    public let enableInAppBackground: Bool
    public let monitorThermalState: Bool
}

///Lark举报
public struct TnsReportConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "tns_report_config")
        enum CodingKeys: String, CodingKey {
        case reportPath = "report_path"
        case token = "token"
    }

    public let reportPath: String
    public let token: String

    
    public static let `default` = Self(reportPath: "/cust/lark_report",
                                       token: "")
}


public struct CcmRegengBlackListConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_regeng_black_list_config")
    
    enum CodingKeys: String, CodingKey {
        case enable = "enable"
        case blackListUid = "black_list_uid"
    }
    
    public let enable: Bool
    public let blackListUid: [String]
}


public struct CommentPerformanceConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_mobile_comment_performance_config")
    
    enum CodingKeys: String, CodingKey {
        case fpsEnable = "fps_collection_enable"
        case editable = "editable_cost_enable"
        case loadEnable = "load_cost_enable"
        case sendEnable = "send_comment_enable"
    }
    
    public let fpsEnable: Bool
    public let editable: Bool
    public let loadEnable: Bool
    public let sendEnable: Bool
}

public struct DocsFeedPushPreloadConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_feed_push_config")
    enum CodingKeys: String, CodingKey {
        case preloadDelay = "docs_feed_push_preload_delay" //MS
        case preloadLimitCount = "docs_feed_push_preload_limit"
    }
    public let preloadDelay: Int
    public let preloadLimitCount: Int
}

//用户行为预测
public struct DocsForecastConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "docs_forecast_config")
    enum CodingKeys: String, CodingKey {
        case recordLength = "record_length"
        case disableWebviewPreloadCount = "disable_webview_preload"
        case disableTemplatePreloadCount = "disable_template_preload"
        case maxPreloadTypeCount = "max_preload_type_count"
        case supportPreloadTypes = "support_preload_types"
    }
    public let recordLength: Int
    public let disableWebviewPreloadCount: Int
    public let disableTemplatePreloadCount: Int
    public let maxPreloadTypeCount: Int
    public let supportPreloadTypes: [Int]?
}

public struct SSRWebViewConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ssr_webview_config")
    enum CodingKeys: String, CodingKey {
        case promtTimeout = "promt_timeout"
        case enableInFullPreload = "enable_in_full_preload"
        case enableInPartPreload = "enable_in_part_preload"
        case enableInNotPreload = "enable_in_not_preload"
        case enableDocxAtWiki = "enable_docx_at_wiki"
    }
    // promt调用超时时间
    public let promtTimeout: Int
    // 完全预加载时是否可用
    public let enableInFullPreload: Bool
    // 部分预加载时是否可用
    public let enableInPartPreload: Bool
    // 未预加载时是否可用
    public let enableInNotPreload: Bool
    // DocX@wiki是否生效
    public let enableDocxAtWiki: Bool
    
}

// ios17适配
public struct iOS17CompatibleConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_ios17_compatible_config")
    enum CodingKeys: String, CodingKey {
        case fixKeyboardIssue = "fix_keyboard_issue"
        case fixNavibackIssue = "fix_naviback_issue"
        case fixInputViewIssue = "fix_inputView_issue"
        case fixSmartKeyboardIssueVersion = "fix_smartKeyboard_issue_version"
    }
    public let fixKeyboardIssue: Bool
    public let fixNavibackIssue: Bool
    public let fixInputViewIssue: Bool
    public let fixSmartKeyboardIssueVersion: String
}

public struct MyAIChatModeSetting: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_myai_chatmode_config")
    enum CodingKeys: String, CodingKey {
        case toolIds = "toolIds"
    }
    public let toolIds: [String]
}

public struct DisablePreloadStrategy: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_preload_source_disabled_strategy")
    enum CodingKeys: String, CodingKey {
        case sourceConfig = "source_config"
        case maxCount = "max_space_list_count"
        case preloadDisabled = "preload_disabled_when_app_start"
    }
    public let sourceConfig: [String: [String]]
    public let preloadDisabled: Bool
    public let maxCount: Int
}

public struct PDFInlineAIMenuConfig: SettingDecodable {
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_mobile_pdf_inline_ai_menu_config")

    enum CodingKeys: String, CodingKey {
        case missingList = "missing_list"
        case swizzledEnable = "swizzled_enable"
    }

    public let missingList: [String]?

    public let swizzledEnable: Bool
}
