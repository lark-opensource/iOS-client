//
//  WidgetPreloadConfig.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2023/6/15.
//

import Foundation
import LarkSetting

/// Block 预加载的间隔时长
///
/// 配置地址:
/// * Feishu(https://cloud.bytedance.net/appSettings-v2/detail/config/181597/detail/status)
struct WidgetPreloadConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "workplace_component_preload")
    
    static let defaultValue = WidgetPreloadConfig(
        minTimeSinceLastPrefetch: 14400 // 秒
    )

    /// 与上次预加载间隔时间, 默认 4 小时
    let minTimeSinceLastPrefetch: Int
}
