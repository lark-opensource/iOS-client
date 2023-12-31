//
//  KeyboardContext.swift
//  LarkOpenChat
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkOpenIM
import Swinject
import EditTextView
import LarkKeyboardView
import LarkContainer

open class KeyboardContext: BaseModuleContext {
    public var inputTextView: LarkEditTextView {
        return self.resolver.resolve(OpenKeyboardService.self)!.inputTextView
    }

    public var keyboardPanel: KeyboardPanel {
        return self.resolver.resolve(OpenKeyboardService.self)!.inputKeyboardPanel
    }

    public var displayVC: UIViewController {
        return self.resolver.resolve(OpenKeyboardService.self)!.displayVC()
    }

    public var inputProtocolSet: TextViewInputProtocolSet? {
        return self.resolver.resolve(OpenKeyboardService.self)?.inputProtocolSet
    }

    public func keyboardAppearForSelectedPanel(item: KeyboardItemKey) {
        self.resolver.resolve(OpenKeyboardService.self)?.keyboardAppearForSelectedPanel(item: item)
    }

    public func reloadPaneItems() {
        (try? self.resolver.resolve(assert: OpenKeyboardService.self))?.reloadPaneItems()
    }

    public func reloadPaneItemForKey(_ key: KeyboardItemKey) {
        (try? self.resolver.resolve(assert: OpenKeyboardService.self))?.reloadPaneItemForKey(key)
    }

    public func foldKeyboard() {
        (try? self.resolver.resolve(assert: OpenKeyboardService.self))?.foldKeyboard()
    }
}
