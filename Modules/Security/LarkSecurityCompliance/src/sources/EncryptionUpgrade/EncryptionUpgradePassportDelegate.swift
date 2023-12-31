//
//  EncryptionUpgradePassportDelegate.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/22.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import RxSwift
import RxCocoa
import LarkSecurityComplianceInfra

final class EncryptionUpgradeUserStateDelegate: PassportDelegate {
    private let container: Container

    let name: String = "EncryptionUpgradeUserStateDelegate"

    init(container: Container) {
        self.container = container
    }

    func userDidOnline(state: PassportState) {
        guard state.loginState == .online,
              let userId = state.user?.userID else { return }
        do {
            let userResolver = try container.getUserResolver(userID: userId)
            let predecessor = try userResolver.resolve(assert: EncryptionUpgradePredecessorProtocol.self)
            predecessor.updateUserList()
        } catch {
            Logger.error("passportDelegate error: \(error)")
        }
    }
}
