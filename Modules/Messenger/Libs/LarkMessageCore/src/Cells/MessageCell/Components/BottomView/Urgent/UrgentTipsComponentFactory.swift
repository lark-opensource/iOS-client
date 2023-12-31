//
//  UrgentTipsComponentFactory.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/9.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface

public protocol UrgentTipsComponentContext: UrgentTipsComponentViewModelContext { }

extension PageContext: UrgentTipsComponentContext {
}

public class UrgentTipsComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .urgentTip
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if !message.isUrgent || message.isDecryptoFail || message.isCleaned {
            return false
        }
        let chat = metaModel.getChat()
        if context.isBurned(message: metaModel.message) {
            return false
        }
        // 单聊：对方不是机器人 && 不是和自己的单聊
        let chatWithBot = chat.chatter?.type == .bot
        let chatWithSelf = context.currentChatterId == chat.chatter?.id
        if chat.type == .p2P, (chatWithBot || chatWithSelf) {
            return false
        }
        // 群聊：群成员必须大于1，群成员不包括机器人（chatterCount包含了机器人）
        if chat.type == .group, chat.userCount <= 1 {
            return false
        }
        // 必须是自己发的消息才能加急
        return context.isMe(metaModel.message.fromChatter?.id ?? "", chat: metaModel.getChat())
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return UrgentTipsComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: UrgentTipsComponentBinder<M, D, C>(context: context),
            transform: { chatters, chat in
                return chatters.map { chatter in
                    return ChatterForUrgentTip(id: chatter.id, displayName: chatter.displayName(chatId: chat.id,
                                                                                                chatType: chat.type,
                                                                                                scene: .urgentTip))
                }
            }
        )
    }

}
