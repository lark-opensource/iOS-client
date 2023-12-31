//
//  AuthorizedUserInfo.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/3/23.
//

import Foundation
import LarkLocalizations
import SwiftyJSON


public struct UserAliasInfo: Codable, Equatable {
    public let displayName: String?
    public let i18nDisplayNames: [String: String]

    public enum CodingKeys: String, CodingKey {
        case displayName = "value"
        case i18nDisplayNames = "i18n_value"
    }

    public static var empty: UserAliasInfo {
        UserAliasInfo(displayName: nil, i18nDisplayNames: [:])
    }

    public init(displayName: String?, i18nDisplayNames: [String: String]) {
        self.displayName = displayName
        self.i18nDisplayNames = i18nDisplayNames
    }

    // display_name 的 json value
    public init(json: JSON) {
        displayName = json["value"].string
        i18nDisplayNames = json["i18n_value"].dictionaryObject as? [String: String] ?? [:]
    }

    // display_name 的 json value
    public init(data: [String: Any]) {
        displayName = data["value"] as? String
        i18nDisplayNames = data["i18n_value"] as? [String: String] ?? [:]
    }

    public var currentLanguageDisplayName: String? {
        localizeDisplayName(locale: LanguageManager.currentLanguage.rawValue.lowercased())
    }

    public func localizeDisplayName(locale: String) -> String? {
        if let i18nName = i18nDisplayNames[locale], !i18nName.isEmpty {
            return i18nName
        } else if let displayName, !displayName.isEmpty {
            return displayName
        } else {
            return nil
        }
    }
}


public struct AuthorizedUserInfo: Equatable, Codable {
    public let userID: String
    // 兜底名字
    public let userName: String
    // 国际化名字，取不到当前 locale 名字会用兜底名字
    public let i18nNames: [String: String]
    // 别名信息，优先级最高
    public let aliasInfo: UserAliasInfo

    public static var empty: AuthorizedUserInfo {
        AuthorizedUserInfo(userID: "", userName: "", i18nNames: [:], aliasInfo: .empty)
    }

    public init(userID: String, userName: String, i18nNames: [String: String], aliasInfo: UserAliasInfo) {
        self.userID = userID
        self.userName = userName
        self.i18nNames = i18nNames
        self.aliasInfo = aliasInfo
    }

    public func getDisplayName(locale: String = LanguageManager.currentLanguage.rawValue.lowercased()) -> String {
        if let alias = aliasInfo.localizeDisplayName(locale: locale) {
            return alias
        }
        if let i18nName = i18nNames[locale],
           !i18nName.isEmpty {
            return i18nName
        } else {
            return userName
        }
    }
}
