//
//  OPGadgetContainerReloadConfig.swift
//  OPGadget
//
//  Created by qsc on 27/3/2023.
//

import Foundation
import LarkSetting
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPGadgetContainerReloadConfig.self, category: "GadgetContainerReloadConfig")

struct OPGadgetContainerReloadConfig: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "gadget_reload_current_schema")
    let openToAll: Bool
    let blackList: [String]
    let whiteList: [String]
}


extension OPGadgetContainerReloadConfig {
    func useCurrentMountData(appId: String) -> Bool {
        if(blackList.contains(appId)) {
            logger.info("not use CurrentMountData because appid in blacklist")
            return false
        } else {
            logger.info("check use CurrentMountData: whitelist.contains \(whiteList.contains(appId)) or openToAll: \(openToAll)")
            return whiteList.contains(appId) || openToAll
        }
    }
}
