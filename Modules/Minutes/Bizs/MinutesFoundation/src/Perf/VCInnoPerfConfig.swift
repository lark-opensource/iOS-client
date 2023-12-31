//
//  VCInnoPerfConfig.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/15.
//

import Foundation
import LarkSetting

struct VCInnoPerfConfig: SettingDecodable {
  static let settingKey = UserSettingKey.make(userKeyLiteral: "vc_inno_perf_config")
  let reportInterval: Int
  let powerReportInterval: Int
}

@propertyWrapper
struct SyncedSetting<T: SettingDecodable> where T.Key == UserSettingKey {
    public var wrappedValue: T? {
        try? SettingManager.shared.setting(with: T.self)
    }
}
