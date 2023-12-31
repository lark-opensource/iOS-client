//
//  SchemeConfig.swift
//  LarkCloudScheme
//
//  Created by 王元洵 on 2022/2/11.
//

import Foundation
import LKCommonsLogging

/// 字节云平台配置的 schema_manage_config, https://cloud.bytedance.net/appSettings/config/114682/detail/status
struct SchemeConfig {
    private static let logger = Logger.log(SchemeConfig.self, category: "SchemeConfig")
    private let schemeAllowListKey = "schema_handle_list"
    private let schemeForbiddenListKey = "schema_handle_block_list"
    private let schemeIgnoreListKey = "schema_handle_ignore_list"
    private let schemeDownloadSiteKey = "download_site_list"
    /// default scheme list
    /// Android uses as incremental config, and they finished first, so iOS implements it in the same way

    /// URL scheme 白名单（默认 canOpen 为 true）
    private(set) lazy var allowList: Set<String> = Set(Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String]
    ?? [
        "tel",
        "xiaomier",
        "dmallos"
    ])

    /// URL scheme 黑名单（默认 canOpen 为 false，且弹窗提示）
    private(set) lazy var forbiddenList: Set<String> = []

    /// URL scheme 忽略名单（一般为内部 scheme，默认 canOpen 为 false，抛回给 WebView）
    private(set) lazy var ignoreList: Set<String> = [
        "http",
        "https",
        "about",
        "sslocal",
        "data",
        "pageready",
        "bytedance"
    ]

    /// scheme app download website list
    private(set) var schemeDownloadSiteList: [String: String] = [:]

    init() {}

    init?(jsonDict: [String: Any]) {
        if let allowList = jsonDict[schemeAllowListKey] as? [String], !allowList.isEmpty {
            self.allowList.formUnion(allowList)
            SchemeConfig.logger.info("[Cloud scheme] Update allow list: \(self.allowList)")
        } else {
            SchemeConfig.logger.error("[Cloud scheme] Cannot convert to valid scheme allow list")
        }
        if let forbiddenList = jsonDict[schemeForbiddenListKey] as? [String], !forbiddenList.isEmpty {
            self.forbiddenList.formUnion(forbiddenList)
            SchemeConfig.logger.info("[Cloud scheme] Update forbidden list: \(self.forbiddenList)")
        } else {
            SchemeConfig.logger.error("[Cloud scheme] Cannot convert to valid scheme forbidden list")
        }
        if let ignoreList = jsonDict[schemeIgnoreListKey] as? [String], !ignoreList.isEmpty {
            self.ignoreList.formUnion(ignoreList)
            SchemeConfig.logger.info("[Cloud scheme] Update ignore list: \(self.ignoreList)")
        } else {
            SchemeConfig.logger.error("[Cloud scheme] Cannot convert to valid scheme ignore list")
        }
        if let schemeDownloadSiteList = jsonDict[schemeDownloadSiteKey] as? [String: String], !schemeDownloadSiteList.isEmpty {
            self.schemeDownloadSiteList = schemeDownloadSiteList
            SchemeConfig.logger.info("[Cloud scheme] Update download site list: \(self.schemeDownloadSiteList)")
        } else {
            SchemeConfig.logger.error("[Cloud scheme] Cannot convert to valid download site list")
        }
    }
}

extension Set where Element == String {

    func caseInsensitiveContains(_ string: Element) -> Bool {
        return contains(where: {
            $0.caseInsensitiveCompare(string) == .orderedSame
        })
    }
}
