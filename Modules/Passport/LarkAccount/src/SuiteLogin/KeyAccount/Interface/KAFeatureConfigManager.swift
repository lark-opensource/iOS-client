//
//  KAFeatureConfigManager.swift
//  LarkAccount
//
//  Created by au on 2023/4/27.
//

import Foundation
import LarkSetting

struct KAFeatureConfig: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "passport_ka_spec_feat_config")
    let passportKaFeatureName: String?
}

struct KAFeatureConfigManager {

    static var featureName: String {
        if let config = try? SettingManager.shared.setting(with: KAFeatureConfig.self), // user:checked (setting)
           let name = config.passportKaFeatureName {
            return name
        }
        return ""
    }

    /// 华润场景特化
    static var enableKACRC = Self.featureName.lowercased().contains("kacrc")

    /// idp 使用原生登录页
    static var enableNativeIdP = Self.featureName.lowercased().contains("native_idp")
}
