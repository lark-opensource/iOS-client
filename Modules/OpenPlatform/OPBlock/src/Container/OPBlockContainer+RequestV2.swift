//
//  OPBlockContaienr+RequestV2.swift
//  OPBlock
//
//  Created by Meng on 2023/3/6.
//

import Foundation
import LarkSetting

/// Block Network API V2 配置
///
/// 配置地址：
/// * BOE
/// * 飞书(https://cloud.bytedance.net/appSettings-v2/detail/config/176663/detail/basic)
final class NetworkAPISetting {
    @LazyRawSetting(key: .make(userKeyLiteral: "block_use_new_network_api"))
    private var rawSetting: [String: Any]?

    init() {}

    func checkEnableRequest(appId: String) -> Bool {
        guard let networkSetting = rawSetting else {
            return false
        }

        // 取不到 request 配置，默认返回 false
        guard let requestSetting = networkSetting["request"] as? [String: Bool] else {
            return false
        }

        // 如果配置了 forceDisable 且为 true 时，强制返回 false
        if requestSetting["forceDisable"] ?? false {
            return false
        }

        // 1. 配置了 appId 优先取 appId 的 bool 配置
        // 2. 否则取 default 配置
        // 3. 兜底走 false
        return requestSetting[appId] ?? requestSetting["default"] ?? false
    }
}
