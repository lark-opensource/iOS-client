//
//  OpenPlatformLauncherDelegate.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/7/28.
//

import Foundation
import LarkAccountInterface
import TTMicroApp
import LKCommonsLogging

final class OpenPlatformLauncherDelegate: LauncherDelegate {
    let name = "OpenPlatformLauncher"
    static let opLogger = Logger.oplog(OpenPlatformLauncherDelegate.self, category: "OpenPlatformLauncherDelegate")

    func beforeLogout(conf: LogoutConf) {
        if conf.type == .all {
            Self.opLogger.info("beforLogout setUpClearModels")
            OPClearManager.shared.setUpClearModels()
        }
    }
}
