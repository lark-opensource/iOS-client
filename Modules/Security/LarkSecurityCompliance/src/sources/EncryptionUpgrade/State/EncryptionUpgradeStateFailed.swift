//
//  EncryptionUpgradeStateFailed.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/15.
//

import Foundation
import UniverseDesignButton
import UniverseDesignColor

final class EncryptionUpgradeStateFailed: EncryptionUpgradeState {
    var state: EncryptionUpgrade.State { .failed }

    private var isDarkMode = false

    var image: UIImage {
        isDarkMode ? BundleResources.LarkSecurityCompliance.Encryption_upgrade.negative_failed :
        BundleResources.LarkSecurityCompliance.Encryption_upgrade.positive_failed
    }

    var title: String { BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_UpdateFailureTitle }

    var text: String { BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_UpdateAgainOrLaterDescript() }

    func hide() {
        updateLaterButton.isHidden = true
        tryAgainButton.isHidden = true
    }

    func show() {
        updateLaterButton.isHidden = false
        tryAgainButton.isHidden = false
    }

    func onThemeChange(withDarkMode: Bool) {
        isDarkMode = withDarkMode
    }

    let updateLaterButton: UIButton = {
        let button = UDButton.secondaryGray
        button.setTitle(BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_UpdateLaterButton, for: .normal)
        button.contentHorizontalAlignment = .center
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.ud.title4
        button.isHidden = true
        return button
    }()

    let tryAgainButton: UIButton = {
        let button = UDButton.primaryBlue
        button.setTitle(BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_TryAgainButton, for: .normal)
        button.contentHorizontalAlignment = .center
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.ud.title4
        button.isHidden = true
        return button
    }()
}
