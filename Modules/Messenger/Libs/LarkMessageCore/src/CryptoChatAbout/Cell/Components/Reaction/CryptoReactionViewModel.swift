//
//  CryptoReactionViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/11/21.
//

import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LKCommonsLogging

class CryptoReactionViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReactionViewModelContext & PageContext>: ReactionViewModel<M, D, C> {
    public override func getReactionChatterDisplayName(_ chatter: Chatter) -> String {
        let chat = self.metaModel.getChat()
        if chat.type == .p2P, !self.context.isMe(chatter.id, chat: chat) {
            return BundleI18n.LarkMessageCore.Lark_IM_SecureChatUser_Title
        } else {
            let displayName = chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .reaction)
            if displayName.isEmpty {
                ReactionViewModelLogger.logger.error(
                    """
                    reaction: displayName is empty:
                    \(chatter.chatExtraChatID ?? "chatExtraChatID is empty")
                    \(chat.id)
                    \(chat.type)
                    \(chatter.id)
                    \(chatter.alias.count)
                    \(chatter.localizedName.count)
                    \(chatter.nickName?.count ?? 0)
                    """
                )
            }
            return displayName
        }
    }
}
