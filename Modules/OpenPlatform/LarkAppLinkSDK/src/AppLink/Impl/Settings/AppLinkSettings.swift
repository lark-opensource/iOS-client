//
//  AppLinkSettings.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/29.
//

import Foundation
import LarkCloudScheme
import LarkSetting

let applinkRemoteSettingsKey = "key_open_app_link_config"

/// 无域名的 AppLink 的域名段，支持类似 lark://applink/client/xxx 格式
let unifiedDomain: String = "applink"

/// AppLink 支持的 Scheme 列表
var supportedSchemes: [String] = {
    var supportedHostSchemes = CloudSchemeManager.shared.supportedHostSchemes
    supportedHostSchemes.append("https")
    return supportedHostSchemes
}()

/// AppLink 配置
struct AppLinkSettings {
    
    /// 远端配置：支持调用的 AppLink path 列表
    ///
    /// 为空表示远端配置加载未完成
    let supportedPathsRemote: [String]
    
    /// 远端配置：支持调用的 AppLink domain 正则列表，会有多个，用于支持 AppLink 的交叉调用和跨域调用，仅用于校验作用，禁止被用于组装或生成 AppLink
    ///
    /// 为空表示远端配置加载未完成
    let supportedRegDomainsRemote: [String]
}
