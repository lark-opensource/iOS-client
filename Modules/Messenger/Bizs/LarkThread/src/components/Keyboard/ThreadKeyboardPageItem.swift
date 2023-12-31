//
//  ThreadKeyboardPageItem.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkModel
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkCore
import RustPB
import LarkSendMessage
import LarkMessageBase

struct ThreadKeyboardPageItem {
    static let key = "ThreadKeyboardPageItem"
    static let iconColor = UIColor.ud.iconN2

    var thread: RustPB.Basic_V1_Thread {
        return threadWrapper.thread.value
    }

    weak var keyboardView: IMKeyBoardView?
    let threadWrapper: ThreadPushWrapper
    var getReplyMessage: (() -> Message?)?
    let keyboardStatusManager: KeyboardStatusManager

    init(threadWrapper: ThreadPushWrapper,
         keyboardView: IMKeyBoardView,
         keyboardStatusManager: KeyboardStatusManager,
         getReplyMessage: (() -> Message?)?) {
        self.threadWrapper = threadWrapper
        self.getReplyMessage = getReplyMessage
        self.keyboardView = keyboardView
        self.keyboardStatusManager = keyboardStatusManager
    }
}

protocol ThreadKeyboardViewPageItemProtocol: BaseKeyboardPanelSubItemModule<KeyboardContext, IMKeyboardMetaModel> {
    var threadPageItem: ThreadKeyboardPageItem? { get }
    func defaultSendContext() -> APIContext
    func trackReplyMsgSend(state: SendMessageState, chatModel: Chat?)
}

extension ThreadKeyboardViewPageItemProtocol {
    var threadPageItem: ThreadKeyboardPageItem? {
        let item: ThreadKeyboardPageItem? = context.store.getValue(for: ThreadKeyboardPageItem.key)
        if item == nil {
            assertionFailure("may be some things error")
        }
        return item
    }

    func trackReplyMsgSend(state: SendMessageState, chatModel: Chat?) {
        if case .finishSendMessage(_, _, _, _, _) = state {
            self.trackReplyThreadClick(.reply, chatModel: chatModel)
        }
    }

    private func trackReplyThreadClick(_ type: ThreadTracker.ReplyThreadClickType, chatModel: Chat?) {
        guard let rootMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = chatModel else { return  }
        ThreadTracker.trackReplyThreadClick(chat: chat,
                                            message: rootMessage,
                                            clickType: .reply,
                                            threadId: !rootMessage.threadId.isEmpty ? rootMessage.threadId : rootMessage.id,
                                            inGroup: true)
    }

    func defaultSendContext() -> APIContext {
        let context = APIContext(contextID: "")
        context.set(key: APIContext.anonymousKey, value: false)
        context.set(key: APIContext.replyInThreadKey, value: true)
        return context
    }
}
