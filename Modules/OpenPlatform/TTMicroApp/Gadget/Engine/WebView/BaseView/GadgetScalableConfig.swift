//
//  GadgetScalableConfig.swift
//  TTMicroApp
//
//  Created by qsc on 2023/3/30.
//

import Foundation
import LarkSetting
import LKCommonsLogging


fileprivate let logger = Logger.oplog(GadgetScalableConfig.self, category: "GadgetScalableConfig")

struct GadgetRenderScalableRemoteConfig: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "openplatform_gadget_render_scalable")
    let enableScaleAppIdList: [String]
    let disableScaleAppIdList: [String]
}

extension GadgetRenderScalableRemoteConfig {
    func checkScaleEnabled(with appId: String) -> Bool {
        if(disableScaleAppIdList.contains(appId)) {
            logger.info("disable scalable because of \(appId) in disableList")
            return false
        } else {
            logger.info("check scalable for: \(appId): enableList has *: \(enableScaleAppIdList.contains("*")) or appid \(enableScaleAppIdList.contains(appId))")
            return enableScaleAppIdList.contains("*") || enableScaleAppIdList.contains(appId)
        }
    }
}

public class GadgetScalableConfig: NSObject {
    private var remoteConfig: GadgetRenderScalableRemoteConfig?
    
    public override init() {
        remoteConfig = try? SettingManager.shared.setting(with: GadgetRenderScalableRemoteConfig.self, decodeStrategy: .useDefaultKeys)
    }
    
    @objc public func checkScaleEnabled(appId: String) -> Bool {
        return remoteConfig?.checkScaleEnabled(with: appId) ?? false
    }
}
