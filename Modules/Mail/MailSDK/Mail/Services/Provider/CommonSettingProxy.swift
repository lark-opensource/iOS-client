//
//  CommonSettingProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/5/14.
//

import Foundation

public enum MailSettingKey: String, CaseIterable {
    case mailSettingKey = "MailSDK_Common_Setting"
    case helpCenterLinkKey = "mail_articles_link_config"
    case customerServiceLinkKey = "mail_capacity_limit_config"
    case mailMixSearchConfigKey = "mail_mix_search_config"
    case mailOAuthClientConfigKey = "mail_oauth_client_config"
    case mailClientURLKey = "mail_third_client_url"
    case mailFolderLayerMaxCountKey = "mail_folder_layer_max_count"
}

public protocol CommonSettingProxy {
    func stringValue(key: String) -> String?
    func IntValue(key: String) -> Int?
    func floatValue(key: String) -> Float?
    func arrayValue(key: String) -> [Any]?

    /// 获取setting配置下发的原始字符串，需要自己解析json
    /// - Parameter configName: 配置的名称
    /// - Returns: json字符串
    func originalSettingValue(configName: MailSettingKey) -> String?
}

/// 后续新增AppSetting 使用这个接口实现
public protocol MailSettingConfigProxy {
    var preloadConfig: MailPreloadConfig? { get }
    var linkConfig: MailArticlesLinkConfig? { get }
    var aiHistoryLinkConfig: MailAIHistoryLinkConfig? { get }
}
