//
//  BaseKeyboardPanelSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkOpenKeyboard
import LarkKeyboardView
import LarkOpenIM

open class BaseKeyboardPanelDefaultSubModule <C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelSubItemModule<C, M> {

    public var item: InputKeyboardItem?

    open var metaModel: M?

    open override func createItem() {
        guard item == nil else { return }
        self.item = didCreatePanelItem()
    }

    open override func modelDidChange(model: M) {
        metaModel = model
    }

    open override func handler(model: M) -> [Module<C, M>] {
        metaModel = model
        return super.handler(model: model)
    }

    open override func getItems() -> [InputKeyboardItem] {
        return item != nil ? [item!] : []
    }

    open func didCreatePanelItem() -> InputKeyboardItem? {
        return nil
    }

    open func foldKeyboard() {
        self.context.foldKeyboard()
    }

    open func reloadItemKeyboardIconIcons(_ keyboardIcon: (UIImage?, UIImage?, UIImage?)) {
        self.item?.keyboardIcon = keyboardIcon
        self.context.reloadPaneItemForKey(panelItemKey)
    }
}
