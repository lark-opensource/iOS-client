//
//  LarkGPSSettings.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/6/22.
//

import Foundation
import LarkSetting
import LarkContainer

/// lark 户关闭GPS后，Toast提示配置
struct GPSDisableConfig: SettingDecodable {
  static let settingKey = UserSettingKey.make(userKeyLiteral: "location_api_disable_gps_toast_config")
  let toastDuration: Int

    enum CodingKeys: String, CodingKey {
        case toastDuration = "toastDuration"
    }
}

private let defaultDuration = 60 * 3

final class GPSDisableSettings {
    
    private let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    /// gps 关闭toast 频控 默认是 3分钟
    var toastDuration: Int {

        let result: GPSDisableConfig
        do {
            result = try userResolver.settings.setting(with: GPSDisableConfig.self)
        } catch {
            result = GPSDisableConfig(toastDuration: defaultDuration)
        }
        return result.toastDuration >= 0 ? result.toastDuration : defaultDuration
    }
}
