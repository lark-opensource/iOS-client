//
//  ReplyInThreadMergeForwardDataManager.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/6/23.
//

import Foundation
import UIKit
import LarkModel
import LarkAccountInterface
import RustPB
import LarkCore

public final class ReplyInThreadMergeForwardDataManager {

    public static func isReplyInThreadData(content: MergeForwardContent) -> Bool {
         if let thread = content.thread, thread.isReplyInThread {
             return true
         }
         return false
     }

    public static func isP2pChatType(content: MergeForwardContent) -> Bool {
         return content.chatType == .p2P
     }

    public static func isChatMember(content: MergeForwardContent?, currentChatterId: String?) -> Bool {
        guard let content = content else {
            return false
        }
        if content.chatType == .p2P {
            if let currentUserID = currentChatterId, (currentUserID == "\(content.p2PCreatorID)" || currentUserID == "\(content.p2PPartnerID)") {
                return true
            }
        } else {
            if let chat = content.fromThreadChat {
                return chat.role == .member
            }
        }
        return false
    }

    // 群成员或公开群
    public static func isChatMemberOrPublicChat(content: MergeForwardContent?, currentChatterId: String?) -> Bool {
        if let chat = content?.fromThreadChat, chat.isPublic {
            return true
        }
        return isChatMember(content: content, currentChatterId: currentChatterId)
    }

    public static func avatarOfMemberOrPublic(content: MergeForwardContent?, currentChatterId: String?) -> (String, String) {
        /// 这里根据产品要求 单聊不展示头像
        if isChatMemberOrPublicChat(content: content, currentChatterId: currentChatterId), let content = content, content.chatType != .p2P {
            return (content.fromThreadChat?.id ?? "", content.fromThreadChat?.avatarKey ?? "")
        }
        return ("", "")
    }

    public static func titleOfMemberOrPublic(content: MergeForwardContent?, currentChatterId: String?) -> String {
        guard let content = content, isChatMemberOrPublicChat(content: content, currentChatterId: currentChatterId) else {
            return ""
        }
        if content.chatType == .p2P {
            return p2pFromTitleFor(content: content)
        } else {
            return content.fromThreadChat?.name ?? ""
        }
    }

    /// 来自：xxx；群名
    public static func fromTitleFor(content: MergeForwardContent?, currentChatterId: String?) -> String {
        guard let content = content, isChatMember(content: content, currentChatterId: currentChatterId) else {
             return ""
        }
        if content.chatType == .p2P {
            return p2pFromTitleFor(content: content)
        } else {
            return content.fromThreadChat?.name ?? ""
        }
    }

    public static func fromAvatarFor(content: MergeForwardContent?, currentChatterId: String?) -> String {
        /// 这里根据产品要求 单聊不展示头像
        if isChatMember(content: content, currentChatterId: currentChatterId), let content = content, content.chatType != .p2P {
             return content.fromThreadChat?.avatarKey ?? ""
         }
         return ""
    }

    public static func fromAvatarEntityId(content: MergeForwardContent?, currentChatterId: String?) -> String {
        if self.fromAvatarFor(content: content, currentChatterId: currentChatterId).isEmpty {
            return ""
        }
        if content?.fromThreadChat?.type == .p2P {
            return content?.fromThreadChat?.chatter?.id ?? ""
        }
        return content?.fromThreadChat?.id ?? ""
    }

    // 来自：xxx；来自：xxx和xxx的会话
    private static func p2pFromTitleFor(content: MergeForwardContent) -> String {
        if content.p2PPartnerName.isEmpty {
            return BundleI18n.LarkMessageCore.Lark_Chat_Thread_FromChat("\(content.p2PCreatorName)")
        } else {
            let title: String
            if let fromId = content.messages.first?.fromId, fromId == "\(content.p2PPartnerID)" {
                title = BundleI18n.LarkMessageCore.Lark_IM_Thread_FromUser1AndUser2Chat_Text2("\(content.p2PPartnerName)",
                                                                                              "\(content.p2PCreatorName)")
            } else {
                title = BundleI18n.LarkMessageCore.Lark_IM_Thread_FromUser1AndUser2Chat_Text2("\(content.p2PCreatorName)",
                                                                                              "\(content.p2PPartnerName)")
            }
            return BundleI18n.LarkMessageCore.Lark_Chat_Thread_FromChat(title)
        }
     }

    /// xxx；xxx和xxx的会话。和p2pFromTitleFor的区别是没有前缀"来自："
    public static func p2pTitleFor(content: MergeForwardContent) -> String {
        if content.p2PPartnerName.isEmpty {
            return BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_TopicPostedInOwnChat_Variable("\(content.p2PCreatorName)")
        }
        // 两个人的聊天
        let title: String
        if let fromId = content.messages.first?.fromId, fromId == "\(content.p2PPartnerID)" {
            title = BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_TopicPostedInTwoUsersChat_Variable("\(content.p2PPartnerName)",
                                                                                                      "\(content.p2PCreatorName)")
        } else {
            title = BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_TopicPostedInTwoUsersChat_Variable("\(content.p2PCreatorName)",
                                                                                                      "\(content.p2PPartnerName)")
        }
        return title
    }

    public static func getFromChatFor(content: MergeForwardContent) -> Chat {
        if let chat = content.fromThreadChat {
            return chat
        }
        guard content.chatType == .p2P else {
            assertionFailure("只有p2p情况下才会有 chat不存在的情况")
            return Chat.transform(pb: RustPB.Basic_V1_Chat())
        }
        let chat = getMockP2pChat(id: content.thread?.channel.id ?? "")
        chat.name = p2pFromTitleFor(content: content)
        return chat
    }

    public static func getMockP2pChat(id: String) -> Chat {
        let chat = Chat.transform(pb: RustPB.Basic_V1_Chat())
        chat.type == .p2P
        chat.isSuper = false
        chat.isCrypto = false
        chat.id = id
        chat.chatterCount = 2
        chat.oncallId = ""
        chat.isAllowPost = true
        return chat
    }
}
