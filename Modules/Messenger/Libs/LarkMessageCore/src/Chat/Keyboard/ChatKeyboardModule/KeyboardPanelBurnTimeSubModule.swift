//
//  KeyboardPanelBurnTimeSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkOpenKeyboard
import LarkKeyboardView
import LarkOpenIM
import LarkBaseKeyboard

open class KeyboardPanelBurnTimeSubModule <C: KeyboardContext, M: KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M> {

    open override var panelItemKey: KeyboardItemKey {
        return .burnTime
    }

    public func getBurnTimeView() -> UIView? {
        return context.keyboardPanel.buttons.first { btn in
            return btn.key == KeyboardItemKey.burnTime.rawValue
        }
    }
}
