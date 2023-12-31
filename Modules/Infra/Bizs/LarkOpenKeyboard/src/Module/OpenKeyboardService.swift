//
//  OpenKeyboardService.swift
//  LarkOpenChat
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkKeyboardView
import EditTextView

public protocol OpenKeyboardService {
    var inputTextView: LarkEditTextView { get }
    var inputKeyboardPanel: KeyboardPanel { get }
    var inputProtocolSet: TextViewInputProtocolSet? { get }
    func displayVC() -> UIViewController
    func reloadPaneItems()
    func reloadPaneItemForKey(_ key: KeyboardItemKey)
    func keyboardAppearForSelectedPanel(item: KeyboardItemKey)
    func foldKeyboard()
}

extension OpenKeyboardService {
    public func foldKeyboard() {
        self.inputKeyboardPanel.superview?.endEditing(true)
        self.inputKeyboardPanel.closeKeyboardPanel(animation: true)
    }
}

open class OpenKeyboardServiceEmptyIMP: OpenKeyboardService {
    public var inputTextView: LarkEditTextView { LarkEditTextView() }
    public var inputKeyboardPanel: KeyboardPanel { KeyboardPanel() }
    public var inputProtocolSet: TextViewInputProtocolSet? { nil }
    public init() {}
    public func displayVC() -> UIViewController { UIViewController() }
    public func keyboardAppearForSelectedPanel(item: KeyboardItemKey) {}
    public func reloadPaneItems() {}
    public func reloadPaneItemForKey(_ key: KeyboardItemKey) {}
}
