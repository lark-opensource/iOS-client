//
//  JumpToChatActionHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/9/24.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import LarkOpenChat

public final class JumpToChatActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType { return .jumpToChat }

    private var targetVC: UIViewController? {
        return self.context.pageAPI
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return true
    }

    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        guard let targetVC = self.targetVC else {
            assertionFailure("缺少 From VC")
            return
        }
        /// 跟产品确认 小组跳转详情页
        if chat.chatMode == .threadV2 {
            let body = ThreadDetailByIDBody(threadId: message.id, loadType: .root)
            self.context.nav.push(body: body, from: targetVC)
        } else {
            if message.position == replyInThreadMessagePosition {
                let body = ReplyInThreadByIDBody(threadId: message.threadId,
                                                 loadType: .position,
                                                 position: message.threadPosition,
                                                 sourceType: .other,
                                                 chatFromWhere: ChatFromWhere(fromValue: params[MessageMenuInfoKey.chatFromWhere] as? String) ?? .ignored)
                self.context.nav.push(body: body, from: targetVC)
                return
            }
            let body = ChatControllerByIdBody(chatId: message.channel.id,
                                              position: message.position,
                                              fromWhere: .card)
            self.context.nav.push(body: body, from: targetVC)
        }
    }
    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_JumpToChat,
                                 icon: UIImage(),
                                 trackExtraParams: ["click": "jump_to_chat",
                                                    "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat, params: [:])
        }
    }
}
