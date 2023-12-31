//
//  BaseChatKeyboardSubModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2021/12/24.
//

import Foundation
import LarkOpenIM

open class BaseChatKeyboardSubModule: Module<ChatKeyboardContext, ChatKeyboardMetaModel> {
    /// 「+」号菜单 Item
    open var moreItems: [ChatKeyboardMoreItem] {
        return []
    }

    open func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        assertionFailure("must override")
    }

    /// input handler
    open var inputHandlers: [ChatKeyboardInputOpenProtocol] {
        return []
    }

    open func createInputHandlers(metaModel: ChatKeyboardMetaModel) {}
}

open class NormalChatKeyboardSubModule: BaseChatKeyboardSubModule {
}

open class CryptoChatKeyboardSubModule: BaseChatKeyboardSubModule {
}
