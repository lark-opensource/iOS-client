//
//  CryptoRecalledSystemCellViewModel.swift
//  LarkChat
//
//  Created by qihongye on 2023/8/17.
//

import Foundation
import LarkModel
import LarkMessageCore
import LarkCore

final class CryptoRecalledSystemCellViewModel<C: RecalledSystemCellContext>: RecalledSystemCellViewModel<C> {
    override func getChatterDisplayName(chatter: Chatter) -> String {
        if metaModel.getChat().type == .p2P {
            return BundleI18n.LarkChat.Lark_IM_SecureChatUser_Title
        }
        return chatter.displayName(
            chatId: message.channel.id,
            chatType: .group,
            scene: .groupOwnerRecall
        )
    }
}
