//
//  SettingConfig.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/16.
//

import Foundation
import LarkLocalizations

// Mail Preload Config
public struct MailPreloadConfig: Decodable {
    public let enableOnlyWifi: Bool
    public let newMailPreloadCount: Int
    public let searchPreloadCount: Int
    public let preloadImageCountPerThread: Int
    public let enablePreDownloadImg: Bool? // 是否开启点击列表提前加载图片

    enum CodingKeys: String, CodingKey {
        case enableOnlyWifi = "enableOnlyWifi"
        case newMailPreloadCount = "newMailPreloadCount"
        case searchPreloadCount = "searchPreloadCount"
        case preloadImageCountPerThread = "preloadImageCountPerThread"
        case enablePreDownloadImg = "enablePreDownloadImg"
    }
}

// Mail articles link config
public struct MailArticlesLinkConfig: Decodable {
    public let serverHelp: String
    public let passwordHelp: String
    public let loginSafety: String
    public let openIMAP: String
    public let migrationSetting: String
    public let migrationInComplete: String

    enum CodingKeys: String, CodingKey {
        case serverHelp = "setup-server"
        case passwordHelp = "password-help"
        case loginSafety = "login-safety"
        case openIMAP = "open-imap"
        case migrationSetting = "migrate-setting"
        case migrationInComplete = "migrate-incomplete"
    }
}
public struct MailAIHistoryLinkConfig: Decodable {
    public let chatInitUrl: String
    enum CodingKeys: String, CodingKey {
        case chatInitUrl = "embedded_chat_init_url"
    }
}

extension String {
    var localLink: String {
        let token = "${locale}"
        let locale = LanguageManager.currentLanguage.languageIdentifier
        return self.replacingOccurrences(of: token, with: locale)
    }
}
