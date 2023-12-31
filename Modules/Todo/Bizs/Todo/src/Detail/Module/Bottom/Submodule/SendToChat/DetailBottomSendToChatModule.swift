//
//  DetailBottomSendToChatModule.swift
//  Todo
//
//  Created by baiyantao on 2023/3/31.
//

import Foundation
import LarkContainer
import TodoInterface

// nolint: magic number
class DetailBottomSendToChatModule: DetailBottomSubmodule {

    @ScopedInjectedLazy private var todoService: TodoService?

    private lazy var sendToChatView = initSendToChatView()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        sendToChatView.updateTitle(context.scene.sendToChatCheckboxTitle)
        sendToChatView.onToggleCheckbox = { [weak self] isSelected in
            self?.todoService?.setSendToChatIsSeleted(isSeleted: isSelected)
        }
    }

    override func bottomItems() -> [DetailBottomItem] {
        guard context.scene.isShowSendToChat else { return [] }
        // 375 是参考旧逻辑给出的，先按这个兼容方案实现，等后面重构 bottom module 的时候，需要删掉这个临时逻辑
        return [.init(view: sendToChatView, widthMode: .fixed(375))]
    }

    private func initSendToChatView() -> DetailBottomSendToChatView {
        return DetailBottomSendToChatView(
            isSelected: todoService?.getSendToChatIsSeleted() ?? true
        )
    }
}
