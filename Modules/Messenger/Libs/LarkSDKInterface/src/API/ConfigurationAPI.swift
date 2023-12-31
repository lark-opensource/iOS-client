//
//  ConfigurationAPI.swift
//  LarkSDKInterface
//
//  Created by chengzhipeng-bytedance on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import LarkLocalizations
import RustPB
import ServerPB
import LKCommonsLogging

public struct DeviceSetting {
    public var language: String

    public init(language: String) {
        self.language = language
    }
}

/// 翻译设置
public struct TranslateLanguageSetting {
    private static let logger = Logger.log(TranslateLanguageSetting.self, category: "LarkSDKInterface.ConfigurationAPI")

    /// 翻译设置的目标语言key 默认为系统语言
    public var targetLanguage: String = LanguageManager.systemLanguage?.languageCode ?? ""
    /// 语言key排序，保证三端展示顺序一致
    public var languageKeys: [String] = []
    /// 图片翻译支持的目标语种
    public var imageLanguageKeys: [String] = []
    /// 网页翻译支持的目标语种
    public var webLanguageKeys: [String] = []
    /// 语言key->显示文案映射关系
    public var supportedLanguages: [String: String] = [:]
    /// 默认所有语言配置
    public var globalConf: RustPB.Im_V1_LanguagesConfiguration = RustPB.Im_V1_LanguagesConfiguration()
    /// 语言key->语言翻译设置，只存用户后期修改过的，第一次获取时为空
    public var languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration] = [:]
    /// 翻译设置Scope，解释如下：
    /// 看RustPB.Im_V1_TranslateScopeMask的定义，翻译有3个设置项，这三个设置项开关可自由组合，
    /// RustPB.Im_V1_TranslateScopeMask中枚举值定义成二进制左移形式，1=1<<0,2=1<<1,4=1<<2，
    /// 举个例子，如果translateScope为5，因为十进制5=二进制101，5在这种枚举值定义下只可能是1+4，
    /// 1+4表示枚举值为1和4的开关是开启的，这样的枚举值定义考虑了设置项和开关组合的扩展性。
    public var translateScope: Int = 0
    /// 不自动翻译的语言key
    public var disAutoTranslateLanguagesConf: [String] = []
    //自动翻译开关-翻译选项scope配置，根据scop返回值确定哪些选项是需要展示的
    // 解释：租户之间需求不同，个别租户只有消息，文档正文及评论这两个翻译需求，额外列出的邮件等不起作用
    // 根据租户需求显示需要展示的自动翻译按钮下的-翻译子选项
    public var translateScopeConfiguration: [Int: Bool] = [:]

    /// 自动翻译开关-消息-是否开启
    public var messageSwitch: Bool {
        return (self.translateScope & RustPB.Im_V1_TranslateScopeMask.larkMessageMask.rawValue) != 0
    }
    /// 自动翻译开关-文档正文-是否开启
    public var docBodySwitch: Bool {
        return (self.translateScope & RustPB.Im_V1_TranslateScopeMask.docBodyMask.rawValue) != 0
    }
    /// 自动翻译开关-文档评论-是否开启
    public var docCommentSwitch: Bool {
        return (self.translateScope & RustPB.Im_V1_TranslateScopeMask.docCommentMask.rawValue) != 0
    }
    /// 自动翻译开关-网页-是否开启
    public var webXmlSwitch: Bool {
        return (self.translateScope & RustPB.Im_V1_TranslateScopeMask.webXml.rawValue) != 0
    }
    /// 自动翻译开关-邮件-是否开启
    public var emailSwitch: Bool {
        return (self.translateScope & RustPB.Im_V1_TranslateScopeMask.email.rawValue) != 0
    }
    /// 自动翻译开关-公司圈-是否开启
    public var momentsSwitch: Bool {
        return (self.translateScope & RustPB.Im_V1_TranslateScopeMask.moments.rawValue) != 0
    }
    /// 自动翻译全局开关
    public var autoTranslateGlobalSwitch: Bool = false
    /// 翻译支持的源语种，服务端排序
    public var srcLanugages: [String] = []
    /// 源语种的设置
    public var srcLanguagesConfig: [String: RustPB.Im_V1_SrcLanguageConfig] = [:]
    /// 用户网页翻译的自定义设置
    public var webTranslationConfig: RustPB.Im_V1_WebTranslationConfig = RustPB.Im_V1_WebTranslationConfig()
    /// 目标语种的设置, 使用language_keys排序
    public var trgLanguagesConfig: [String: RustPB.Im_V1_TrgLanguageConfig] = [:]

    public func getTranslateScope(srcLanguageKey: String) -> Int {
        if srcLanguageKey.isEmpty { return 0 }
        let scopes = self.srcLanguagesConfig[srcLanguageKey]?.scopes ?? 0
        return Int(scopes)
    }

    /// 该语言是否需要自动翻译，不用判断服务器是否支持：服务器是转给Google翻译的，服务器支持的语言是Google支持语言的子集
    public func needAutoTranslate(language: String) -> Bool {
        /// 源语言和目标语言不相同
        if language == self.targetLanguage { return false }
        /// 语言为not_lang：不是一个有语言的消息，比如图片等
        if language == "not_lang" { return false }
        /// 该语言未设置不自动翻译
        return !self.disAutoTranslateLanguagesConf.contains(language)
    }

    public init() { }

    /// 翻译设置信息
    public func info(srcLanguage: String = "") -> String {
        var infoString = ""
        infoString += self.targetLanguage + ","
        if !srcLanguage.isEmpty {
            infoString += srcLanguage + ","
        }
        infoString += String(translateScope) + ","
        infoString += String(self.globalConf.rule.rawValue) + ","
        infoString += self.disAutoTranslateLanguagesConf.joined(separator: "-") + "."
        return infoString
    }

    /// 判断翻译Scope是否开启
    public func isScopeOpen(scope: Int, scopeType: RustPB.Im_V1_TranslateScopeMask) -> Bool {
        return (scopeType.rawValue & scope) != 0
    }

    public func getTrgLanguageI18nStringFor(_ key: String) -> String {
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let config = trgLanguagesConfig[key],
           let language = config.i18NLanguage[currentLocalizations] {
            return language
        }
        Self.logger.error("trgLanguageI18nString notFound, key: \(key), currentLocalizations: \(currentLocalizations), config: \(trgLanguagesConfig[key])")
        return key
    }
}

public protocol ConfigurationAPI {
    /// 获取字节云平台指定key对应的value
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]>

    /// 更新本地语言
    ///
    /// - Parameter language: zh-CN/en-US .etc
    /// - Returns: Observable
    func updateDeviceSetting(language: String) -> Observable<DeviceSetting>

    /// 触发 sdk 拉取系统模板
    func getSystemMessageTemplate(language: String) -> Observable<Void>

    /// 获取翻译设置 只在UserGeneralSettings中使用
    func fetchTranslateLanguageSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<TranslateLanguageSetting>

    /// 设置自动翻译开关
    func setAutoTranslateGlobalSwitch(isOpen: Bool) -> Observable<Void>

    /// 设置翻译目标语言 只在UserGeneralSettings中使用
    func updateTranslateLanguageSetting(language: String) -> Observable<Void>

    /// 设置翻译语言key->翻译效果 只在UserGeneralSettings中使用
    func updateLanguagesConfiguration(globalConf: RustPB.Im_V1_LanguagesConfiguration?, languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]?) -> Observable<Void>

    /// 设置翻译显示翻译效果开关(一级)
    func updateGlobalLanguageDisplayConfig(globalConf: RustPB.Im_V1_LanguagesConfiguration) -> Observable<Void>

    /// 设置翻译源语言(三级) 的翻译效果
    func updateLanguagesConfigurationV2(srcLanguagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) -> Observable<Void>

    /// 修改源语种自动翻译设置(三级)scopes范围
    func updateSrcLanguageScopes(srcLanguagesScope: Int, language: String) -> Observable<Void>

    /// 设置TranslateScope，解释见TranslateLanguageSetting (二级)
    func updateAutoTranslateScope(scope: Int) -> Observable<Void>

    /// 设置不自动翻译的语言 只在UserGeneralSettings中使用
    func updateDisableAutoTranslateLanguages(languages: [String]) -> Observable<[String]>

    /// 获取某条消息的其他语言翻译内容 （原文, [译文]）
    func fetchMessageTranslateInfos(messageId: String) -> Observable<(MessageTranslateInfo, [MessageTranslateInfo])>

    /// 新的拉取新版本的接口
    ///
    /// - Parameters:
    ///   - version: 当前安装版本
    ///   - os: 暂时为固定值iOS
    ///   - userID: 当前登录的userID
    ///   - tenantID: 当前登录的tenantID
    ///   - source: Enterprise or appstore
    ///   - kaChannel: Pass `RELEASE_CHANNEL` if `isKA` is `true`, else pass `nil`
    /// - Returns: RustPB.Basic_V1_GetNewVersionResponse
    func getNewVersion(
        version: String,
        os: String,
        userID: String,
        tenantID: String,
        source: String,
        kaChannel: String?
    ) -> Observable<RustPB.Basic_V1_GetNewVersionResponse>

    /// 当前版本的Release信息
    ///
    /// - Parameters:
    ///   - version: Release信息
    ///   - platform: 暂时为固定值iOS
    /// - Returns: Release信息
    func getVersionNote(version: String, platform: String) -> Observable<RustPB.Basic_V1_VersionData>

    /// 获取workStatus设置
    func getWorkStatusSetting() -> Observable<Bool>

    /// workStatus设置
    func setWorkStatusSetting(isUpdate: Bool) -> Observable<Void>

    /// 获取消息通知设置
    func getNotificationSetting() -> (Observable<(RustPB.Settings_V1_NotificationSetting, Bool)>)

    /// 设置消息通知
    func setNotificationSetting(setting: RustPB.Settings_V1_NotificationSetting?, messageNotificationsOffDuringCallsSetting: Bool?) -> Observable<Void>

    /// 对外展示时区设置
    func setupExternalDisplayTimezoneSetting(setting: RustPB.Settings_V1_ExternalDisplayTimezoneSetting) -> Observable<Void>

    func getExternalDisplayTimezone() -> Observable<RustPB.Settings_V1_ExternalDisplayTimezoneSetting>

    /// 获取消息通知设置v2
    func getNotificationSettingV2() -> Observable<RustPB.Settings_V1_NotificationSettingV2>

    /// 设置消息通知v2
    func setNotificationSettingV2(setting: RustPB.Settings_V1_NotificationSettingV2) -> Observable<Void>

    /// 获取(大部分)用户设置
    func getMostUserSetting() -> Observable<RustPB.Settings_V1_GetUserSettingResponse>

    /// 获取邮件通知设置
    func getMailNotificationSetting() -> Observable<RustPB.Email_Client_V1_MailNotificationSettings>

    /// 设置邮件通知
    func setMailNotificationSetting(setting: RustPB.Email_Client_V1_MailNotificationSettings) -> Observable<Void>

    /// 获取 app 配置
    func getAppConfig() -> Observable<RustPB.Basic_V1_AppConfig>

    /// 直接获取 app 本地配置，会发rust同步请求，请勿在主线程调用
    func getAppConfigFromLocal() -> RustPB.Basic_V1_AppConfig?

    /// 获取免打扰提醒样式
    func getAndReviseBadgeStyle() -> (Observable<RustPB.Settings_V1_BadgeStyle>, Observable<RustPB.Settings_V1_BadgeStyle>)

    /// 设置免打扰提醒样式
    func setBadgeStyle(_ badgeStyle: RustPB.Settings_V1_BadgeStyle) -> Observable<Void>

    /// 设置是否显示主导航免打扰 badge
    func setShowTabMuteBadge(_ showRemind: Bool) -> Observable<Void>

    /// 获取是否显示主导航免打扰 badge
    func fetchShowTabMuteBadge() -> Observable<Bool>

    /// 远程获取好友隐私设置，找到/添加我
    func fetchAddFriendPrivateConfig() -> Observable<RustPB.Settings_V1_GetAddFriendPrivateConfigResponse>

    /// 本地获取一次好友隐私设置，找到/添加我
    func getAddFriendPrivateConfig() -> Observable<RustPB.Settings_V1_GetAddFriendPrivateConfigResponse>

    /// 设置如何找到我
    func setWayToFindMeSetting(id: String, enable: Bool, verifyToken: String) -> Observable<Void>

    /// 设置如何添加我
    func setWayToAddMeSetting(addMeType: RustPB.Settings_V1_WayToAddMeSettingItem.TypeEnum, enable: Bool) -> Observable<Void>

    /// 获取&设置时间制
    func fetchTimeFormat() -> Observable<RustPB.Settings_V1_TimeFormatSetting.TimeFormat>
    func setTimeFormat(_ timeFormat: RustPB.Settings_V1_TimeFormatSetting.TimeFormat) -> Observable<Void>

    /// 获取勿扰模式截止ntp时间
    func fetchDoNotDisturbEndTime() -> Observable<Int64>
    /// 设置勿扰模式截止ntp时间
    func setDoNotDisturbEndTime(time: Int64) -> Observable<Void>

    /// 设置语音自动转文字
    func setAudioToTextSetting(enable: Bool) -> Observable<Void>
    /// 获取语音自动转文字设置
    func getAudioToTextSetting(isFromServer: Bool) -> Observable<Bool>

    /// 设置是否可以电话加急
    func setSmsPhoneUrgent(accept: Bool) -> Observable<Void>
    /// 获取服务器电话加急状态
    func fetchSmsPhoneSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<RustPB.Settings_V1_SmsPhoneUrgentSetting>
    /// 获取Feed设置
    func getFeedSetting() -> Observable<RustPB.Settings_V1_FeedSetting>
    /// 设置Feed
    func setFeedSetting(setting: RustPB.Settings_V1_FeedSetting) -> Observable<Void>
    /// 查询屏蔽用户列表
    func getBlockUserListRequest(cursor: String) -> Observable<RustPB.Contact_V2_GetBlockUserListResponse>
    /// 查询被屏蔽的用户数
    func getBlockUserNum() -> Observable<RustPB.Contact_V2_GetBlockUserNumResponse>
    /// 删除屏蔽用户
    func deleteBlockUserByID(_ id: String) -> Observable<Void>
    /// 设置全局协作权限
    func setupUserMsgAuth(type: RustPB.Contact_V2_MsgType) -> Observable<Void>
    /// 查询全局协作权限设置
    func getUserMsgAuth() -> Observable<RustPB.Contact_V2_GetUserMsgAuthResponse>

    // 企业实体词 Setting
    /// 拉取企业实体配置
    func getEnterpriseEntityWordConfig() -> Observable<ServerPB.ServerPB_As_setting_GetUserASSettingResponse>

    /// 设置企业实体词配置
    func setEnterpriseEntityWordConfig(messageEnabled: Bool?, docEnabled: Bool?, minutesEnabled: Bool?) -> Observable<ServerPB.ServerPB_As_setting_SetUserASSettingResponse>

    // 智能纠错 setting
    /// 拉取智能纠错配置
    func getSmartCorrectConfig() -> Observable<ServerPB_Correction_GetCorrectionSettingResponse>

    /// 设置智能纠错配置
    func setSmartCorrectConfig(_ isEnabeld: Bool) -> Observable<ServerPB_Correction_SetCorrectionSettingResponse>

    /// 智能补全
    func getSmartComposeConfig() -> Observable<ServerPB_Composer_GetComposerSettingResponse>
    func setSmartComposeConfig(_ isEnable: Bool) -> Observable<ServerPB_Composer_SetComposerSettingResponse>
    /// 更新系统时区
    func updateSysytemTimezone(_ timezone: String) -> Observable<Void>
}

public typealias ConfigurationAPIProvider = () -> ConfigurationAPI

/// 翻译效果模型
public struct MessageTranslateInfo {
    public typealias TranslatePBModel = RustPB.Basic_V1_TranslateInfo
    public typealias TypeEnum = RustPB.Basic_V1_Message.TypeEnum

    /// 消息类型
    public let type: TypeEnum
    /// 语言名称，服务器返回的是key，会在翻译对比界面替换为value
    public var languageValue: String
    /// 内容
    public let content: MessageContent

    public let messageContentVersion: Int32

    public init(type: TypeEnum,
                languageValue: String,
                content: MessageContent,
                messageContentVersion: Int32) {
        self.type = type
        self.languageValue = languageValue
        self.content = content
        self.messageContentVersion = messageContentVersion
    }

    public static func transform(pb: TranslatePBModel) -> MessageTranslateInfo {
        /// 内容
        let content: MessageContent
        if pb.messageType == .text {
            content = TextContent.transform(pb: pb)
        } else {
            content = PostContent.transform(pb: pb)
        }
        return MessageTranslateInfo(
            type: pb.messageType,
            languageValue: pb.language,
            content: content,
            messageContentVersion: pb.messageContentVersion)
    }
}
