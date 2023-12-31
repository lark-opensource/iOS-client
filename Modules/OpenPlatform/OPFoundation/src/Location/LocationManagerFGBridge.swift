//
//  LocationManagerFGWrapper.swift
//  EEMicroAppSDK
//
//  Created by 张旭东 on 2022/8/9.
//

import LarkSetting
@objc(EMALocationManagerFGBridge)
public final class LocationManagerFGBridge: NSObject {
    @objc
    public static var isUseNewUpdateAlgorithm: Bool {
        return (locationTaskConfig["isUseNewUpdateLocationAlgorithm"] as? Bool) ?? false
    }
    
    @objc
    public static var updateCurrentLocationTimeout: TimeInterval {
        return (locationTaskConfig["updateCurrentLocationTimeout"] as? TimeInterval) ?? 3.0
    }
    
    private static var locationTaskConfig: [String: Any] {
        do {
            // TODOZJX
            let config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "lark_core_location_task_config"))
            return config
        } catch {
            return [:]
        }
    }
}
