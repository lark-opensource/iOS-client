//
//  KeyboardImageContainerProtocol.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/5/12.
//

import UIKit
import LarkOpenKeyboard

public protocol KeyboardImageContainerProtocol: KeyboardContainerProtocol {

    var editTextViewWidth: CGFloat { get set }

    func getPostAttachmentServer() -> PostAttachmentServer?

    func kbc_viewDidAppear(_ animated: Bool)

    func kbc_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)

    func kbc_splitSplitModeChange()
}

public extension KeyboardImageContainerProtocol {

    func kbc_viewDidAppear(_ animated: Bool) {
        self.editTextViewWidth = self.displayVC().view.bounds.width
    }

    func kbc_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.resizeAttachmentView(toSize: size)
        }, completion: nil)
    }

    func kbc_splitSplitModeChange() {
        self.resizeAttachmentView(toSize: self.displayVC().view.bounds.size)
    }

    /// resize when vc rotation
    func resizeAttachmentView(toSize: CGSize) {
        if toSize.width == self.editTextViewWidth {
            return
        }
        self.editTextViewWidth = toSize.width
        self.getPostAttachmentServer()?.resizeAttachmentView(textView: self.inputTextView,
                                               toSize: toSize)
    }

}
