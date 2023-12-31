//
//  EncryptionUpgradeStateInProgress.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/15.
//

import Foundation
import UniverseDesignProgressView
import UniverseDesignButton
import RxSwift
import RxCocoa

final class EncryptionUpgradeStateInProgress: EncryptionUpgradeState {

    private var isDarkMode = false

    var state: EncryptionUpgrade.State { .inProgress }

    var image: UIImage {
        isDarkMode ? BundleResources.LarkSecurityCompliance.Encryption_upgrade.negative_upgrading :
        BundleResources.LarkSecurityCompliance.Encryption_upgrade.positive_upgrading
    }

    var title: String { BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SecurityUpdateTitle }

    var text: String { updateText(eta: EncryptionUpgradeStorage.shared.eta) }

    var textSignal: Driver<String> { textSubject.asDriverOnErrorJustComplete() }

    let progressBar = UDProgressView(config: .init(showValue: true),
                                     layoutConfig: .init(valueLabelWidth: 27,
                                                         valueLabelHeight: 18))

    private let textSubject = PublishSubject<String>()

    private func updateText(eta: Int) -> String {
        eta < 60 ? BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SecurityUpdateDescription(
            eta,
            BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SecondTitle
        ) : BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SecurityUpdateDescription(
            eta / 60,
            BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_MinuteTitle
        )
    }

    func hide() {
        progressBar.isHidden = true
        rightCornerSkipButton.isHidden = true
    }

    func show() {
        progressBar.reset()
        textSubject.onNext(updateText(eta: 0))
        progressBar.isHidden = false
        rightCornerSkipButton.isHidden = false
    }

    func onThemeChange(withDarkMode: Bool) {
        isDarkMode = withDarkMode
    }

    var progress: EncryptionUpgrade.Progress = EncryptionUpgrade.Progress(percentage: 0, eta: 0) {
        didSet {
            progressBar.setProgress(CGFloat(progress.percentage) / 100.0, animated: true)
            textSubject.onNext(updateText(eta: progress.eta))
        }
    }

    let rightCornerSkipButton: UIButton = {
        let button = UDButton.textBlue
        button.titleLabel?.font = UIFont.ud.body0
        button.setTitle(BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipButton, for: .normal)
        return button
    }()
}

extension UDProgressView {
    func reset() {
        self.setProgress(0.0, animated: false)
    }
}
