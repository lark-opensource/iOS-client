//
//  WPNetworkSetting.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/8.
//

import Foundation
import LarkSetting

/// 网络层超时配置
///
/// 配置地址:
/// * Feishu(https://cloud.bytedance.net/appSettings-v2/detail/config/168018/detail/status)
/// * Lark(https://cloud.bytedance.net/appSettings-v2/detail/config/169185/detail/basic)
struct NetworkTimeoutConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "workplace_network_timeout_config")
    static let defaultValue = NetworkTimeoutConfig()

    /// 网络超时时间（单位 s）
    var timeout: Double = 30.0
}
