//
//  MailSettingConfig.swift
//  LarkMail
//
//  Created by ByteDance on 2023/5/16.
//

import Foundation
import LarkSetting
import MailSDK

/// AppSettings
/// 如有新增的配置，新配置使用一个Struct定义，比如：
/// MailPreloadConfig 在setting的配置为
/// {
///     "enableOnlyWifi": True,
///     "newMailPreloadCount": 5,
///     "searchPreloadCount": 5,
///     "preloadImageCountPerThread": 5
/// }
/// 通过定义个Struct， 实现 SettingDecodable， 并在 MailSettingConfig 新增
/// @Setting(.useDefaultKeys)
/// public var preloadConfig: MailPreloadConfig?
/// 可以自动实现appsetting配置的解析
public struct MailSettingConfig: MailSettingConfigProxy {
    @Setting(.useDefaultKeys)
    public var preloadConfig: MailPreloadConfig? // 预加载配置
    @Setting(.useDefaultKeys)
    public var linkConfig: MailArticlesLinkConfig? // 帮助文档配置
    @Setting(.useDefaultKeys)
    public var aiHistoryLinkConfig: MailAIHistoryLinkConfig? // ai link配置信息
}

extension MailPreloadConfig: SettingDecodable {
    // AppSetting上对应的key https://cloud.bytedance.net/appSettings-v2/detail/config/178044
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "MailPreloadConfig")
}

extension MailArticlesLinkConfig: SettingDecodable {
    // AppSetting上对应的key https://cloud.bytedance.net/appSettings-v2/detail/config/130920
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "mail_articles_link_config")
}

extension MailAIHistoryLinkConfig: SettingDecodable {
    //https://cloud-boe.bytedance.net/appSettings-v2/detail/config/186527/
    public static let settingKey = UserSettingKey.make(userKeyLiteral: "mail_ai_config")
}
