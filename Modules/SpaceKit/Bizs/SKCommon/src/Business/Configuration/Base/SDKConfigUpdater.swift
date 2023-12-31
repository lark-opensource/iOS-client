//
//  SDKConfigUpdater.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/4/29.
//  

import SKFoundation
import SKInfra

public struct SDKConfigUpdater {
    let updatedConfig: [String: Any]

    public init(updatedConfig: [String: Any]) {
        self.updatedConfig = updatedConfig
    }

    public func updateWith(_ sdk: DocsSDK) {
        updateWatermarkIfNeeded()
        updateDeviceIdIfNeeded()
    }

    private func updateWatermarkIfNeeded() {
        if let waterEnable = updatedConfig["globalWatermarkIsOn"] as? Bool {
            CCMKeyValue.globalUserDefault.set(waterEnable, forKey: UserDefaultKeys.globalWatermarkEnabled)
            DocsLogger.info("update watermark settting: \(waterEnable)", component: LogComponents.watermark)
        }
    }

    private func updateDeviceIdIfNeeded() {
        guard let newDeviceId = updatedConfig["device_id"] as? String else {
            return
        }
        let oldDeviceId = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID)
        DocsLogger.info("update deviceId from \(oldDeviceId?.prefix(5) ?? "null") to \(newDeviceId.prefix(5))", component: LogComponents.sdkConfig)
        DocsTracker.shared.deviceid = newDeviceId
        CCMKeyValue.globalUserDefault.set(newDeviceId, forKey: UserDefaultKeys.deviceID)
        SpaceHttpHeaders.updateDevice(newDeviceId)
        NetConfig.shared.updateDeviceId(newDeviceId)
        GeckoPackageManager.shared.setupDevice(device: newDeviceId)
    }
}
