//
//  IMComposePageItem.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/20.
//

import UIKit
import LarkMessengerInterface
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkCore
import LarkBaseKeyboard
import LarkMessageBase
import RustPB
import LarkModel

class ComposeKeyboardPageItem {

    static let key = "ComposeKeyboardPageItem"
    static let iconColor = UIColor.ud.iconN2
    let chatFromWhere: ChatFromWhere?
    var isFromMsgThread: Bool
    let attachmentServer: PostAttachmentServer
    var supportAtMyAI: Bool

    init(chatFromWhere: ChatFromWhere?, isFromMsgThread: Bool, attachmentServer: PostAttachmentServer, supportAtMyAI: Bool) {
        self.chatFromWhere = chatFromWhere
        self.attachmentServer = attachmentServer
        self.isFromMsgThread = isFromMsgThread
        self.supportAtMyAI = supportAtMyAI
    }
}

protocol ComposeKeyboardViewPageItemProtocol: BaseKeyboardPanelSubItemModule<IMComposeKeyboardContext, IMKeyboardMetaModel> {
    var pageItem: ComposeKeyboardPageItem? { get }
}

extension ComposeKeyboardViewPageItemProtocol {
    var pageItem: ComposeKeyboardPageItem? {
        let item: ComposeKeyboardPageItem? = context.store.getValue(for: ComposeKeyboardPageItem.key)
        if item == nil {
            assertionFailure("may be some things error")
        }
        return item
    }

    func getThreadIdForChat(_ chat: Chat?, keyboardStatusManager: KeyboardStatusManager) -> String? {
        if chat?.chatMode == .threadV2 {
            switch keyboardStatusManager.currentKeyboardJob {
            case .multiEdit(let message):
                return message.parentMessage?.id ?? message.id
            case .reply(let info):
                return info.message.id
            default:
                return nil
            }
        }
        return nil
    }
}
