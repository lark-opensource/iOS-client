//
//  EncryptionUpgradeStorage.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/21.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra

// ignoring lark storage check for rekey beforehand
// lint:disable lark_storage_check

final class EncryptionUpgradeStorage {

    private let encryptionUpgradeShouldRekey = "encryption_upgrade_should_rekey".md5()
    private let encryptionUpgradeShouldSkipOnce = "encryption_upgrade_should_skip_once".md5()
    private let encryptionUpgradeEta = "encryption_upgrade_eta".md5()
    private let encryptionUpgradeUserList = "encryption_upgrade_user_list".md5()
    private let encryptionUpgradeIsUpgraded = "encryption_upgrade_is_upgraded".md5()
    private let encryptionUpgradeForceFail = "encryption_upgrade_force_fail".md5()

    private let globalMMKV = SCKeyValue.globalMMKVEncrypted()

    static let shared: EncryptionUpgradeStorage = EncryptionUpgradeStorage()

    func updateShouldRekey(value: Bool) {
        Logger.info("store set shouldRekey:\(value)")
        UserDefaults.standard.set(value, forKey: encryptionUpgradeShouldRekey)
    }

    func updateShouldSkipOnce(value: Bool) {
        Logger.info("store set shouldSkip:\(value)")
        UserDefaults.standard.set(value, forKey: encryptionUpgradeShouldSkipOnce)
    }

    func updateEta(value: Int) {
        Logger.info("store set eta:\(value)")
        globalMMKV.set(value, forKey: encryptionUpgradeEta)
    }

    func updateUserList(value: [String]) {
        Logger.info("store set userList:\(value)")
        globalMMKV.set(value, forKey: encryptionUpgradeUserList)
    }

    func updateIsUpgraded(value: Bool) {
        Logger.info("store set isUpgraded:\(value)")
        globalMMKV.set(value, forKey: encryptionUpgradeIsUpgraded)
    }

    func mockForceFailure(_ value: Bool) {
        globalMMKV.set(value, forKey: encryptionUpgradeForceFail)
    }

    var forceFailure: Bool {
        globalMMKV.value(forKey: encryptionUpgradeForceFail) ?? false
    }

    var shouldRekey: Bool {
        UserDefaults.standard.bool(forKey: encryptionUpgradeShouldRekey)
    }

    var shouldSkipOnce: Bool {
        UserDefaults.standard.bool(forKey: encryptionUpgradeShouldSkipOnce)
    }

    var eta: Int {
        globalMMKV.value(forKey: encryptionUpgradeEta) ?? 0
    }

    var userList: [String] {
        globalMMKV.value(forKey: encryptionUpgradeUserList) ?? []
    }

    var isUpgraded: Bool {
        globalMMKV.value(forKey: encryptionUpgradeIsUpgraded) ?? false
    }
}
