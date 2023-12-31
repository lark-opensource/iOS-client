//
//  OpenKeyboardViewModel.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkKeyboardView
import LarkOpenIM
import LarkContainer

// swiftlint:disable missing_docs

open class OpenKeyboardViewModel<C: KeyboardContext, M: KeyboardMetaModel>: ResolverWrapper {
    public var resolver: Resolver { module.resolver }

    public let module: BaseKeyboardModule<C, M>

    public var panelItems: [InputKeyboardItem] {
        return self.module.getPanelItems()
    }

    public init(module: BaseKeyboardModule<C, M>) {
        self.module = module
    }

    /// 业务关系metaModel改变的时候可以触发
    open func modelDidChange(model: M) {
        self.module.modelDidChange(model: model)
    }
}
