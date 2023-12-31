//
//  EncryptionUpgradeAssembly.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/11.
//

import Foundation
import LarkContainer
import BootManager
import LarkAssembler
import LarkRustClient
import LarkAccountInterface
import LarkSecurityComplianceInfra

final class EncryptionUpgradeAssembly: LarkAssemblyInterface {
    func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)

        container.register(EncryptionUpgradeService.self) { _ in // Global
            EncryptionUpgradeServiceImp()
        }

        userContainer.register(EncryptionUpgradePredecessorProtocol.self) { resolver in
            try EncryptionUpgradePredecessor(userResolver: resolver)
        }
    }

    func registLaunch(container: Container) {
        NewBootManager.register(EncryptionUpgradePrecheckTask.self)
        NewBootManager.register(EncryptionUpgradeTask.self)
        NewBootManager.register(EncryptionUpgradePredecessorTask.self)
    }

    func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            EncryptionUpgradeUserStateDelegate(container: container)
        }), PassportDelegatePriority.low)
    }
}
