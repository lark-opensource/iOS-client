//
//  ToOriginal.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/16.
//

import Foundation
import LarkModel
import LarkOpenChat
import UniverseDesignToast
import EENavigator
import LarkMessengerInterface

public final class ToOriginalMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .toOriginal
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    private func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        let body = ChatControllerByBasicInfoBody(
            chatId: chat.id,
            positionStrategy: .position(message.position),
            messageId: message.id,
            isCrypto: chat.isCrypto,
            isMyAI: chat.isP2PAi,
            chatMode: chat.chatMode
        )
        self.context.nav.push(body: body, from: targetVC)
        MenuTracker.trackViewInChat(isCrypto: chat.isCrypto)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return model.message.threadMessageType != .threadReplyMessage
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Message_ThreadMessageActionViewInChat,
                                 icon: BundleResources.Menu.menu_to_original,
                                 trackExtraParams: ["click": "back_to_chat", "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}
