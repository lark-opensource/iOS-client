//
//  CopyableLabel.swift
//  Calendar
//
//  Created by zhouyuan on 2018/12/14.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
import LarkEMM
import UniverseDesignToast
import LarkSensitivityControl

open class CopyableLabel: UILabel, UIGestureRecognizerDelegate {

    private let highlitedView = UIView()
    private var didShowCopy: (() -> Void)?
    public init(isCopyable: Bool, didShowCopy: (() -> Void)? = nil) {
        super.init(frame: .zero)
        if isCopyable {
            attachLongHandle()
            self.didShowCopy = didShowCopy
            self.addSubview(highlitedView)
            highlitedView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.6)
            highlitedView.isHidden = true
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var canBecomeFirstResponder: Bool {
        return true
    }

    private func attachLongHandle() {
        NotificationCenter.default.addObserver(self, selector: #selector(menuControllerWillHide),
                                               name: UIMenuController.willHideMenuNotification,
                                               object: nil)
        isUserInteractionEnabled = true
        let longPress = UILongPressGestureRecognizer(target: self,
                                                     action: #selector(showMenu(sender:)))
        addGestureRecognizer(longPress)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        highlitedView.frame = textFrame()
    }

    private func textFrame() -> CGRect {
        return CGRect(origin: CGPoint(x: 0, y: 0), size: self.intrinsicContentSize)
    }

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        let textRect = textFrame()
        return textRect.contains(point)
    }

    @objc
    func menuControllerWillHide() {
        highlitedView.isHidden = true
    }

    @objc
    func copyText(_ sender: Any?) {
        do {
            let config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.copyableLabelCopy)))
            try SCPasteboard.generalUnsafe(config).string = text
            if let window = self.window {
                UDToast.showSuccess(with: I18n.Calendar_Share_LinkCopied, on: window)
            }
        } catch {
            SCPasteboardUtils.logCopyFailed()
            if let window = self.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Share_UnableToCopy, on: window)
            }
        }
        UIMenuController.shared.setMenuVisible(false, animated: true)
        highlitedView.isHidden = true
    }

    @objc
    func showMenu(sender: UIGestureRecognizer) {
        becomeFirstResponder()
        didShowCopy?()
        highlitedView.isHidden = false
        let menu = UIMenuController.shared
        menu.menuItems = [UIMenuItem(title: BundleI18n.Calendar.Calendar_Common_Copy, action: #selector(copyText(_:)))]
        if !menu.isMenuVisible {
            let point = sender.location(in: self)
            let rect = CGRect(x: point.x, y: 0, width: 1, height: self.bounds.height)
            menu.setTargetRect(rect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(copyText(_:)))
    }

    deinit {
        self.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
}
