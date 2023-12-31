//
//  KeyboardPanelMoreSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/9.
//

import UIKit
import LarkOpenIM
import LarkOpenKeyboard
import LarkKeyboardView
import RxCocoa
import RxSwift

public struct KeyboardPanelMoreConfig {
    let itemsTintColor: UIColor
    let itemDriver: Driver<[BaseKeyboardMoreItem]>
    public init(itemsTintColor: UIColor,
         itemDriver: Driver<[BaseKeyboardMoreItem]>) {
        self.itemsTintColor = itemsTintColor
        self.itemDriver = itemDriver
    }
}

open class KeyboardPanelMoreSubModule<C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M> {

    public var config: KeyboardPanelMoreConfig?

    open override var panelItemKey: KeyboardItemKey {
        return .more
    }

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let config = config else {
            return nil
        }

        return LarkKeyboard.buildMore(config.itemsTintColor,
                                      { [weak self] in
            self?.context.keyboardAppearForSelectedPanel(item: .more)
            self?.buildMoreSelected()
            return true
        },
        moreItemsDriver: config.itemDriver)
    }

    open func buildMoreSelected() {
    }
}
