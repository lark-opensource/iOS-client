//
//  ComposePostVC+Delegate.swift
//  Lark
//
//  Created by lichen on 2018/5/23.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import EENavigator
import Foundation
import LarkAlertController
import LarkCanvas
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import LarkEmotion
import LarkEmotionKeyboard
import LarkSetting
import LarkFoundation
import LarkKeyboardKit
import LarkMessageBase
import LarkModel
import LarkSDKInterface
import LarkUIKit
import Photos
import UniverseDesignToast
import RxCocoa
import RxSwift
import LarkMessengerInterface
import ByteWebImage
import RustPB
import LarkContainer
import LKCommonsLogging
import Heimdallr
import LarkSendMessage
import LarkBaseKeyboard

// MARK: - KeyboardPanelDelegate
extension ComposePostViewController: KeyboardPanelDelegate {
    public func didLayoutPanelIcon() {
        self.viewModel.module.keyboardPanelDidLayoutIcon()
    }

    public func keyboardItemOnTap(index: Int, key: String) -> (KeyboardPanelEvent) -> Void {
        return self.kbc_keyboardItemOnTap(index: index, key: key)
    }

    public func keyboardItemKey(index: Int) -> String {
        return self.kbc_keyboardItemKey(index: index)
    }

    public func systemKeyboardPopup() {
    }

    public func keyboardContentHeightWillChange(_ height: Float) {
    }

    public func keyboardContentHeightDidChange(_ height: Float) {
    }

    public func keyboardViewCoverSafeArea(index: Int, key: String) -> Bool {
        return self.kbc_keyboardViewCoverSafeArea(index: index, key: key)
    }

    public func numberOfKeyboard() -> Int {
        return self.kbc_numberOfKeyboard()
    }

    public func keyboardIcon(index: Int, key: String) -> (UIImage?, UIImage?, UIImage?) {
        return self.kbc_keyboardIcon(index: index, key: key)
    }

    public func willSelected(index: Int, key: String) -> Bool {
        return self.kbc_willSelected(index: index, key: key)
    }

    public func didSelected(index: Int, key: String) {
        delegate?.willResignFirstResponders()
        return self.kbc_didSelected(index: index, key: key)
    }

    public func closeKeyboardPanel() {
        self.kbc_closeKeyboardPanel()
    }

    public func keyboardView(index: Int, key: String) -> (UIView, Float) {
        return self.kbc_keyboardView(index: index, key: key)
    }

    public func keyboardSelectEnable(index: Int, key: String) -> Bool {
        switch key {
        case KeyboardItemKey.emotion.rawValue,
             KeyboardItemKey.picture.rawValue,
             KeyboardItemKey.at.rawValue,
             KeyboardItemKey.canvas.rawValue,
             KeyboardItemKey.font.rawValue,
             KeyboardItemKey.burnTime.rawValue:
            return contentTextView.isFirstResponder || KeyboardKit.shared.firstResponder == nil
        case KeyboardItemKey.send.rawValue:
            return sendPostEnable()
        default:
            return true
        }
    }

    public func keyboardIconBadge(index: Int, key: String) -> KeyboardIconBadgeType {
        return self.kbc_keyboardIconBadge(index: index, key: key)
    }

    public func keyboardIconViewCustomization(index: Int, key: String, iconView: UIView) {}
}
