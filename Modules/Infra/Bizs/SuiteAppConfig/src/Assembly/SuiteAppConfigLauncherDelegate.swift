//
//  SuiteAppConfigLauncherDelegate.swift
//  SuiteAppConfig
//
//  Created by Yiming Qu on 2021/2/2.
//

import Foundation
import LarkAccountInterface
import LKCommonsLogging

final class SuiteAppConfigLauncherDelegate: LauncherDelegate {

    private static let logger = Logger.log(
        SuiteAppConfigLauncherDelegate.self,
        category: "SuiteAppConfig.LauncherDelegate"
    )

    let name = "SuiteAppConfig"

    func fastLoginAccount(_ account: LarkAccountInterface.Account) {
        Self.logger.info("fastLoginAccount reload", additionalData: [
            "uid": account.userID
        ])
        AppConfigManager.shared.reloadConfig(for: account.userID, clearConfig: false)
    }

    func afterSetAccount(_ account: Account) {
        Self.logger.info("after set account reload", additionalData: [
            "uid": account.userID
        ])
        AppConfigManager.shared.reloadConfig(for: account.userID)
    }

    func beforeLogoutClearAccount(_ account: Account?) {
        Self.logger.info("before logout clear account reload", additionalData: [
            "uid": String(describing: account?.userID)
        ])
        AppConfigManager.shared.clearConfig()
    }

}
