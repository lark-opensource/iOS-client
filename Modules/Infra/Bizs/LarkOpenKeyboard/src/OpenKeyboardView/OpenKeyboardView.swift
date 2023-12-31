//
//  OpenKeyboardView.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkKeyboardView
import LarkContainer

open class OpenKeyboardView<C: KeyboardContext, M: KeyboardMetaModel>: LKKeyboardView, ResolverWrapper {
    public var resolver: Resolver { openViewModel.resolver }

    let openViewModel: OpenKeyboardViewModel<C, M>

    public var module: BaseKeyboardModule<C, M> {
        return openViewModel.module
    }

    public init(frame: CGRect,
                config: KeyboardLayouConfig,
                viewModel: OpenKeyboardViewModel<C, M>,
         keyboardNewStyleEnable: Bool = false) {
        self.openViewModel = viewModel
        super.init(frame: frame, config: config, keyboardNewStyleEnable: keyboardNewStyleEnable)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func didLayoutPanelIcon() {
        super.didLayoutPanelIcon()
        self.openViewModel.module.keyboardPanelDidLayoutIcon()
    }
}
