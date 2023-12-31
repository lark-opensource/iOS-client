//
//  PrivacyConfig.swift
//  LarkAppConfig
//
//  Created by quyiming on 2020/4/29.
//

import Foundation
import LarkLocalizations
import LarkReleaseConfig
import LKCommonsLogging
import LarkSetting

/// 隐私协议和服务条款url配置
public final class PrivacyConfig {

    static let logger = Logger.log(PrivacyConfig.self)

    /// 拼接隐私协议以及服务条款后缀path，格式：/${lang}/${path}
    static public func suffix(_ path: String) -> String {
        return "/\(LanguageManager.currentLanguage.languageIdentifier)/\(path)"
    }

    /// 服务条款path
    static public let termsPath: String = {
        if ReleaseConfig.isLite {
            return "feishu-lite-terms"
        } else {
            return "terms"
        }
    }()

    /// 隐私协议path
    static public let privacyPath: String = {
        if ReleaseConfig.isLite {
            return "feishu-lite-privacy"
        } else {
            return "privacy"
        }
     }()

    /// 注销协议
    static public let accountDeletionPath: String = {
        if ReleaseConfig.isLite {
            return "feishu-lite-deletion"
        } else {
            return "deletion"
        }
    }()

    /// 隐私协议后缀
    static public var privacySuffix: String { suffix(privacyPath) }

    /// 服务条款后缀
    static public var termsSuffix: String { suffix(termsPath) }

    /// 注销协议后缀
    static public var accountDeletionSuffix: String { suffix(accountDeletionPath) }

    /// 隐私协议url
    static public var privacyURL: String {
        if let domain = DomainSettingManager.shared.currentSetting[.privacy]?.first {
            logger.info("privacyURL 返回成功")

            return "https://\(domain)\(suffix(privacyPath))"
        }
        logger.error("get privacy local domain fail")
        return ""
    }

    /// 服务条款url
    static public var termsURL: String {
        logger.info("termsURL 获取domain")

        if let domain = DomainSettingManager.shared.currentSetting[.privacy]?.first {
            return "https://\(domain)\(suffix(termsPath))"
        }
        logger.error("get privacy local domain fail")
        return ""
    }

    /// 动态隐私协议
    static public var dynamicPrivacyURL: String? {
        dynamicURL(key: "help-private-policy")
    }

    /// 动态服务条款
    static public var dynamicTermURL: String? {
        dynamicURL(key: "help-user-agreement")
    }

    private static func dynamicURL(key: String) -> String? {
        return (try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "client_dynamic_link"))[key]) as? String
    }

    /// 注销协议url
    static public var accountDeletionURL: String {
        if let domain = DomainSettingManager.shared.currentSetting[.privacy]?.first {
            return "https://\(domain)\(suffix(accountDeletionPath))"
        }
        logger.error("get account deletion local domain fail")
        return ""
    }
}
