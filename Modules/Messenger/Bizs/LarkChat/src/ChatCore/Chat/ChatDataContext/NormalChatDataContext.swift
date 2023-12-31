//
//  NormalChatDataContext.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import LarkCore
import LarkModel

class NormalChatDataContext: ChatDataContextProtocol {
    let identify = "NormalChatDataContext"

    private let chatWrapper: ChatPushWrapper
    var chat: Chat {
        return self.chatWrapper.chat.value
    }

    var firstMessagePosition: Int32 {
        return self.chat.firstMessagePostion
    }

    var lastMessagePosition: Int32 {
        return self.chat.lastMessagePosition
    }

    var lastVisibleMessagePosition: Int32 {
        return self.chat.lastVisibleMessagePosition
    }

    var readPositionBadgeCount: Int32 {
        return self.chat.readPositionBadgeCount
    }

    var readPosition: Int32 {
        return self.chat.readPosition
    }

    var lastReadPosition: Int32 {
        return self.chat.lastReadPosition
    }

    init(chatWrapper: ChatPushWrapper) {
        self.chatWrapper = chatWrapper
    }
}
