//
//  OPECONetworkAPISetting.swift
//  OPFoundation
//
//  Created by 刘焱龙 on 2023/6/30.
//

import Foundation
import LarkSetting

private struct OPECONetworkAPISetting: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "use_econetwork_api")
    let `default`: Bool
    let path: [String: Bool]
}

public final class OPECONetworkAPISettingDependency {

    public static func enableECONetwork(path: String) -> Bool {
        let setting = (try? SettingManager.shared.setting(with: OPECONetworkAPISetting.self)) ?? OPECONetworkAPISetting(default: false, path: [:])
        if let enable = setting.path[path] {
            return enable
        }
        return setting.default
    }
}
