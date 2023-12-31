//
//  KeyboardContainerProtocol.swift
//  LarkOpenKeyboard
//
//  Created by liluobin on 2023/4/20.
//

import UIKit
import LarkKeyboardView
import UniverseDesignColor

public protocol KeyboardContainerProtocol: AnyObject, OpenKeyboardService {
    /// 缓存使用的View，比如emoji面板 节省性能
    var keyboardViewCache: [Int: UIView] { get set }

    /// 键盘上的按钮 panel items
    var keyboardItems: [InputKeyboardItem] { get }

    ///keyboardItems 发生变化时候触发 比如：可以在keyboardItems的didSet方法中使用
    ///该方法会根据keyboardItems中的配置，重新刷新按钮
    func onkeyboardItemsUpdate()
}

public extension KeyboardContainerProtocol {

    // MARK: - UITextViewDelegate
    func kbc_textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let inputProtocolSet = self.inputProtocolSet  else {
            return true
        }
        return inputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    func kbc_textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    func kbc_textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !self.inputKeyboardPanel.observeKeyboard {
            self.inputKeyboardPanel.resetContentHeight()
        }
        self.inputKeyboardPanel.observeKeyboard = true
        return true
    }

    func kbc_textViewDidEndEditing(_ textView: UITextView) {
        self.inputKeyboardPanel.observeKeyboard = false
        if self.inputKeyboardPanel.selectIndex == nil {
            self.inputKeyboardPanel.closeKeyboardPanel(animation: true)
        }
    }

    func kbc_textViewDidChange(_ textView: UITextView) {
        self.inputProtocolSet?.textViewDidChange(textView)
    }

    func onkeyboardItemsUpdate() {
        self.keyboardViewCache.removeAll()
        self.inputKeyboardPanel.reloadPanel()
    }

    func kbc_keyboardItemOnTap(index: Int, key: String) -> (KeyboardPanelEvent) -> Void {
        return keyboardItems[index].onTapped
    }

    func kbc_keyboardItemKey(index: Int) -> String {
        return keyboardItems[index].key
    }

    func kbc_keyboardViewCoverSafeArea(index: Int, key: String) -> Bool {
        return keyboardItems[index].coverSafeArea
    }

    func kbc_numberOfKeyboard() -> Int {
        return keyboardItems.count
    }

    func kbc_keyboardIcon(index: Int, key: String) -> (UIImage?, UIImage?, UIImage?) {
        return keyboardItems[index].keyboardIcon
    }

    func kbc_willSelected(index: Int, key: String) -> Bool {
        if let action = keyboardItems[index].selectedAction {
            return action()
        }
        return true
    }

    func kbc_didSelected(index: Int, key: String) {
        inputTextView.resignFirstResponder()
        self.inputKeyboardPanel.contentWrapper.backgroundColor = key == KeyboardItemKey.picture.rawValue ? UIColor.ud.bgBody : .clear
    }

    func kbc_closeKeyboardPanel() {
        self.inputKeyboardPanel.contentWrapper.backgroundColor = .clear
    }

    func kbc_keyboardView(index: Int, key: String) -> (UIView, Float) {
        let item = keyboardItems[index]
        let height = item.keyboardHeightBlock()
        if let keyboardView = keyboardViewCache[index] {
            return (keyboardView, height)
        }
        let keyboardView = item.keyboardViewBlock()
        keyboardViewCache[index] = keyboardView
        return (keyboardView, height)
    }

    func kbc_keyboardIconBadge(index: Int, key: String) -> KeyboardIconBadgeType {
        return keyboardItems[index].badgeTypeBlock()
    }
}
