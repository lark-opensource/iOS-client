//
//  TemplateSetting.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/6/15.
//

import Foundation
import LarkSetting

/// template schema 请求重试配置
///
/// 配置地址：
/// * Feishu(https://cloud.bytedance.net/appSettings-v2/detail/config/170975/detail/basic)
/// * Lark(https://cloud.bytedance.net/appSettings-v2/detail/config/172997/detail/basic)
struct TemplateSchemaRetryConfig: SettingDefaultDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "workplace_template_retry_config")
    static let defaultValue = TemplateSchemaRetryConfig(enable: true, maxRetryTimes: 3)

    /// 是否开启重试
    let enable: Bool
    /// 最大重试次数
    let maxRetryTimes: Int
}
