//
//  BadgeConfig.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/31.
//

import Foundation
import LarkSetting

/// Badge 相关配置开关
final class BadgeConfig {
    let configService: WPConfigService

    /// 全局 badge FG，包含新老版工作台
    var enableBadge: Bool {
        return configService.fgValue(for: .badgeOn)
    }

    /// 模版化 badge FG
    var enableTemplateBadge: Bool {
        return configService.fgValue(for: .enableTemplateBadge)
    }

    init(configService: WPConfigService) {
        self.configService = configService
    }
}
