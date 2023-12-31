//
//  AppConfig.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/05/21.
//

import Foundation
import SuiteAppConfig
import LarkContainer

// MARK: - 精简模式
// 以下场景均被精简模式管控
public extension Feed.Feature {
    // 置顶
    static func shortcutEnabled(_ userResolver: UserResolver) -> Bool {
        getConfigValueWithLog("feed.shortcut", userResolver: userResolver)
    }

    // 加急红圈
    static var urgentEnabled: Bool = true
    static func _getUrgentEnabled(userResolver: UserResolver) -> Bool {
        getConfigValueWithLog("urgent.urgentList", userResolver: userResolver)
    }

    // 标签分组
    static var labelEnabled: Bool = true
    static func _getLabelEnabled(userResolver: UserResolver) -> Bool {
        getConfigValueWithLog("label", userResolver: userResolver)
    }

    static var isDebugMode = false
}

extension Feed.Feature {
    static func getConfigValueWithLog(_ key: String, userResolver: UserResolver) -> Bool {
        // TODO: 用户隔离 AppConfigManager
        let enable = AppConfigManager.shared.feature(for: key).isOn
        FeedContext.log.info("feedlog/feature/appConfig. \(key): \(enable)")
        return enable
    }
}
