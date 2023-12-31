//
//  MergeForwardPostCardTool.swift
//  LarkMessageCore
//
//  Created by bytedance on 2021/12/7.
//

import Foundation
import UIKit
import LarkModel
import LarkMessengerInterface

public final class MergeForwardPostCardTool {
    public static func getTitleFromContent(_ content: MergeForwardContent?) -> String {
        guard let content = content, let firstMessage = content.messages.first else {
            return ""
        }
        var name: String? = content.fromChatChatters?[firstMessage.fromId]?.name
        // 如果fromChatChatters包含了fromId 优先使用
        let isMsgThread = content.thread?.isReplyInThread ?? false
        guard let userName = name, !userName.isEmpty else {
            if isMsgThread {
                return BundleI18n.LarkMessageCore.Lark_IM_Thread_UsernameThreadCard_Title(content.chatters[firstMessage.fromId]?.name ?? "")
            } else {
                return BundleI18n.LarkMessageCore.Lark_Group_NamesTopic(content.chatters[firstMessage.fromId]?.name ?? "")
            }
        }
        /// msgThread 展示文案不同
        if isMsgThread {
            return BundleI18n.LarkMessageCore.Lark_IM_Thread_UsernameThreadCard_Title(userName)
        } else {
            return BundleI18n.LarkMessageCore.Lark_Group_NamesTopic(userName)
        }
    }

    public static func getPosterNameFromMessage(_ message: Message?, _ chatType: Chat.TypeEnum?) -> String {
        guard let message = message, let posterName = message.fromChatter?.displayName(chatId: message.chatID, chatType: chatType, scene: .head) else { return "" }
        return BundleI18n.LarkMessageCore.Lark_IM_Thread_UsernameThreadCard_Title(posterName)
    }
}

public final class MergeForwardContentImpl: MergeForwardContentService {
    public func getMergeForwardTitleFromContent(_ content: MergeForwardContent?) -> String {
        return MergeForwardPostCardTool.getTitleFromContent(content)
    }
    public func getPosterNameFromMessage(_ message: Message?, _ chatType: Chat.TypeEnum?) -> String {
        return MergeForwardPostCardTool.getPosterNameFromMessage(message, chatType)
    }
}
