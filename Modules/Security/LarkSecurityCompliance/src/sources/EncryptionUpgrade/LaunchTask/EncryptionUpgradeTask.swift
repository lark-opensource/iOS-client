//
//  EncryptionUpgradeTask.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/4/27.
//

import Foundation
import BootManager
import UniverseDesignToast
import LarkSecurityComplianceInfra
import LarkContainer
import LarkPerf

final class EncryptionUpgradeTask: AsyncBootTask, Identifiable { // Global
    static var identify = "EncryptionUpgradeTask"
    @Provider private var service: EncryptionUpgradeService // global

    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        Logger.info("EncryptionUpgradeTask executed")
        ColdStartup.shared?.operation = .databaseRekey
        let vc = service.startDatabseRekeyVC()
        vc.viewModel.delegate = self
        context.window?.rootViewController = vc
        Logger.info("window root vc set to encryptionUpgrade vc")
    }

    private func resumeBootManager() {
        Logger.info("EncryptionUpgradeTask resume dispatcher")
        DispatchQueue.main.async {
            self.end()
            NewBootManager.shared.context.blockDispatcher = false
        }
    }
}

extension EncryptionUpgradeTask: EncryptionUpgradeEndTaskDelegate {
    func quitAndResume() {
        resumeBootManager()
    }
}
