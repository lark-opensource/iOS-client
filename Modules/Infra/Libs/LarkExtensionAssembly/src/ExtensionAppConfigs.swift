//
//  ExtensionAppConfigs.swift
//  LarkExtensionAssembly
//
//  Created by 王元洵 on 2021/5/10.
//

import Foundation
import LarkExtensionServices
import LarkReleaseConfig
import LarkEnv
import LarkFoundation
import LarkStorageCore
import LarkSetting
import LarkContainer

enum ExtensionAppConfigs {
    /// 保存Extension需要的App Config
    static func saveAppConfig(userResolver: UserResolver) {
        KVPublic.SharedAppConfig.isLark.setValue(ReleaseConfig.isLark)
        KVPublic.SharedAppConfig.envType.setValue(EnvManager.env.type.rawValue)
        KVPublic.SharedAppConfig.envUnit.setValue(EnvManager.env.unit)
        KVPublic.SharedAppConfig.ttenv.setValue(KVPublic.Common.ttenv.value())
        KVPublic.SharedAppConfig.appId.setValue(ReleaseConfig.appId)
        KVPublic.SharedAppConfig.appName.setValue(LarkFoundation.Utils.appName)
        let settingKey = UserSettingKey.make(userKeyLiteral: "extension_setting")
        guard let settings = try? userResolver.settings.setting(with: settingKey) else {
            return
        }
        if let teaPerformance = settings["tea_performance"] as? [String: Any] {
            KVPublic.SharedAppConfig.teaUploadDiffTimeInterval.setValue(teaPerformance["interval"] as? Double)
            KVPublic.SharedAppConfig.teaUploadDiffNumber.setValue(teaPerformance["number"] as? Int)
        }
        KVPublic.SharedAppConfig.logEnable.setValue(settings["log_enable"] as? Bool)
        KVPublic.SharedAppConfig.logBufferSize.setValue(settings["log_max_buffer_size"] as? Int)
    }
}
