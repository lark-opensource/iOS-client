//
//  ColorImageSettingManager.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/21.
//

import Foundation
import LKCommonsLogging
import LarkSetting
import LarkContainer

struct ColorImageConfigItem {
    let key: String
    let startColorInt: Int32
    let endColorInt: Int32
}
final class ColorImageSettingConfig {

    private static let logger = Logger.log(ColorImageSettingConfig.self, category: "ColorImageSettingConfig")
    static let settingKey = UserSettingKey.make(userKeyLiteral: "default_icon_keys_config")

    var fillIcons: [ColorImageConfigItem] = []
    var borderIcons: [ColorImageConfigItem] = []
    var fsUnit = ""
    // 推荐的表情
    var emojiKeys: [String] = []

    init(userResolver: UserResolver) {
        if let settings = try? userResolver.settings.setting(with: Self.settingKey) as [String: Any] {
            self.fillIcons = self.transformArr(settings["fillStyleIconKeys"] as? [[String: Any]])
            self.borderIcons = self.transformArr(settings["borderStyleIconKeys"] as? [[String: Any]])
            self.fsUnit = (settings["fsUnit"] as? String) ?? ""
            self.emojiKeys = settings["reactionKeys"] as? [String] ?? []
            Self.logger.info("settings key value count fillIcon: \(fillIcons.count) borderIcons: \(borderIcons.count)")
        } else {
            Self.logger.error("get ColorImageSettingConfig settings fail")
        }
    }

    private func transformArr(_ arr: [[String: Any]]?) -> [ColorImageConfigItem] {
        guard let arr = arr else { return [] }
        return arr.map { info in
            return ColorImageConfigItem(key: (info["key"] as? String) ?? "",
                                        startColorInt: (info["startColor"] as? Int32) ?? 0,
                                        endColorInt: (info["endColor"] as? Int32) ?? 0)
        }
    }
}
