//
//  BadgeSetting.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/11/16.
//

import Foundation
import LarkSetting

/// Badge push API 监听白名单配置，用于控制是否开启应用可以监听其他 appId badge
///
/// 配置地址：
/// * BOE(https://cloud-boe.bytedance.net/appSettings-v2/detail/config/164413/detail/status)
/// * 飞书(https://cloud.bytedance.net/appSettings-v2/detail/config/171122/detail/status)
/// * Lark(https://cloud.bytedance.net/appSettings-v2/detail/config/170752/detail/status)
struct BadgePushAPIConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "server_badge_push_api_config")
    static let defaultValue = BadgePushAPIConfig(enableAppIds: [])

    /// Settings 默认的 convertFromSnakeCase 不能处理 enable_appIds, 会把这个 key 转换为 enableAppids，而不是 enableAppIds
    /// 因此走手动解析 + useDefaultKeys
    enum CodingKeys: String, CodingKey {
        case enableAppIds = "enable_appIds"
    }

    /// 白名单 appId
    let enableAppIds: [String]
}
