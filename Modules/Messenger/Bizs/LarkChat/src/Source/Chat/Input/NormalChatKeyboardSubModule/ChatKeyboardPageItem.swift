//
//  ChatKeyboardPageItem.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/7.
//

import UIKit
import LarkChatOpenKeyboard
import LarkMessengerInterface
import LarkMessageCore
import LarkModel
import LarkOpenKeyboard
import LarkMessageBase

struct ChatKeyboardViewPageItem {
    static let key = "ChatKeyboardViewPageItem"
    weak var keyboardView: IMKeyBoardView?
    let keyboardStatusManager: KeyboardStatusManager
    let supportAtMyAI: Bool
    let chatFromWhere: ChatFromWhere?
    var getReplyInfo: (() -> KeyboardJob.ReplyInfo?)?
    var afterSendMessage: (() -> Void)?

    init(keyboardView: IMKeyBoardView,
         keyboardStatusManager: KeyboardStatusManager,
         chatFromWhere: ChatFromWhere?,
         supportAtMyAI: Bool,
         getReplyInfo: (() -> KeyboardJob.ReplyInfo?)?,
         afterSendMessage: (() -> Void)?) {
        self.keyboardView = keyboardView
        self.getReplyInfo = getReplyInfo
        self.afterSendMessage = afterSendMessage
        self.keyboardStatusManager = keyboardStatusManager
        self.supportAtMyAI = supportAtMyAI
        self.chatFromWhere = chatFromWhere
    }
}

protocol ChatKeyboardViewPageItemProtocol: BaseKeyboardPanelSubItemModule<KeyboardContext, IMKeyboardMetaModel> {
    var chatPageItem: ChatKeyboardViewPageItem? { get }
}

extension ChatKeyboardViewPageItemProtocol {
    var chatPageItem: ChatKeyboardViewPageItem? {
        let item: ChatKeyboardViewPageItem? = context.store.getValue(for: ChatKeyboardViewPageItem.key)
        if item == nil {
            assertionFailure("may be error")
        }
        return item
    }
}
