//
//  MeegoAbilityConfig.swift
//  LarkMeego
//
//  Created by qsc on 2023/8/8.
//

import Foundation
import LarkSetting
import LKCommonsLogging

struct MeegoCompatibilityConfig: Decodable {
    let forceUpgrade: Bool
    let title: [String: String]?
    let content: [String: String]?
    let freqLimit: Int?
}

struct MeegoAbilityConfig: SettingDecodable {
    static var settingKey = UserSettingKey.make(userKeyLiteral: "meego_ability_config")
    let compatibility: MeegoCompatibilityConfig
}

extension MeegoAbilityConfig {
    func checkCompatibility() -> MeegoCompatibility? {
        if compatibility.forceUpgrade {
            return .forceUpgrade
        }
        // 非强制提醒的情况下，需要配置弹窗内容
        if compatibility.content != nil {
            return .remindUpgrade
        }
        return nil
    }
}
