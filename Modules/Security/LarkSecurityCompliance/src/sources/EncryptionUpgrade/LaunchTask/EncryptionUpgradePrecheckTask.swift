//
//  EncryptionUpgradePrecheckTask.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/4/27.
//

import Foundation
import BootManager
import LarkSecurityComplianceInfra

final class EncryptionUpgradePrecheckTask: BranchBootTask, Identifiable { // Global
    static var identify = "EncryptionUpgradePrecheckTask"
    // 一次冷启动只执行一次
    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        Logger.info("precheck task executed")
        // 本次冷启是否有升级标识
        let shouldRekey = EncryptionUpgradeStorage.shared.shouldRekey
        Logger.info("shouldRekey on precheck: \(shouldRekey)")
        if !shouldRekey {
            return
        }
        // 本次冷启是否有跳过标识
        let shouldSkip = EncryptionUpgradeStorage.shared.shouldSkipOnce
        Logger.info("shouldSkip on precheck: \(shouldSkip)")
        if shouldSkip {
            // 删除一次性跳过标识
            EncryptionUpgradeStorage.shared.updateShouldSkipOnce(value: false)
            return
        }
        NewBootManager.shared.context.blockDispatcher = true
        Logger.info("block dispatcher")

        self.flowCheckout(.encryptionUpgradeFlow)
        Logger.info("flow checkout to encryptionUpgradeFlow")
    }
}
