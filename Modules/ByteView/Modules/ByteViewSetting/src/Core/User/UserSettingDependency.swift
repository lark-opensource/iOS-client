//
//  UserSettingDependency.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/7.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

public enum UserSettingDomainKey: String {
    case passport
    case rtcFrontier
    case rtcDecision
    case rtcDefaultips
    case mpApplink

    case feishuRtc = "feishu_rtc"
    case feishuPreRtc = "feishu_pre_rtc"
    case feishuTestRtc = "feishu_test_rtc"
    case feishuTestPreRtc = "feishu_test_pre_rtc"
    case feishuTestGaussRtc = "feishu_test_gauss_rtc"

    case larkRtc = "lark_rtc"
    case larkPreRtc = "lark_pre_rtc"
    case larkTestRtc = "lark_test_rtc"
    case larkTestPreRtc = "lark_test_pre_rtc"
    case larkTestGaussRtc = "lark_test_gauss_rtc"

    case vcPrivacySoundUrl = "vc_privacy_sound_url"     //声纹
    case vcPrivacyPolicyUrl = "vc_privacy_policy_url"   //隐私协议
    case vcTermsServiceUrl = "vc_terms_service_url"    //用户协议
    case vcLivePolicyUrl = "vc_live_policy_url"        //直播协议
}

public struct RtcSettingDependency {
    public let appId: String
    public let kaChannel: String
    /// CA根证书集
    public let serverCertificate: [Data]

    public init(appId: String, kaChannel: String, serverCertificate: [Data]) {
        self.appId = appId
        self.kaChannel = kaChannel
        self.serverCertificate = serverCertificate
    }
}

public protocol UserSettingDependency {
    /// 账号信息
    var account: AccountInfo { get }
    /// 本地存储
    var storage: LocalStorage { get }
    /// 全局本地存储，后续删掉
    var globalStorage: LocalStorage { get }
    /// 网络能力
    var httpClient: HttpClient { get }

    /// 获取FG的值
    /// - Parameter key: 需要获取FG的key
    func featureGatingValue(for key: String) -> Bool

    /// 获取运行时可变FG的值
    /// - Parameter key: 需要获取FG的key
    func dynamicFeatureGatingValue(for key: String) -> Bool

    /// 获取Setting的值
    /// LarkSetting需要扫描UserSettingKey.make方法，直接透传StaticString扫描不到(lark/project/lark_setting.rb)
    func setting<T: Decodable>(for key: SettingsV3Key, type: T.Type) throws -> T

    /// 获取Setting的值，返回原始字典
    func setting(for key: SettingsV3Key) throws -> [String: Any]

    /// 获取域名配置
    func domain(for key: UserSettingDomainKey) -> [String]

    /// 是否是私有化 KA
    var isPrivateKA: Bool { get }

    /// 安装包是否是Lark （对应海外 Appstore）
    var packageIsLark: Bool { get }

    var rtcSetting: RtcSettingDependency { get }

    var appGroupId: String { get }

    var broadcastExtensionId: String { get }

    /// 是否需要更新Lark
    var shouldUpdateLark: Bool { get }

    /// 通知是否显示详情
    var shouldShowDetails: Bool { get }

    /// 会中通话中是否暂停通知
    var shouldShowMessage: Bool { get }

    /// 是否启用CallKit
    var isCallKitEnabled: Bool { get }
    /// 是否显示CallKit设置
    var showsCallKitSetting: Bool { get }

    var callKitLogo: UIImage { get }

    /// 是否在系统通话记录中显示视频会议通话记录
    /// - A Boolean value that indicates whether the provider includes a call in the system’s Recents list after the call ends.
    var includesCallsInRecents: Bool { get }

    /// 登录国家码：原始翻译文档和资源文件的生成 https://bytedance.feishu.cn/docs/doccnjoB6WKXcer4wZ8VbeXPgTc#TuKAsx
    var mobileCodes: [MobileCode] { get }

    var logPath: String { get }

    var translateLanguageSetting: TranslateLanguageSetting { get }
    var voipExpiredRecord: VoIPExpiredIgnoreRecord? { get }
    func updateVoipExpiredRecord(_ record: VoIPExpiredIgnoreRecord?)

    var deviceNtpTimeRecord: DeviceNtpTimeRecord? { get }
    func updateDeviceNtpTimeRecord(_ record: DeviceNtpTimeRecord?)

    func updateTranslateLanguage(isAutoTranslationOn: Bool?, targetLanguage: String?, rule: TranslateDisplayRule?)
    func observeTranslateLanguageSetting(onChanged: @escaping (TranslateLanguageSetting) -> Void)
}
