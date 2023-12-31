//
//  BlockAutoMaxHeightConfig.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2023/8/16.
//

import Foundation
import LarkSetting

/// block自动高度最大限制
///
/// 配置地址:
/// * Feishu(https://cloud.bytedance.net/appSettings-v2/detail/config/188675/detail/status)
/// * boe(https://cloud-boe.bytedance.net/appSettings-v2/detail/config/180305/detail/status?deploy_id=189971)
struct BlockAutoMaxHeightConfig: SettingDefaultDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "block_max_auto_height")
    
    static let defaultValue = BlockAutoMaxHeightConfig(
        maxHeight: 3000
    )

    var maxHeight: Int
}
