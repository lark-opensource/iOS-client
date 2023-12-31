//
//  UserGeneralSettings.swift
//  LarkSDKInterface
//
//  Created by K3 on 2018/6/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LKCommonsLogging
import RustPB
import LarkLocalizations

public protocol UserGeneralSettings: AnyObject {
    /// 文件发送大小限制
    var fileUploadSizeLimit: BehaviorRelay<FileUploadSizeLimit> { get }
    /// Messenger单测黑名单机制
    var skipTestConfig: BehaviorRelay<SkipTestConfig> { get }
    /// 字节云平台视频发送限制
    var sendVideoConfig: SendVideoConfig { get }
    /// 字节云平台创建假消息配置
    var createQuasiMessageConfig: CreateQuasiMessageConfig { get }
    /// 字节云平台配置的messenger_video_compress
    var videoCompress: BehaviorRelay<MessengerVideoCompress> { get }
    /// 字节云平台配置的video_origin_type
    var originVideoCompress: BehaviorRelay<OriginVideoCompressConfig> { get }
    /// 字节云平台配置的ve_synthesis_settings
    var videoSynthesisSetting: BehaviorRelay<VideoSynthesisSetting> { get }
    /// 字节云平台配置的video_pre_process
    var videoPreprocessConfig: BehaviorRelay<VideoPreprocessConfig> { get }
    /// 字节云平台配置的bgtask_enable
    var bgTaskConfig: BGTaskConfig { get }
    /// 字节云平台配置的helpdesk_common
    var helpdeskCommon: HelpdeskCommon { get }
    /// 字节云平台配置的GroupConfig
    var groupConfig: GroupConfig { get }
    /// 字节云平台配置的desc_op
    var userGrowthConfig: UserGrowthConfig { get }
    /// byteCloud setting dominManagePolicy
    var dominManagePolicyConfig: DominManagePolicyConfig { get }
    /// 用户投放Source列表
    var ugBannerConfig: UGBannerConfig { get }
    /// 用户投放Source列表变化监听
    var ugBannerConfigChangeVariable: BehaviorRelay<Void> { get }
    /// Onboarding spotlight config
    var spotlightWorkspaceConfig: SpotlightWorkspaceConfig { get }
    /// 字节云平台配置的contacts_config
    var contactsConfig: ContactsConfig { get }

    /// 翻译设置
    var translateLanguageSetting: TranslateLanguageSetting { get }
    var translateLanguageSettingDriver: Driver<TranslateLanguageSetting> { get }
    /// 网页翻译配置
    var webTranslateConfig: SettingV3WebTranslateConfig { get }

    /// 帮助中心域名
    var helpDeskBizDomainConfig: HelpCenterBizDomainConfig { get }

    /// 推送新消息是否显示详情
    var showMessageDetail: Bool { get set }

    var adminCloseShowDetail: Bool { get set }

    /// 通话和会议中暂停消息
    var messageNotificationsOffDuringCalls: Bool { get set }

    var notifyConfig: NotifyConfig { get }

    var is24HourTime: BehaviorRelay<Bool> { get }
    /// gadget Engine AB 测试相关
    var gadgetABTestConfig: GadgetEngineConfig { get }
    /// op monitor config
    var opMonitorConfig: OPMonitorConfig { get }
    /// 推送降级端上资源监测策略配置
    var pushDowngradeAppLagConfig: PushDowngradeAppLagConfig? { get }
    ///消息预预处理配置
    var messagePreProcessConfig: MessagePreProcessConfig { get }
    ///获取机型分类配置
    var deviceClassifyConfig: DeviceClassifyConfig { get }
    /// 大 GIF 不自动播放配置
    var gifLoadConfig: GIFLoadConfig { get }
    var memberListNonDepartmentConfig: MemberListNonDepartmentConfig { get }

    /// 可在线解压缩的文件类型配置
    var messengerFileConfig: MessengerFileConfig { get }
    /// 消息气泡折叠配置
    var messageBubbleFoldConfig: MessageBubbleFoldConfig { get }
    /// 群Tab添加引导网页链接
    var chatTabAddUGLinkConfig: ChatTabAddUGLinkConfig { get }
    /// 群置顶 onboarding 网页链接
    var chatPinOnboardingDetailLinkConfig: ChatPinOnboardingDetailLinkConfig { get }
    /// 群接龙 url 的 path 配置
    var bitableGroupNoteConfig: BitableGroupNoteConfig { get }

    /// 会话页面是否启用新的防截（录）屏配置
    var chatSecureViewEnableConfig: ChatSecureViewEnableConfig? { get }
    /**
     同步远程推送消息显示设置
     */
    func fetchRemoteSettingFromServer(finish: ((Bool, Bool, Bool) -> Void)?)

    /**
     更新远程推送消息显示设置
     */
    func updateRemoteSetting(isShowDetail: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void)

    //更新是否显示拨打电话提示设置
    func updateRemoteSetting(showPhoneAlert: Bool, success: (() -> Void)?, failure: ((Error) -> Void)?)

    /**
     打开系统消息设置
     */
    func openNotificationSetting()

    /// 同步后再异步获取：消息显示详情，电话提示
    func initializeSyncSettings()

    // 关闭手机通知
    func updateNotificaitonStatus(notifyDisable: Bool)
    func updateNotificaitonStatus(notifyDisable: Bool, retry: Int)
    func updateNotificationStatus(notifyDisable: Bool) -> Observable<Bool>
    func updateNotificationStatus(notifyDisable: Bool, retry: Int) -> Observable<Bool>

    // @我的消息仍通知
    func updateNotificaitonStatus(notifyAtEnabled: Bool)
    func updateNotificaitonStatus(notifyAtEnabled: Bool, retry: Int)
    func updateNotificationStatus(notifyAtEnabled: Bool) -> Observable<Bool>
    func updateNotificationStatus(notifyAtEnabled: Bool, retry: Int) -> Observable<Bool>

    // 星标联系人的消息仍通知
    func updateNotificationStatus(notifySpecialFocus: Bool) -> Observable<Bool>
    func updateNotificationStatus(notifySpecialFocus: Bool, retry: Int) -> Observable<Bool>

    // 通知修改声音
    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem]) -> Observable<Bool>
    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem],
                                  retry: Int) -> Observable<Bool>

    /// 异步获取一次通知配置；pc登录客户端提醒，@消息提醒， 星标联系人提醒
    func fetchDeviceNotifySettingFromServer()

    /// 拉取翻译设置
    func fetchTranslateLanguageSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<Void>
    /// 设置TranslateScope，解释见TranslateLanguageSetting
    func updateAutoTranslateScope(scope: Int) -> Observable<Void>
    /// 修改源语种自动翻译设置scopes范围
    func updateSrcLanguageScopes(srcLanguagesScope: Int, language: String) -> Observable<Void>
    /// 设置翻译目标语言
    func updateTranslateLanguageSetting(language: String) -> Observable<Void>
    /// 设置翻译语言key->翻译效果
    func updateLanguagesConfiguration(globalConf: RustPB.Im_V1_LanguagesConfiguration?, languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]?) -> Observable<Void>
    /// 设置翻译显示翻译效果开关(一级)
    func updateGlobalLanguageDisplayConfig(globalConf: RustPB.Im_V1_LanguagesConfiguration) -> Observable<Void>
    /// 设置翻译源语言(三级) 的翻译效果
    func updateLanguagesConfigurationV2(srcLanguagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) -> Observable<Void>
    /// 修改自动翻译全局开关
    func setAutoTranslateGlobalSwitch(isOpen: Bool) -> Observable<Void>
    /// 设置不自动翻译的语言
    func updateDisableAutoTranslateLanguages(languages: [String]) -> Observable<Void>
}

/// 字节云平台配置的helpdesk_common，https://cloud.bytedance.net/appSettings/config/121002/detail/status
public struct HelpdeskCommon {
    public static let HelpdeskCommonRequestKey = "helpdesk_common"

    /// 服务台小程序appId，给一个默认值，兜底策略
    public var helpdeskMiniProgramAppId: String = "cli_9da5b90fc3ec110b"
    public var feishuMiniProgramAppLink: String = ""

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let helpdeskCommon = fieldGroups[HelpdeskCommon.HelpdeskCommonRequestKey] else { return nil }
        guard let data = helpdeskCommon.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
        guard let appId = jsonDict["helpdesk-mini-program-appId"] as? String, !appId.isEmpty else { return nil }
        guard let link = jsonDict["feishu_mini_app_link"] as? String, !link.isEmpty else { return nil }
        self.helpdeskMiniProgramAppId = appId
        self.feishuMiniProgramAppLink = link
    }
}

// 某个环境下转码参数配置，属性设置默认值为兜底策略，外部使用时无需担心值不正确。
public struct SubCompressConfig {
    /// 最大码率
    public private(set) var maxBitrate: Int = Int(1.5 * 1000 * 1000)
    /// 码率压缩倍数
    public private(set) var bitrateCompressScale: Int = 120

    /// 分辨率长边限制
    public private(set) var maxVideoSizeWidth: Int = 960
    /// 分辨率窄边限制
    public private(set) var maxVideoSizeNarrow: Int = 544

    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else { return nil }

        func intValue(_ key: String) -> Int? {
            return config[key] as? Int
        }

        // 当所有的属性都下发&&值符合预期时才进行赋值；
        // 这里特意不使用一次转成object的方法，因无法确定object中所有的属性都符合预期。
        guard let mb = intValue("max_bitrate"), let bcs = intValue("bitrate_compress_scale"),
              let mvsw = intValue("max_video_size_width"), let mvsn = intValue("max_video_size_narrow") else { return nil }

        // 赋值
        self.maxBitrate = mb
        self.bitrateCompressScale = bcs
        self.maxVideoSizeWidth = mvsw
        self.maxVideoSizeNarrow = mvsn
    }
}

public struct VideoResolution {
    public var width: CGFloat = 4096
    public var height: CGFloat = 4096

    public init() {}

    public init?(config: Any) {
        guard let config = config as? [String: CGFloat] else { return nil }

        guard let width = config["width"] else { return nil }
        guard let height = config["height"] else { return nil }

        self.width = width
        self.height = height
    }
}

public struct VideoFirstFrame {
    public var timeStamp: Int32 = 100
    public var blackAmount: Int32 = 80
    public var blackThreshold: Int32 = 40
    public var maxSkipFrame: UInt64 = 300
    public var transitionTime: Int32 = 0
    public init() {}
    public init?(config: Any) {
        guard let config = config as? [String: Any] else { return nil }
        guard let timeStamp = config["time_stamp"] as? Int32 else { return nil }
        guard let blackAmount = config["black_amount"] as? Int32 else { return nil }
        guard let blackThreshold = config["black_threshold"] as? Int32 else { return nil }
        guard let maxSkipFrame = config["max_skip_frame"] as? UInt64 else { return nil }
        guard let transitionTime = config["transition_time"] as? Int32 else { return nil }

        self.timeStamp = timeStamp
        self.blackAmount = blackAmount
        self.blackThreshold = blackThreshold
        self.maxSkipFrame = maxSkipFrame
        self.transitionTime = transitionTime
    }
}

/// 真正发送视频前的预检测阶段，超出限制将转为文件发送
public struct SendVideoConfig {
    public static let key = "send_video_msg_config"

    /// 单位：字节，超出将按照文件发送
    public var fileSize: Int64 = 5 * 1024 * 1024 * 1024
    /// 单位：秒，超出将按照文件发送
    public var duration: Double = 3 * 3600
    /// 分辨率，超出将按照文件发送
    public var resolution = VideoResolution()
    /// 帧率，超出将按照文件发送
    public var frameRate: CGFloat = 120
    /// 单位：bps，码率，超出将按照文件发送
    public var bitrate: CGFloat = 20 * 1024 * 1024

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let videoConfig = fieldGroups[SendVideoConfig.key] else { return nil }
        guard let data = videoConfig.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else { return nil }
        guard let baseConfig = jsonDict["base_config"] else { return nil }

        guard let fileSize = baseConfig["limit_file_size"] as? Int64 else { return nil }
        guard let duration = baseConfig["limit_video_duration"] as? Double else { return nil }
        guard let resolution = VideoResolution(config: baseConfig["limit_video_resolution"] ?? "") else { return nil }
        guard let frameRate = baseConfig["limit_video_frame_rate"] as? CGFloat else { return nil }
        guard let bitrate = baseConfig["limit_video_bitrate"] as? CGFloat else { return nil }

        self.fileSize = fileSize
        self.duration = duration
        self.resolution = resolution
        self.frameRate = frameRate
        self.bitrate = bitrate
    }
}

/*
 {
 "base_config": {
 "limit_file_size": 26214400,
 "limit_image_size": {
 "width": 10000,
 "height": 10000
 }
 },
 "jpg_config": {
 "limit_file_size": 26214400,
 "limit_image_size": {
 "width": 12000,
 "height": 12000
 }
 },
 "png_config": {
 "limit_file_size": 26214400,
 "limit_image_size": {
 "width": 8000,
 "height": 8000
 }
 },
 "gif_config": {
 "limit_file_size": 26214400,
 "limit_image_size": {
 "width": 7000,
 "height": 7000
 }
 }
 }
 */
extension String {

    func toDictionary() -> [String: Any]? {
        var result: [String: Any]?
        guard !self.isEmpty else { return result }
        guard let dataSelf = self.data(using: .utf8) else {
            return result
        }
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                                                       options: .mutableContainers) as? [String: Any] {
            result = dic
        }
        return result
    }
}

public struct CreateQuasiMessageConfig {
    public static let key = "custom_exception_config"
    public private(set) var isNativeQuasiMessage = false
    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else {
            return nil
        }
        if let map = config["create_quasi_message"] as? [String: Any],
           let isNativeQuasiMessage = map["is_native_quasi_message"] as? Bool {
            self.isNativeQuasiMessage = isNativeQuasiMessage
        }
    }

    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let configString = fieldGroups[Self.key] as? String,
              let config = configString.toDictionary() else {
            return nil
        }
        if let map = config["create_quasi_message"] as? [String: Any],
           let isNativeQuasiMessage = map["is_native_quasi_message"] as? Bool {
            self.isNativeQuasiMessage = isNativeQuasiMessage
        }
    }
}

//获取机型分类
public struct DeviceClassifyConfig {
    public enum MobileClassify {
        case highMobile         //高端机
        case midMobile          //中端机
        case lowMobile          //低端机
        case unClassifyMobile   //未分类机型
    }
    public var mobileClassify: MobileClassify = .unClassifyMobile //机型
    public var mobileScore: Double = 0
    public static let key = "get_device_classify"
    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else {
            return nil
        }
        if let deviceScore = config["cur_device_score"] as? Double {
            mobileScore = deviceScore
        }
        if let classify = config["mobileClassify"] as? String {
            if classify == "mobile_classify_high" {
                mobileClassify = .highMobile
            }
            if classify == "mobile_classify_mid" {
                mobileClassify = .midMobile
            }
            if classify == "mobile_classify_low" {
                mobileClassify = .lowMobile
            }
        }
    }
    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let configString = fieldGroups[Self.key] as? String,
              let config = configString.toDictionary() else {
            return nil
        }
        self.init(config: config)
    }
}

//消息预处理配置
public struct MessagePreProcessConfig {
    public static let key = "message_preProccess"
    /// 最大缓存预处理结果个数
    public private(set) var maxProccessCount: Int = 10
    /// 是否启动预处理
    public private(set) var enablePreProccess: Bool = false
    /// 最大可用内存
    public private(set) var maxMemory: Int = 200
    /// 是否开启封面预转码
    public private(set) var enableCoverPreprocess: Bool = false
    public private(set) var processMaxConcurrentOperationCount: Int = 1

    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else {
            return nil
        }
        if let maxProccessCount = config["maxProccessCount"] as? Int {
            self.maxProccessCount = maxProccessCount
        }
        if let enablePreProccess = config["enablePreProccess"] as? Bool {
            self.enablePreProccess = enablePreProccess
        }
        if let maxMemory = config["maxMemory"] as? Int {
            self.maxMemory = maxMemory
        }
        if let enableCoverPreprocess = config["enableCoverPreprocess"] as? Bool {
            self.enableCoverPreprocess = enableCoverPreprocess
        }
        if let processMaxConcurrentOperationCount = config["processMaxConcurrentOperationCount"] as? Int {
            self.processMaxConcurrentOperationCount = processMaxConcurrentOperationCount
        }
    }

    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let configString = fieldGroups[Self.key] as? String,
              let config = configString.toDictionary() else {
            return nil
        }
        self.init(config: config)
    }
}

/// 大 GIF 不自动播放配置
public struct GIFLoadConfig {
    public static let key = "gif_load_config"
    /// 文件大小超过此值，不自动播放
    public private(set) var size: Int = 0
    /// GIF 宽高乘积超过此阈值，不自动播放
    public private(set) var width: Int = 0
    /// GIF 宽高乘积超过此阈值，不自动播放
    public private(set) var height: Int = 0

    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config,
              let height = config["height"] as? Int,
              let width = config["width"] as? Int,
              let size = config["size"] as? Int,
              height * width > 0,
              size > 0
        else {
            return nil
        }
        self.size = size
        self.height = height
        self.width = width
    }
    public init?(filedGroups: [String: Any]?) {
        guard let filedGroups = filedGroups,
              let configString = filedGroups[Self.key] as? String,
              let config = configString.toDictionary() else {
            return nil
        }
        self.init(config: config)
    }
}

/// "原图"模式下，视频转码策略
public struct OriginVideoCompressConfig {
    public static let key: String = "video_origin_type"
    /// 宽边分辨率基线
    public private(set) var maxVideoSizeWidth: Int = 1080
    /// 窄边分辨率基线
    public private(set) var maxVideoSizeNarrow: Int = 720
    /// 动态码率压缩比
    public private(set) var bitrateCompressScale: Int = 80

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[OriginVideoCompressConfig.key], !value.isEmpty else { return nil }
        guard let data = value.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Int] else { return nil }

        guard let width = jsonDict["bigSideBaseNum"], let narrow = jsonDict["smallSideBaseNum"], let scale = jsonDict["bitRateCompressRatio"] else { return nil }

        self.maxVideoSizeWidth = width
        self.maxVideoSizeNarrow = narrow
        self.bitrateCompressScale = scale
    }
}

/// 非"原图"模式下，视频转码策略
public struct VideoCompressConfig {
    /// 最大帧率
    public private(set) var maxRate: Int = 30
    /// 大小小于此值&&MP4&&H264时不处理
    public private(set) var skipProcessFileSize: Int = 10
    /// 时长大于等于多少算长视频，单位秒
    public private(set) var longVideoDuration: Int = 120

    /// 短视频配置
    public private(set) var short = SubCompressConfig()
    /// 长视频配置
    public private(set) var long = SubCompressConfig()

    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else { return nil }

        func intValue(_ key: String) -> Int? {
            return config[key] as? Int
        }
        func subConfigValue(_ key: String) -> SubCompressConfig? {
            return SubCompressConfig(config: config[key] as? [String: Any])
        }

        // 当所有的属性都下发&&值符合预期时才进行赋值；
        // 这里特意不使用一次转成object的方法，因无法确定object中所有的属性都符合预期。
        guard let spfs = intValue("skip_process_file_size"), let mr = intValue("max_rate"),
              let lvd = intValue("long_video_duration"), let short = subConfigValue("short"),
              let long = subConfigValue("long") else { return nil }

        // 赋值
        self.maxRate = mr
        self.skipProcessFileSize = spfs
        self.longVideoDuration = lvd
        self.short = short
        self.long = long
    }
}

/// 字节云平台配置的messenger_video_compress
public struct MessengerVideoCompress {
    public static let key = "messenger_video_compress"

    /// wifi环境转码配置
    public private(set) var wifiConfig = VideoCompressConfig()
    /// 4g环境转码配置
    public private(set) var wlan4gConfig = VideoCompressConfig()
    /// 3g环境转码配置
    public private(set) var wlan3gConfig = VideoCompressConfig()
    /// 2g环境转码配置
    public private(set) var wlan2gConfig = VideoCompressConfig()
    /// offline环境转码配置
    public private(set) var offlineConfig = VideoCompressConfig()

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let videoCompress = fieldGroups[MessengerVideoCompress.key] else { return nil }
        guard let data = videoCompress.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else { return nil }

        self.wifiConfig = VideoCompressConfig(config: jsonDict["wifi"]) ?? self.wifiConfig
        self.wlan4gConfig = VideoCompressConfig(config: jsonDict["4g"]) ?? self.wlan4gConfig
        self.wlan3gConfig = VideoCompressConfig(config: jsonDict["3g"]) ?? self.wlan3gConfig
        self.wlan2gConfig = VideoCompressConfig(config: jsonDict["2g"]) ?? self.wlan2gConfig
        self.offlineConfig = VideoCompressConfig(config: jsonDict["offline"]) ?? self.offlineConfig
    }
}

/// 视频发送综合配置
public struct VideoSynthesisSetting {

    static let logger = Logger.log(VideoSynthesisSetting.self, category: "VideoSynthesisSetting")

    public static let key: String = "ve_synthesis_settings"
    /// 视频发送相关配置
    public private(set) var sendSetting: VideoSendSetting = VideoSendSetting()
    /// 视频压缩配置，目前没地方使用，已经替换为newCompressSetting
    private var compressSetting: VideoCompressSetting = VideoCompressSetting()
    /// 视频 ve 透传配置
    public private(set) var veSetting: VideoEditorSetting = VideoEditorSetting()
    /// 封面图配置
    public private(set) var coverSetting: CoverImageSetting = CoverImageSetting()
    /// 新版本视频压缩配置
    public private(set) var newCompressSetting: VideoCompressNewSetting = VideoCompressNewSetting()

    public init() {}

    public init?(fieldGroups: [String: String], abConfig: [String: [String: Any]]?) {
        guard let videoSynthesisSetting = fieldGroups[VideoSynthesisSetting.key] else { return nil }
        guard let data = videoSynthesisSetting.data(using: .utf8) else { return nil }
        guard var jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] else { return nil }

        func mergeDictionary(dic1: [String: Any], dic2: [String: Any]) -> [String: Any] {
            return dic1.merging(dic2) { value1, value2 in
                var result = value1
                if let oldDic = value1 as? [String: Any],
                   let newDic = value2 as? [String: Any] {
                    result = mergeDictionary(dic1: oldDic, dic2: newDic)
                } else {
                    result = value2
                }
                return result
            }
        }
        // 合并 ab 与 setting
        if let abConfig = abConfig,
            let newSetting = mergeDictionary(dic1: jsonDict, dic2: abConfig) as? [String: [String: Any]] {
            VideoSynthesisSetting.logger.info("get new abConfig \(abConfig) result \(newSetting)")
            jsonDict = newSetting
        }

        self.sendSetting = VideoSendSetting(config: jsonDict[VideoSendSetting.key])
        self.compressSetting = VideoCompressSetting(config: jsonDict[VideoCompressSetting.key])
        self.veSetting = VideoEditorSetting(config: jsonDict[VideoEditorSetting.key])
        self.coverSetting = CoverImageSetting(config: jsonDict[CoverImageSetting.key])
        self.newCompressSetting = VideoCompressNewSetting(config: jsonDict[VideoCompressNewSetting.key])
    }
}

/// 视频发送配置
public struct VideoSendSetting {
    public static let key: String = "send"

    /// 单位：字节，超出将按照文件发送
    public private(set) var fileSize: Int64 = 5 * 1024 * 1024 * 1024
    /// 单位：秒，超出将按照文件发送
    public private(set) var duration: Double = 5 * 60
    /// 分辨率，超出将按照文件发送
    public private(set) var resolution = VideoResolution()
    /// 帧率，超出将按照文件发送
    public private(set) var frameRate: CGFloat = 120
    /// 单位：bps，码率，超出将按照文件发送
    public private(set) var bitrate: CGFloat = 30 * 1024 * 1024
    /// 首帧，调整数据跳过首屏黑帧
    public private(set) var firstFrame = VideoFirstFrame()
    /// 边压边传缓存大小
    public private(set) var chunkBufferSize: Int64 = 100_000
    /// 视频解析失败时按照文件发送
    public private(set) var sendFileEnable: Bool = true
    /// 150*1024*1024,  剩余空间不可小于150MB
    public var limitDiskFreeSize: CGFloat = 150 * 1024 * 1024
    /// 剩余空间不可小于原视频的x倍
    public var limitDiskFreeMultiple: CGFloat = 3
    /// 发送多视频时，剩余空间不可小于多视频总大小 + x 倍最大视频大小
    public var limitDiskFreeMaxFactor: Double = 2

    public init(config: [String: Any]? = nil) {
        if let fileSize = config?["limit_file_size"] as? Int64 {
            self.fileSize = fileSize
        }
        if let duration = config?["limit_video_duration"] as? Double {
            self.duration = duration
        }
        if let resolution = VideoResolution(config: config?["limit_video_resolution"] ?? "") {
            self.resolution = resolution
        }
        if let firstFrame = VideoFirstFrame(config: config?["first_frame"] ?? "") {
            self.firstFrame = firstFrame
        }
        if let frameRate = config?["limit_video_frame_rate"] as? CGFloat {
            self.frameRate = frameRate
        }
        if let bitrate = config?["limit_video_bitrate"] as? CGFloat {
            self.bitrate = bitrate
        }
        if let chunkBufferSize = config?["chunk_buffer_size"] as? Int64 {
            self.chunkBufferSize = chunkBufferSize
        }
        if let sendFileEnable = config?["send_file_enable"] as? Int64 {
            self.sendFileEnable = sendFileEnable == 1
        }

        if let limit_disk = config?["limit_disk"] as? [String: Any] {
            if let limitDiskFreeSize = limit_disk["free_size"] as? CGFloat {
                self.limitDiskFreeSize = limitDiskFreeSize
            }
            if let limitDiskFreeMultiple = limit_disk["free_multiple"] as? CGFloat {
                self.limitDiskFreeMultiple = limitDiskFreeMultiple
            }
            if let limitDiskFreeMaxFactor = limit_disk["free_max_factor"] as? Double {
                self.limitDiskFreeMaxFactor = limitDiskFreeMaxFactor
            }
        }
    }
}

public struct VideoTranscodeConfig {
    public var bigSideMax: Int // 视频宽边最大值
    public var smallSideMax: Int // 视频窄边最大值
    public var fpsMax: Int // 最大 fps
    public var bitrateSetting: String // VESDK 透传配置
    public var remuxResolutionSetting: Int32 // 转封装分辨率限制
    public var remuxFPSSetting: Int32 // 转封装 fps 限制
    public var remuxBitratelimitSetting: String // 转封装码率限制
    public var isForceReencode: Bool // 是否是强制转码

    public init(
        bigSideMax: Int,
        smallSideMax: Int,
        fpsMax: Int,
        bitrateSetting: String,
        remuxResolutionSetting: Int32,
        remuxFPSSetting: Int32,
        remuxBitratelimitSetting: String,
        isForceReencode: Bool
    ) {
        self.bigSideMax = bigSideMax
        self.smallSideMax = smallSideMax
        self.fpsMax = fpsMax
        self.bitrateSetting = bitrateSetting
        self.remuxFPSSetting = remuxFPSSetting
        self.remuxResolutionSetting = remuxResolutionSetting
        self.remuxBitratelimitSetting = remuxBitratelimitSetting
        self.isForceReencode = isForceReencode
    }
}

/// 视频预处理配置
public struct VideoPreprocessConfig {
    public static let key = "video_pre_process"

    /// 预处理筛选条件
    public struct Filter {
        static let key = "filter"

        /// 从相册中筛选前几个media
        public private(set) var mediaCount: Int = 10
        /// 从前几个media中筛选前几个video
        public private(set) var videoCount: Int = 3
        /// 触发预测压缩时间间隔，单位 s，采用 pct75 数据
        public private(set) var interval: TimeInterval = 900

        init(config: [String: Any]? = nil) {
            if let mediaCount = config?["media_count"] as? Int {
                self.mediaCount = mediaCount
            }
            if let videoCount = config?["video_count"] as? Int {
                self.videoCount = videoCount
            }
            if let interval = config?["interval"] as? TimeInterval {
                self.interval = interval
            }
        }
    }

    /// 预压缩
    public struct Compress {
        static let key = "compress"

        /// 预压缩开关
        public struct Switch {
            static let key = "switch"

            /// 选中预压缩（一期）
            public private(set) var selectVideoEnable = true
            /// 打开相册时预压缩（二期）
            public private(set) var openAlbumEnable = true
            /// 系统分享预压缩（三期）
            public private(set) var shareFromSystemEnable = true
            /// 相册预览预压缩（三期）
            public private(set) var previewVideoEnable = true

            init(config: [String: Any]? = nil) {
                if let selectVideoEnable = config?["select_video_enable"] as? Int {
                    self.selectVideoEnable = selectVideoEnable == 1
                }
                if let openAlbumEnable = config?["open_album_enable"] as? Int {
                    self.openAlbumEnable = openAlbumEnable == 1
                }
                if let shareFromSystemEnable = config?["share_from_system_enable"] as? Int {
                    self.shareFromSystemEnable = shareFromSystemEnable == 1
                }
                if let previewVideoEnable = config?["preview_video_enable"] as? Int {
                    self.previewVideoEnable = previewVideoEnable == 1
                }
            }
        }

        /// 预压缩大小限制
        public struct Limit {
            static let key = "limit"

            /// 预压缩大小阈值(Byte)
            public private(set) var fileSize: Int = 5 * 1024 * 1024 * 1024
            /// 预压缩时长阈值(S)
            public private(set) var videoDuration: Int = 5 * 60
            /// cpu使用上限
            public private(set) var cpuUsage: Float = 80
            /// 倍数下限（磁盘空间➗原始视频）
            public private(set) var diskSpaceFreeCount: Double = 5
            /// 剩余容量下限（MB）
            public private(set) var diskSpaceFreeSize: Int = 500 * 1024 * 1024

            init(config: [String: Any]? = nil) {
                if let fileSize = config?["file_size"] as? Int {
                    self.fileSize = fileSize
                }
                if let videoDuration = config?["video_duration"] as? Int {
                    self.videoDuration = videoDuration
                }
                if let cpuUsage = config?["cpu_usage"] as? Float {
                    self.cpuUsage = cpuUsage
                }
                if let diskSpaceFreeCount = config?["disk_space_free_count"] as? Double {
                    self.diskSpaceFreeCount = diskSpaceFreeCount
                }
                if let diskSpaceFreeSize = config?["disk_space_free_size"] as? Int {
                    self.diskSpaceFreeSize = diskSpaceFreeSize
                }
            }
        }

        public private(set) var compressSwitch = Switch()
        public private(set) var limit = Limit()

        init(config: [String: Any]? = nil) {
            if let switchConfig = config?[Switch.key] as? [String: Any] {
                self.compressSwitch = Switch(config: switchConfig)
            }
            if let limitConfig = config?[Limit.key] as? [String: Any] {
                self.limit = Limit(config: limitConfig)
            }
        }
    }

    /// 透传
    public struct Raw {
        static let key = "raw"

        public struct Limit {
            /// 视频大小限制, 单位 字节
            public private(set) var fileSize = 60 * 1024 * 1024
            /// 视频码率限制, 单位 bps
            public private(set) var videoBitrate: CGFloat = 3 * 1024 * 1024
            /// 视频分辨率宽阈值
            public private(set) var videoWidth: CGFloat = 2160
            /// 视频分辨率高阈值
            public private(set) var videoHeight: CGFloat = 3840

            init(config: [String: Any]? = nil) {
                if let fileSize = config?["file_size"] as? Int {
                    self.fileSize = fileSize
                }
                if let videoBitrate = config?["video_bitrate"] as? CGFloat {
                    self.videoBitrate = videoBitrate
                }
                if let videoWidth = config?["video_width"] as? CGFloat {
                    self.videoWidth = videoWidth
                }
                if let videoHeight = config?["video_height"] as? CGFloat {
                    self.videoHeight = videoHeight
                }
            }
        }

        /// 是否开启检测，0 关闭 1 开启
        public private(set) var enable = false
        /// 一次最多检测个数
        public private(set) var tps = 1
        /// cpu 使用值，根据不同系统设置不同参数
        public private(set) var cpuUsageLimit: Float = 80
        /// 原图限制
        public private(set) var originLimit = Limit()
        /// 非原图限制
        public private(set) var commonLimit = Limit()

        /// 交织diff阈值
        public private(set) var diffMax: UInt = 300_000

        init(config: [String: Any]? = nil) {
            if let enable = config?["enable"] as? Int {
                self.enable = enable == 1
            }
            if let tps = config?["tps"] as? Int {
                self.tps = tps
            }
            if let cpuUsageLimit = config?["cpu_usage_limit"] as? Float {
                self.cpuUsageLimit = cpuUsageLimit
            }
            if let originLimit = config?["origin_limit"] as? [String: Any] {
                self.originLimit = Limit(config: originLimit)
            }
            if let commonLimit = config?["common_limit"] as? [String: Any] {
                self.commonLimit = Limit(config: commonLimit)
            }
            if let diffMax = config?["diff_max"] as? UInt {
                self.diffMax = diffMax
            }
        }
    }

    public private(set) var filter = Filter()
    public private(set) var compress = Compress()
    public private(set) var raw = Raw()

    public init(config: [String: Any]? = nil) {
        if let filterConfig = config?[Filter.key] as? [String: Any] {
            self.filter = Filter(config: filterConfig)
        }
        if let compressConfig = config?[Compress.key] as? [String: Any] {
            self.compress = Compress(config: compressConfig)
        }
        if let rawConfig = config?[Raw.key] as? [String: Any] {
            self.raw = Raw(config: rawConfig)
        }
    }

    public init?(fieldGroups: [String: String]) {
        guard let videoPreprocessConfig = fieldGroups[VideoPreprocessConfig.key] else { return nil }
        guard let data = videoPreprocessConfig.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        self.init(config: jsonDict)
    }
}

public struct VideoCompressNewSetting {
    public static let key: String = "compress_new"

    // low_bitrate_max 低码率画质阈值
    public private(set) var lowBitrateMax: Int = 524_288

    /// 超时设置
    public private(set) var timeoutPeriod: Double = 6

    // 场景配置，低码率/弱网/原图等 -> high/middle/low等压缩配置
    public private(set) var scenes: [String: String] = [:]

    // 压缩配置，high/middle/low等 -> Config
    public private(set) var config: [String: VideoTranscodeConfig] = [:]

    /// 智能合成配置
    public private(set) var aiCodec: AICodecConfig = AICodecConfig()

    public struct AICodecConfig {
        /// 是否开启智能合成
        public private(set) var enable: Bool = true
        /// 是否开启弱网限制
        public private(set) var weakNetLimit: Bool = true
        /// 低端机限制
        public private(set) var lowDeviceLimit: Double = 10
        /// CPU 限制（百分比）
        public private(set) var cpuLimit: Int = 80
        /// 温度限制（ThermalState）
        public private(set) var thermalLimit: Int = 1
        /// 电池限制（百分比）
        public private(set) var batteryLimit: Int = 40

        init(config: [String: Any]? = nil) {
            if let enable = config?["enable"] as? Bool {
                self.enable = enable
            }
            if let weakNetLimit = config?["weakNetLimit"] as? Bool {
                self.weakNetLimit = weakNetLimit
            }
            if let lowDeviceLimit = config?["lowDeviceLimit"] as? Double {
                self.lowDeviceLimit = lowDeviceLimit
            }
            if let cpuLimit = config?["cpuLimit"] as? Int {
                self.cpuLimit = cpuLimit
            }
            if let thermalLimit = config?["thermalLimit"] as? Int {
                self.thermalLimit = thermalLimit
            }
            if let batteryLimit = config?["batteryLimit"] as? Int {
                self.batteryLimit = batteryLimit
            }
        }
    }

    public init(config: [String: Any]? = nil) {
        if let lowBitrateMax = config?["low_bitrate_max"] as? Int {
            self.lowBitrateMax = lowBitrateMax
        }
        if let timeoutPeriod = config?["timeoutPeriod"] as? Double {
            self.timeoutPeriod = timeoutPeriod
        }
        if let scenes = config?["scene"] as? [String: String] {
            self.scenes = scenes
        }
        if let quality = config?["quality"] as? [[String: Any]] {
            for config in quality {
                if let key = config["level"] as? String {
                    guard let bigSideMax = config["big_side_max"] as? Int,
                        let smallSideMax = config["small_side_max"] as? Int,
                        let fpsMax = config["fps_max"] as? Int,
                        let bitrateSetting = config["external_setting"] as? String,
                        let remuxSetting = config["remux_setting"] as? [String: Any],
                        let remuxBigSideMax = remuxSetting["big_side_max"] as? Int32,
                        let remuxSmallSideMax = remuxSetting["small_side_max"] as? Int32,
                        let remuxFPS = remuxSetting["fps_max"] as? Int32,
                        let remuxBitrate = remuxSetting["bitrate_max"] as? String else {
                        continue
                    }
                    self.config[key] = VideoTranscodeConfig(
                        bigSideMax: bigSideMax,
                        smallSideMax: smallSideMax,
                        fpsMax: fpsMax,
                        bitrateSetting: bitrateSetting,
                        remuxResolutionSetting: remuxBigSideMax * remuxSmallSideMax,
                        remuxFPSSetting: remuxFPS,
                        remuxBitratelimitSetting: remuxBitrate,
                        isForceReencode: false
                    )
                }
            }
        }
        if let aiCodec = config?["aiCodec"] as? [String: Any] {
            self.aiCodec = AICodecConfig(config: aiCodec)
        }
    }
}

/// 视频压缩配置
public struct VideoCompressSetting {
    public static let key: String = "compress"

//    origin_big_side_max: 1080, # 原图模式宽边阈值
    public private(set) var originBigSideMax: Int = 1080
//    origin_small_side_max: 720, # 原图模式窄边阈值
    public private(set) var originSmallSideMax: Int = 720
//    origin_max_FPS: 30, # 原图模式帧率阈值
    public private(set) var originMaxFPS: Int = 30
//    common_big_side_max: 960, # 非原图模式宽边阈值
    public private(set) var commonBigSideMax: Int = 960
//    common_small_side_max: 540, # 非原图模式窄边阈值
    public private(set) var commonSmallSideMax: Int = 540
//    common_max_FPS: 30 # 非原图模式帧率阈值
    public private(set) var commonMaxFPS: Int = 30
//    common_big_side_max: 960, # 非原图模式宽边阈值
    public private(set) var weakBigSideMax: Int = 960
//    common_small_side_max: 540, # 非原图模式窄边阈值
    public private(set) var weakSmallSideMax: Int = 540
//    common_max_FPS: 30 # 非原图模式帧率阈值
    public private(set) var weakMaxFPS: Int = 30

    public init(config: [String: Any]? = nil) {
        if let originBigSideMax = config?["origin_big_side_max"] as? Int {
            self.originBigSideMax = originBigSideMax
        }
        if let originSmallSideMax = config?["origin_small_side_max"] as? Int {
            self.originSmallSideMax = originSmallSideMax
        }
        if let originMaxFPS = config?["origin_max_FPS"] as? Int {
            self.originMaxFPS = originMaxFPS
        }
        if let commonBigSideMax = config?["common_big_side_max"] as? Int {
            self.commonBigSideMax = commonBigSideMax
        }
        if let commonSmallSideMax = config?["common_small_side_max"] as? Int {
            self.commonSmallSideMax = commonSmallSideMax
        }
        if let commonMaxFPS = config?["common_max_FPS"] as? Int {
            self.commonMaxFPS = commonMaxFPS
        }
        if let weakBigSideMax = config?["weak_big_side_max"] as? Int {
            self.weakBigSideMax = weakBigSideMax
        }
        if let weakSmallSideMax = config?["weak_small_side_max"] as? Int {
            self.weakSmallSideMax = weakSmallSideMax
        }
        if let weakMaxFPS = config?["weak_max_FPS"] as? Int {
            self.weakMaxFPS = weakMaxFPS
        }
    }
}

/// 视频 ve 透传配置，private的都没地方使用
public struct VideoEditorSetting {
    public static let key: String = "ve"
    // "remux_max_file_size" 转封装最大文件阈值
    public private(set) var remuxMaxFileSize: Float64 = 150 * 1024 * 1024
    //"internal_setting" ve码率相关透传配置（支持慢速视频发送）
    public private(set) var internalSetting: [String: Any] = [:]
    // "enable_mux_rotation" 是否支持带有旋转信息的视频后台转码
    public private(set) var enableMuxRotation: Int32 = 0

    //"remux_setting" ve转封装相关透传配置
    private var originRemuxResolutionSetting: Float = 720 * 1280
    private var remuxResolutionSetting: Float = 540 * 960
    private var weakRemuxResolutionSetting: Float = 540 * 960
    private var originRemuxFPSSetting: Int32 = 60
    private var remuxFPSSetting: Int32 = 60
    private var weakRemuxFPSSetting: Int32 = 60
    // swiftlint:disable line_length
    private var originRemuxBitratelimitSetting: String = "{\"setting_values\":{\"normal_bitratelimit\": 3145728,\"hd_bitratelimit\":3145728}}"
    private var remuxBitratelimitSetting: String = "{\"setting_values\":{\"normal_bitratelimit\": 1258291,\"hd_bitratelimit\":1258291}}"
    private var weakRemuxBitratelimitSetting: String = "{\"setting_values\":{\"normal_bitratelimit\": 1258291,\"hd_bitratelimit\":1258291}}"
    //"external_setting" ve码率相关透传配置
    private var externalSetting: String = "{\"compile\":{\"encode_mode\":\"hw\",\"hw\":{\"bitrate\":3145728,\"sd_bitrate_ratio\":0.4,\"full_hd_bitrate_ratio\":1.5,\"hevc_bitrate_ratio\":1,\"h_fps_bitrate_ratio\":1.4,\"effect_bitrate_ratio\":1.4,\"fps\":30,\"audio_bitrate\":128000}}}"
    private var externalWeakSetting: String = "{\"compile\":{\"encode_mode\":\"hw\",\"hw\":{\"bitrate\":3145728,\"sd_bitrate_ratio\":0.4,\"full_hd_bitrate_ratio\":1.5,\"hevc_bitrate_ratio\":1,\"h_fps_bitrate_ratio\":1.4,\"effect_bitrate_ratio\":1.4,\"fps\":30,\"audio_bitrate\":128000}}}"
    // swiftlint:enable line_length

    public init(config: [String: Any]? = nil) {
        if let remuxMaxFileSize = config?["remux_max_file_size"] as? Float64 {
            self.remuxMaxFileSize = remuxMaxFileSize
        }
        if let remuxSetting = config?["remux_setting"] as? [String: Any] {
            if let remuxResolutionSetting = remuxSetting["origin_resolution"] as? Float {
                self.originRemuxResolutionSetting = remuxResolutionSetting
            }
            if let remuxFPSSetting = remuxSetting["origin_fps"] as? Int32 {
                self.originRemuxFPSSetting = remuxFPSSetting
            }
            if let remuxBitratelimitSetting = remuxSetting["origin_bitratelimit"] as? String {
                self.originRemuxBitratelimitSetting = remuxBitratelimitSetting
            }
            if let remuxResolutionSetting = remuxSetting["common_resolution"] as? Float {
                self.remuxResolutionSetting = remuxResolutionSetting
            }
            if let remuxFPSSetting = remuxSetting["common_fps"] as? Int32 {
                self.remuxFPSSetting = remuxFPSSetting
            }
            if let remuxBitratelimitSetting = remuxSetting["common_bitratelimit"] as? String {
                self.remuxBitratelimitSetting = remuxBitratelimitSetting
            }
            if let weakRemuxResolutionSetting = remuxSetting["weak_resolution"] as? Float {
                self.weakRemuxResolutionSetting = weakRemuxResolutionSetting
            }
            if let weakRemuxFPSSetting = remuxSetting["weak_fps"] as? Int32 {
                self.weakRemuxFPSSetting = weakRemuxFPSSetting
            }
            if let weakRemuxBitratelimitSetting = remuxSetting["weak_bitratelimit"] as? String {
                self.weakRemuxBitratelimitSetting = weakRemuxBitratelimitSetting
            }
        }

        if let externalSetting = config?["external_setting"] as? String {
            self.externalSetting = externalSetting
        }

        if let externalWeakSetting = config?["external_weak_setting"] as? String {
            self.externalWeakSetting = externalWeakSetting
        }

        if let internalSetting = config?["internal_setting"] as? [String: Any] {
            self.internalSetting = internalSetting
        }

        if let enableMuxRotation = config?["enable_mux_rotation"] as? Int32 {
            self.enableMuxRotation = enableMuxRotation
        }
    }
}

public struct CoverImageSetting {
    public static let key: String = "cover"

    private var concurrenceUploadEnable: Bool = false // 是否并行上传封面图，没地方使用
    public var limitEnable: Bool = false // 是否开启封面图的限制
    public var limitQuality: Float = 0.75 // 是否开启封面图的限制
    public var limitBigSideMax: Float = 640 // 分辨率大边阈值
    public var limitSmallSideMax: Float = 640 // 分辨率大边阈值

    public init(config: [String: Any]? = nil) {
        if let concurrenceUploadEnable = config?["concurrence_upload_enable"] as? Int {
            self.concurrenceUploadEnable = concurrenceUploadEnable == 1
        }
        if let coverFileLimit = config?["cover_file_limit"] as? [String: Any] {
            if let limitEnable = coverFileLimit["limit_enable"] as? Int {
                self.limitEnable = limitEnable == 1
            }
            if let limitQuality = coverFileLimit["limit_quality"] as? Float {
                self.limitQuality = Float(limitQuality) / 100
            }
            if let limitBigSideMax = coverFileLimit["limit_big_side_max"] as? Float {
                self.limitBigSideMax = limitBigSideMax
            }
            if let limitSmallSideMax = coverFileLimit["limit_small_side_max"] as? Float {
                self.limitSmallSideMax = limitSmallSideMax
            }
        }
    }
}

public struct GroupConfig {
    public static let key = "group_config"
    private let analysisHeartbeatIntervalKey = "analysis_heartbeat_interval"
    public private(set) var analysisHeartbeatInterval: Int = 2000

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let helpdeskCommon = fieldGroups[GroupConfig.key] else { return nil }
        guard let data = helpdeskCommon.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
        guard let interval = jsonDict[analysisHeartbeatIntervalKey] as? Int else { return nil }
        self.analysisHeartbeatInterval = interval
    }
}

/// UG 相关的字节云平台配置项
public struct  UserGrowthConfig {
    static let logger = Logger.log(UserGrowthConfig.self, category: "OnboardingConfig")
    public static let key = "invite_member_channel_adjust"

    public var configValue = true

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[UserGrowthConfig.key] else {
            UserGrowthConfig.logger.info("exp key `\(UserGrowthConfig.key)` not exist")
            return
        }
        guard let configValue = Bool(value) else {
            UserGrowthConfig.logger.info("exp value with `\(UserGrowthConfig.key)` is invalid")
            return
        }
        UserGrowthConfig.logger.info("exp value with `\(UserGrowthConfig.key)` is \(configValue)")
        self.configValue = configValue
    }
}

public struct DominManagePolicyConfig {
    static let logger = Logger.log(DominManagePolicyConfig.self, category: "dominManagePolicyConfig")
    public static let key = "domain_manage_policy"
    private let secLinkWhitelistKey = "sec_link_whitelist"
    public private(set) var secLinkWhitelist: [String] = []
    /// 将命中白名单内host正则逻辑的url视为安全地址，允许其调用安全相关的API.
    /// 详见https://bytedance.feishu.cn/docs/doccnLZ23fjsCdopsxu3degsPQd
    private let jsAPIHostTrustListKey = "js_api_host_trust_list"
    public private(set) var jsAPIHostTrustList: [String] = []

    public init() {}

    public init?(fieldGroups: [String: String]) {
        let value = fieldGroups[DominManagePolicyConfig.key]
        guard let value else {
            DominManagePolicyConfig.logger.info("no domain_manage_policy key")
            return nil
        }
        guard let data = value.data(using: .utf8) else {
            DominManagePolicyConfig.logger.error("invalid domain_manage_policy data")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            DominManagePolicyConfig.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        guard let secLinkWhitelist = jsonDict[secLinkWhitelistKey] as? [String] else {
            DominManagePolicyConfig.logger.error("cannot convert to valid secLinkWhitelist")
            return nil
        }
        self.secLinkWhitelist = secLinkWhitelist
        if let jsAPIHostTrustList = jsonDict[jsAPIHostTrustListKey] as? [String] {
            self.jsAPIHostTrustList = jsAPIHostTrustList
        }
    }
}

public struct HelpCenterBizDomainConfig {
    static let logger = Logger.log(HelpCenterBizDomainConfig.self, category: "BizDomainConfig")
    public static let key = "biz_domain_config"
    private let helpCenterKey = "help_center"
    public private(set) var helpCenterHost = ""

    public init() {}

    public init?(fieldGroups: [String: String]) {
        let value = fieldGroups[HelpCenterBizDomainConfig.key]
        guard let value else {
            DominManagePolicyConfig.logger.info("no domain_manage_policy key")
            return nil
        }
        guard let data = value.data(using: .utf8) else {
            DominManagePolicyConfig.logger.error("invalid domain_manage_policy data")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            DominManagePolicyConfig.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        guard let host = jsonDict[helpCenterKey] as? [String] else {
            DominManagePolicyConfig.logger.error("cannot convert to valid host")
            return nil
        }
        self.helpCenterHost = host.first ?? ""
    }
}

public struct SettingV3WebTranslateConfig {
    static let logger = Logger.log(SettingV3WebTranslateConfig.self, category: "WebTranslateConfig")
    public static let key = "web_translate_config"
    private let sampleTextMaxContentLengthKey = "sample_text_max_content_length"
    public private(set) var sampleTextMaxContentLength: Int?

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[SettingV3WebTranslateConfig.key] else {
            SettingV3WebTranslateConfig.logger.info("no web_translate_config key")
            return nil
        }
        guard let data = value.data(using: .utf8) else {
            SettingV3WebTranslateConfig.logger.error("invalid domain_manage_policy data")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            SettingV3WebTranslateConfig.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        guard let sampleTextMaxContentLength = jsonDict[sampleTextMaxContentLengthKey] as? Int else {
            SettingV3WebTranslateConfig.logger.error("cannot convert to valid sampleTextMaxContentLength")
            return nil
        }
        self.sampleTextMaxContentLength = sampleTextMaxContentLength
    }
}

/// UG 相关的字节云平台配置项 https://data.bytedance.net/libra/flight/349431/edit
public struct GadgetEngineConfig {
    static let logger = Logger.log(GadgetEngineConfig.self,
                                   category: "gadgetEnginePreloadConfig")
    private let enablePreloadKey = "use"
    static public let key = "preload"
    public private(set) var enablePreload: Bool = true
    public private(set) var preloadInfo: [String: Any] = [:]

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[GadgetEngineConfig.key] else {
            GadgetEngineConfig.logger.info("no key: \(GadgetEngineConfig.key)")
            return nil
        }
        guard let data = value.data(using: .utf8) else {
            GadgetEngineConfig.logger.error("invalid config data key: \(GadgetEngineConfig.key)")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            GadgetEngineConfig.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        self.preloadInfo = jsonDict
        guard let enablePreloadFlag = jsonDict[enablePreloadKey] as? Int else {
            GadgetEngineConfig.logger.error("cannot read use flag")
            return nil
        }
        self.enablePreload = (enablePreloadFlag == 1)
    }
}

/// 是否启动BGTask 字节云平台配置项 https://cloud.bytedance.net/appSettings/config/119829/detail
public struct BGTaskConfig {
    public static let key = "bgtask_enable"
    /// BGTask可用时取值
    public static let enable = "enable"
    /// 兜底值为disable，不开启BGTask
    public private(set) var value: String = ""

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[BGTaskConfig.key], !value.isEmpty else { return nil }
        self.value = value
    }
}

/// 用户投放source配置列表
public struct UGBannerConfig {
    static let logger = Logger.log(UGBannerConfig.self, category: "UGBannerConfig")
    public static let key = "ug_banner_config"
    private let supportSourceKey = "support_source"
    public private(set) var sourceList: [String] = []

    public init() {}

    public init?(fieldGroups: [String: String]) {
        let value = fieldGroups[UGBannerConfig.key]
        guard let value else {
            UGBannerConfig.logger.info("no support_source key")
            return nil
        }
        guard let data = value.data(using: .utf8) else {
            UGBannerConfig.logger.error("invalid support_source data")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            UGBannerConfig.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        guard let sourceList = jsonDict[supportSourceKey] as? [String] else {
            UGBannerConfig.logger.error("cannot convert to valid sourceList")
            return nil
        }
        self.sourceList = sourceList
    }
}

/// Onboarding spotlight 文案相关配置
public struct SpotlightWorkspaceConfig {
    // TODO: temporary
    public static let key = "spotlight_workplace"

    public private(set) var value: String = ""

    static let logger = Logger.log(SpotlightWorkspaceConfig.self, category: "SpotlightWorkspaceConfig")

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[SpotlightWorkspaceConfig.key],
              !value.isEmpty else {
            SpotlightWorkspaceConfig.logger.info("no spotlight workspace config value")
            return nil
        }
        self.value = value
    }
}

/// OPMonitor 相关的字节云平台配置项 https://cloud.bytedance.net/appSettings/config/134428/detail/basic
public struct OPMonitorConfig {
    static let logger = Logger.log(OPMonitorConfig.self, category: "OPMonitorConfig")
    static public let key = "op_monitor"
    public private(set) var config: [String: Any] = [:]

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[OPMonitorConfig.key] else {
            OPMonitorConfig.logger.info("no key: \(OPMonitorConfig.key)")
            return nil
        }
        guard let data = value.data(using: .utf8) else {
            OPMonitorConfig.logger.error("invalid config data key: \(OPMonitorConfig.key)")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            OPMonitorConfig.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        self.config = jsonDict
    }
}

/// 字节云平台配置的 contacts_config, https://cloud.bytedance.net/appSettings/config/128436/detail/status
public struct ContactsConfig {
    static let logger = Logger.log(ContactsConfig.self, category: "ContactsConfig")
    public static let key = "contacts_config"
    public var maxUnauthExternalContactsSelectNumber: Int = 50
    public var contactOrganizeDepartmentAdminURL = ""

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let contactsConfig = fieldGroups[ContactsConfig.key] else {
            Self.logger.info("no contacts_config key")
            return nil
        }
        guard let data = contactsConfig.data(using: .utf8) else {
            Self.logger.error("invalid contacts_config data")
            return nil
        }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            Self.logger.error("cannot convert to valid json dictionary")
            return nil
        }
        guard let maxNum = jsonDict["max_unauth_external_contacts_select_number"] as? Int else {
            Self.logger.error("cannot convert to valid maxNum")
            return nil
        }
        guard let adminURL = jsonDict["contact_organize_department_adminURL"] as? String else {
            Self.logger.error("cannot convert to valid adminURL")
            return nil
        }

        self.maxUnauthExternalContactsSelectNumber = maxNum
        self.contactOrganizeDepartmentAdminURL = adminURL
    }
}

//推送降级端上资源监测策略配置
public struct PushDowngradeAppLagConfig {
    private static let logger = Logger.log(PushDowngradeAppLagConfig.self, category: "PushDowngradeAppLagConfig")

    public static let key = "ios_push_downgrade_app_lag_config"
    public let slightly: Int
    public let moderately: Int
    public let severely: Int
    public let fatally: Int

    public init?(fieldGroups: [String: String]) {
        guard let configs = fieldGroups[Self.key] else {
            Self.logger.info("no key")
            return nil
        }
        guard let data = configs.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
        Self.logger.info("\(jsonDict)")
        guard let config = jsonDict["ios_push_downgrade_app_lag_config"] as? [String: Any] else { return nil }
        guard let cpuStrategy = config["cpu"] as? [String: Any] else { return nil }
        guard let slightly = cpuStrategy["slightly"] as? Int else { return nil }
        guard let moderately = cpuStrategy["moderately"] as? Int else { return nil }
        guard let severely = cpuStrategy["severely"] as? Int else { return nil }
        guard let fatally = cpuStrategy["fatally"] as? Int else { return nil }

        self.slightly = slightly
        self.moderately = moderately
        self.severely = severely
        self.fatally = fatally
    }
}

// 会话页面是否启用新的防截（录）屏配置
public struct ChatSecureViewEnableConfig {
    public static let key = "ios_chat_secureview_enable_config"
    private static let logger = Logger.log(ChatSecureViewEnableConfig.self, category: "ChatSecureViewEnableConfig")
    public private(set) var versionRange: (min: String, max: String)
    public init?(fieldGroups: [String: String]) {
        guard let configs = fieldGroups[Self.key] else {
            Self.logger.info("no ios_chat_secureview_enable_config key")
            return nil
        }
        guard let data = configs.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
        guard let config = jsonDict[Self.key] as? [String: Any] else { return nil }
        Self.logger.info("\(config)")
        guard let minVersion = config["min_version"] as? String else { return nil }
        guard let maxVersion = config["max_version"] as? String else { return nil }
        self.versionRange = (min: minVersion, max: maxVersion)
    }
}

/// 可在线解压缩的文件类型配置
public struct MessengerFileConfig {
    private static let logger = Logger.log(MessengerFileConfig.self, category: "MessengerFileConfig")

    public static let key = "lark_messenger_file"
    public var timeoutSecond: Int = 30
    public var sizeUpperLimit: Int64 = 1_073_741_824
    public var format: [String] = ["zip", "rar"]

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let configs = fieldGroups[Self.key] else {
            Self.logger.info("no lark_messenger_file key")
            return nil
        }
        guard let data = configs.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }
        guard let extractPackage = jsonDict["extract_package"] as? [String: Any] else { return nil }
        guard let timeoutSecond = extractPackage["timeoutS"] as? Int else { return nil }
        guard let sizeUpperLimit = extractPackage["size_upper_limit"] as? Int64 else { return nil }
        guard let format = extractPackage["format"] as? [String] else { return nil }
        self.timeoutSecond = timeoutSecond
        self.sizeUpperLimit = sizeUpperLimit
        self.format = format
    }
}

/// 消息气泡折叠策略配置
/// Bubble folding height config.
/// https://cloud.bytedance.net/appSettings-v2/detail/config/163273/detail/basic
public struct MessageBubbleFoldConfig {
    public static let key = "message_content_folding_control_params"
    public let chatFoldedHeightFactor: CGFloat
    public let chatFoldingTriggerHeightFactor: CGFloat
    public let topicFoldedHeightFactor: CGFloat
    public let topicFoldingTriggerHeightFactor: CGFloat

    public init() {
        chatFoldedHeightFactor = 1.8
        chatFoldingTriggerHeightFactor = 2.5
        topicFoldedHeightFactor = 0.9
        topicFoldingTriggerHeightFactor = 0.9
    }

    public init?(fieldGroups: [String: String]) {
        guard let configs = fieldGroups[Self.key] else {
            return nil
        }
        guard let data = configs.data(using: .utf8) else { return nil }
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return nil }

        self.chatFoldedHeightFactor = jsonDict["chat_folded_height_factor"] as? CGFloat ?? 1.8
        self.chatFoldingTriggerHeightFactor = jsonDict["chat_folding_trigger_height_factor"] as? CGFloat ?? 2.5
        self.topicFoldedHeightFactor = jsonDict["topic_folded_height_factor"] as? CGFloat ?? 0.9
        self.topicFoldingTriggerHeightFactor = jsonDict["topic_folding_trigger_height_factor"] as? CGFloat ?? 0.9
    }
}

/// 群Tab添加引导网页链接
public struct ChatTabAddUGLinkConfig {
    public static let key = "chat_tab_add_ug_link"

    // TODO: 多语音适配
    public private(set) var zhLink: String = ""
    public private(set) var enLink: String = ""
    public private(set) var jaLink: String = ""

    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else {
            return nil
        }
        if let zhLink = config["zh"] as? String,
           let enLink = config["en"] as? String,
           let jaLink = config["ja"] as? String {
            self.zhLink = zhLink
            self.enLink = enLink
            self.jaLink = jaLink
        }
    }

    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let configString = fieldGroups[Self.key] as? String,
              let config = configString.toDictionary() else {
            return nil
        }
        self.init(config: config)
    }
}

/// 群置顶 onboarding 网页链接
public struct ChatPinOnboardingDetailLinkConfig {
    public static let key = "chat_pin_onboarding_detail_link"

    public private(set) var zhLink: String = ""
    public private(set) var enLink: String = ""
    public private(set) var jaLink: String = ""
    public private(set) var otherLink: String = ""

    public init() {}

    public init?(config: [String: Any]?) {
        guard let config = config else {
            return nil
        }
        if let zhLink = config["zh"] as? String,
           let enLink = config["en"] as? String,
           let jaLink = config["ja"] as? String,
           let otherLink = config["other"] as? String {
            self.zhLink = zhLink
            self.enLink = enLink
            self.jaLink = jaLink
            self.otherLink = otherLink
        }
    }

    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let configString = fieldGroups[Self.key] as? String,
              let config = configString.toDictionary() else {
            return nil
        }
        self.init(config: config)
    }
}

/// KA群成员排序隐藏管理员
public struct MemberListNonDepartmentConfig {
    public static let key = "member_list_non_department"

    public private(set) var showDepartment: Bool = true

    public init() {}

    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let hiddenDepartment = (fieldGroups[Self.key] as? NSString)?.boolValue else {
            return nil
        }
        self.showDepartment = !hiddenDepartment
    }
}

/// Messenger单测黑名单机制：https://cloud.bytedance.net/appSettings-v2/detail/config/166898/detail/whitelist-detail/90380
public struct SkipTestConfig {
    public static let key = "skip_test_config"

    /// 是否跳过所有case执行
    public private(set) var allCase: Bool = false
    /// 跳过指定case执行
    public private(set) var caseNames: [String] = [""]

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let config = fieldGroups[Self.key], let data = config.data(using: .utf8),
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let caseNames = jsonDict["case_names"] as? [String], let allCase = jsonDict["all_case"] as? Bool else {
            return nil
        }

        self.allCase = allCase
        self.caseNames = caseNames
    }
}

/// 文件发送大小限制：https://cloud.bytedance.net/appSettings-v2/detail/config/176120/detail/status
public struct FileUploadSizeLimit {
    public static let key = "im_file_upload_size_limit"

    /// 单个文件大小限制，单位：B，默认100GB
    public private(set) var maxSingleFileSize: Int = 100 * 1024 * 1024 * 1024
    /// 总文件大小限制，单位：B，默认100GB
    public let maxTotalFileSize: Int = 100 * 1024 * 1024 * 1024

    public init() {}

    public init?(fieldGroups: [String: String]) {
        guard let value = fieldGroups[Self.key] else { return nil }

        // settings下发的单位是MB，我们需要转化为B
        self.maxSingleFileSize = (value as NSString).integerValue * 1024 * 1024
        // 这里要处理转换失败的情况，恢复为100GB
        if self.maxSingleFileSize <= 0 { self.maxSingleFileSize = 100 * 1024 * 1024 * 1024 }
    }
}

/// 群接龙 url 的 path 配置
public struct BitableGroupNoteConfig {
    public static let key = "group_note_config_page_path"

    public private(set) var pathString: String = ""

    public init() {}

    public init?(fieldGroups: [String: Any]?) {
        guard let fieldGroups = fieldGroups,
              let jsonSting = fieldGroups[Self.key] as? String,
              let jsonDic = jsonSting.toDictionary(),
              let pathString = jsonDic["group_note_config_page"] as? String  else {
            return nil
        }
        self.pathString = pathString
    }
}
