//
//  EncryptionUpgradeService.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/11.
//

import Foundation
import LarkSecurityComplianceInfra

protocol EncryptionUpgradeService {
    func startDatabseRekeyVC() -> EncryptionUpgradeViewController
    func isRekeyNeeded() throws -> PrecheckResult
    var isRekeying: Bool { get }
    var isEncryptionUpgradeViewShowing: Bool { get }
}

struct PrecheckResult {
    let needUpgrade: Bool
    let eta: Int
}

final class EncryptionUpgradeServiceImp: EncryptionUpgradeService {

    private let rustApi: EncryptionUpgradeRustApi

    private weak var viewController: EncryptionUpgradeViewController?

    init() {
        rustApi = EncryptionUpgradeRustApi()
    }

    func startDatabseRekeyVC() -> EncryptionUpgradeViewController {
        let vm = EncryptionUpgradeViewModel(rustApi: rustApi)
        let vc = EncryptionUpgradeViewController(viewModel: vm)
        self.viewController = vc
        return vc
    }

    func isRekeyNeeded() throws -> PrecheckResult {
        let precheckResult = try rustApi.databaseRekeyPrecheck()
        return precheckResult
    }

    var isRekeying: Bool {
        (viewController?.isRekeyInProgress).isTrue
    }

    var isEncryptionUpgradeViewShowing: Bool {
        (viewController?.isViewLoaded).isTrue && viewController?.view.window != nil
    }

}
