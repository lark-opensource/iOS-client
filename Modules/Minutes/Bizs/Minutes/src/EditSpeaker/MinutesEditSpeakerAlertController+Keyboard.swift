//
//  MinutesEditSpeakerAlertController.swift
//  Minutes
//
//  Created by panzaofeng on 2022/1/4.
//

import UIKit
import MinutesFoundation

extension MinutesEditSpeakerAlertController {
    @objc
    func keyboardWillShowAction(_ notification: Notification) {
        MinutesLogger.detail.info("=====> keyboard: Show Action")
        guard let userInfo = notification.userInfo else {
            return
        }

        if let keyboardSize = (userInfo[MinutesEditSpeakerAlertController.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
           let duration = userInfo[MinutesEditSpeakerAlertController.keyboardAnimationDurationUserInfoKey] as? Double,
           let curveRawValue = userInfo[MinutesEditSpeakerAlertController.keyboardAnimationCurveUserInfoKey] as? Int,
           let curve = UIView.AnimationCurve(rawValue: curveRawValue) {
            var defaultDuration = 0.25
            let keyBoardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? defaultDuration
            self.bottomBar.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                maker.bottom.equalToSuperview().inset(keyboardSize.size.height)
            }

            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc
    func keyboardWillHideAction(_ notification: Notification) {
        MinutesLogger.detail.info("=====> keyboard: Hide Action")
        hideKeyboard()
    }

    func hideKeyboard() {
        self.bottomBar.frame.origin.y = self.tableView.frame.origin.y + self.tableView.bounds.size.height
        bottomBar.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

}
