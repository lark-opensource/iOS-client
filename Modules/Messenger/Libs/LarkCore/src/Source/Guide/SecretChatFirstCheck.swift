//
//  SecretChatFirstCheck.swift
//  Pods
//
//  Created by chengzhipeng-bytedance on 2018/9/17.
//

import UIKit
import Foundation
import LarkUIKit
import LarkAlertController
import EENavigator

open class SecretChatFirstCheck {

    static func checkIsFirstSecretChat() -> Bool {
        return KVStore.secretChatNotFirst == false
    }

    static func setSecretChatWhenFirstEnter() {
        KVStore.secretChatNotFirst = true
    }

    public static func showSecretChatNoticeIfNeeded(
        navigator: Navigatable,
        targetVC: UIViewController,
        cancelAction: (() -> Void)?,
        okAction: (() -> Void)?) {
        if SecretChatFirstCheck.checkIsFirstSecretChat() {
            let wrapperView = UIView()
            let contentLabel = UILabel()
            contentLabel.font = UIFont.systemFont(ofSize: 16)
            contentLabel.textColor = UIColor.ud.N900
            contentLabel.textAlignment = .left
            contentLabel.text = BundleI18n.LarkCore.Lark_Legacy_SecretChatNote
            contentLabel.numberOfLines = 0
            wrapperView.addSubview(contentLabel)
            contentLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.width.lessThanOrEqualTo(270)
            }
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkCore.Lark_Legacy_SecretChatNote, alignment: .left)
            alertController.addSecondaryButton(text: BundleI18n.LarkCore.Lark_Legacy_NotNow, dismissCompletion: {
                cancelAction?()
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkCore.Lark_Legacy_AgreeAndUse, dismissCompletion: {
                okAction?()
                SecretChatFirstCheck.setSecretChatWhenFirstEnter()
            })
            navigator.present(alertController, from: targetVC)
        } else {
            okAction?()
        }
    }
}
