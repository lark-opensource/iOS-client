//
//  EncryptionUpgradePredecessorTask.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/21.
//

import Foundation
import LarkContainer
import BootManager
import LarkAssembler
import LarkSecurityComplianceInfra
import LarkSetting

final class EncryptionUpgradePredecessorTask: UserFlowBootTask, Identifiable {
    static var identify = "EncryptionUpgradePredecessorTask"
    override var runOnlyOnceInUserScope: Bool {
        return true
    }

    override func execute() throws {
        Logger.info("encryptionUpgrade predecessor task executed")
        let predecessor = try userResolver.resolve(assert: EncryptionUpgradePredecessorProtocol.self)
        predecessor.process()
    }
}
