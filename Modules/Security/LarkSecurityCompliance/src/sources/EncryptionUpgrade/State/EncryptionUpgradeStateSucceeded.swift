//
//  EncryptionUpgradeStateSucceeded.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/15.
//

import Foundation
import UniverseDesignProgressView
import UniverseDesignColor
import UniverseDesignIcon

final class EncryptionUpgradeStateSucceeded: EncryptionUpgradeState {
    var state: EncryptionUpgrade.State { .succeeded }

    private var isDarkMode: Bool = false

    var image: UIImage {
        isDarkMode ? BundleResources.LarkSecurityCompliance.Encryption_upgrade.negative_succeess :
        BundleResources.LarkSecurityCompliance.Encryption_upgrade.positive_success
    }

    var title: String { BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_UpdateDoneTitle }

    var text: String { BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_UpdateDoneDescript }

    func hide() {
        progressBar.isHidden = true
        checkBoxView.isHidden = true
        loadingLabel.isHidden = true
    }

    func show() {
        progressBar.isHidden = false
        progressBar.setProgress(1.0, animated: false)
        checkBoxView.isHidden = false
        loadingLabel.isHidden = false
    }

    func onThemeChange(withDarkMode: Bool) {
        isDarkMode = withDarkMode
    }

    let progressBar: UDProgressView = {
        let bar = UDProgressView(layoutConfig: .init(linearSmallCornerRadius: 2,
                                                     linearProgressDefaultHeight: 4))
        bar.isHidden = true
        return bar
    }()

    let checkBoxView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UDIcon.getIconByKey(UDIconType.succeedColorful)
        imgView.isHidden = true
        return imgView
    }()

    let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_LoadingTitle
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
}
