//
//  MergeForwardContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public final class MergeForwardContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias TypeEnum = RustPB.Basic_V1_Chat.TypeEnum
    public typealias ChatterInfo = RustPB.Basic_V1_MergeForwardContent.ChatterInfo
    public typealias MessageThread = RustPB.Basic_V1_MergeForwardContent.MessageThread

    public var messageId: String
    public var messages: [Message]
    public var chatType: TypeEnum
    public var groupChatName: String
    public var p2PCreatorName: String
    public var p2PPartnerName: String
    public var p2PCreatorID: Int64
    public var p2PPartnerID: Int64

    public var chatters: [String: ChatterInfo]
    /// 私有话题群 转发的话题会携带该消息，通过thread.isReplyInThread判断是「普通群的话题回复」还是「话题群中的话题」
    public var thread: RustPB.Basic_V1_Thread?
    public var messageReactionInfo: [String: RustPB.Basic_V1_MergeForwardContent.MessageReaction] = [:]
    /// 是否来自私有话题群
    public var isFromPrivateTopic: Bool { return thread != nil }
    /// 通过thread.channel.id从Entity中解析，没权限也可能有值，需要额外判断chat.role == .member
    public var fromThreadChat: Chat?
    public var fromChatChatters: [String: Chatter.PBModel]?
    /// 子消息如果是话题，则存储对应话题回复
    public var messageThreads: [Int64: MessageThread]

    public var originChatID: Int64

    public init(
        messageId: String,
        messages: [Message],
        chatType: TypeEnum,
        originChatID: Int64,
        groupChatName: String,
        p2PCreatorName: String,
        p2PPartnerName: String,
        p2PCreatorID: Int64,
        p2PPartnerID: Int64,
        chatters: [String: ChatterInfo],
        thread: RustPB.Basic_V1_Thread?,
        messageReactionInfo: [String: RustPB.Basic_V1_MergeForwardContent.MessageReaction],
        messageThreads: [Int64: MessageThread]
    ) {
        self.messageId = messageId
        self.messages = messages
        self.chatType = chatType
        self.groupChatName = groupChatName
        self.p2PCreatorName = p2PCreatorName
        self.p2PPartnerName = p2PPartnerName
        self.p2PCreatorID = p2PCreatorID
        self.p2PPartnerID = p2PPartnerID
        self.chatters = chatters
        self.thread = thread
        self.messageReactionInfo = messageReactionInfo
        self.messageThreads = messageThreads
        self.originChatID = originChatID
    }

    public func copy() -> MergeForwardContent {
        let content = MergeForwardContent(
            messageId: self.messageId,
            messages: self.messages.map({ $0.copy() }),
            chatType: self.chatType,
            originChatID: self.originChatID,
            groupChatName: self.groupChatName,
            p2PCreatorName: self.p2PCreatorName,
            p2PPartnerName: self.p2PPartnerName,
            p2PCreatorID: self.p2PCreatorID,
            p2PPartnerID: self.p2PPartnerID,
            chatters: self.chatters,
            thread: self.thread,
            messageReactionInfo: self.messageReactionInfo,
            messageThreads: self.messageThreads
        )
        content.fromThreadChat = fromThreadChat
        content.fromChatChatters = fromChatChatters
        return content
    }

    public static func transform(pb: PBModel) -> MergeForwardContent {
        let thread = pb.content.mergeForwardContent.thread
        return MergeForwardContent(
            messageId: pb.id,
            messages: pb.content.mergeForwardContent.messages.map({ Message.transform(pb: $0) }),
            chatType: pb.content.mergeForwardContent.chatType,
            originChatID: pb.content.mergeForwardContent.originChatID,
            groupChatName: pb.content.mergeForwardContent.groupChatName,
            p2PCreatorName: pb.content.mergeForwardContent.p2PCreatorName,
            p2PPartnerName: pb.content.mergeForwardContent.p2PPartnerName,
            p2PCreatorID: pb.content.mergeForwardContent.p2PCreatorID,
            p2PPartnerID: pb.content.mergeForwardContent.p2PPartnerID,
            chatters: pb.content.mergeForwardContent.chatters,
            thread: thread.id.isEmpty ? nil : thread,
            messageReactionInfo: pb.content.mergeForwardContent.reactionSnapshots,
            messageThreads: pb.content.mergeForwardContent.messageThreads
        )
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let thread = self.thread, let chatPB = entity.chats[thread.channel.id] {
            fromThreadChat = Chat.transform(entity: entity, pb: chatPB)
        }
        fromChatChatters = entity.chatChatters[message.channel.id]?.chatters
        // 话题转发卡片需要外漏展示所有的消息类型，因此对所有消息都需要调用complement
        for msg in messages {
            msg.content.complement(entity: entity, message: message)
        }
        for msg in messages {
            msg.abbreviationInfo = entity.abbrevs
            if msg.fromChatter == nil,
               let chatterPB = fromChatChatters?[msg.fromId] {
                msg.atomicExtra.value.fromChatter = Chatter.transform(pb: chatterPB)
            }
        }
        // 填充子消息译文信息，获取该消息所有子消息的译文信息
        if let translateInfo = entity.mergeForwardTranslateMessages[message.id] {
            self.messages.forEach { (subMessage) in
                // 只在text/post类型的子消息时才填充翻译信息
                guard subMessage.type == .text ||
                        subMessage.type == .post ||
                        subMessage.type == .image ||
                        subMessage.isTranslatableMessageCardType() else { return }

                // 获取该子消息的译文信息
                if let translatePB = translateInfo.subTranslateMessages[subMessage.id] {
                    subMessage.translateState = .translated
                    switch subMessage.type {
                    case .text:
                        subMessage.atomicExtra.unsafeValue.translateContent = TextContent.transform(pb: translatePB)
                    case .post:
                        subMessage.atomicExtra.unsafeValue.translateContent = PostContent.transform(pb: translatePB)
                    case .image:
                        subMessage.atomicExtra.unsafeValue.translateContent = ImageContent.transform(pb: translatePB)
                    case .card:
                        subMessage.atomicExtra.unsafeValue.translateContent = CardContent.transform(pb: translatePB)
                    @unknown default: break
                    }
                }
            }
        }
        // URLPreview
        self.messages.forEach { subMessage in
            if let pb = entity.messages[self.messageId]?.content.mergeForwardContent.messages.first(where: { $0.id == subMessage.id }) {
                let entities = InlinePreviewEntity.transform(entity: entity, pb: pb)
                if subMessage.type == .text, var content = subMessage.content as? TextContent {
                    content.inlinePreviewEntities = entities
                    subMessage.content = content
                } else if subMessage.type == .post, var content = subMessage.content as? PostContent {
                    content.inlinePreviewEntities = entities
                    subMessage.content = content
                }
                // 合并转发页面不预览URL卡片，暂时不挂卡片数据
                subMessage.urlPreviewHangPointMap = pb.content.urlPreviewHangPointMap

                var mergeForwardInfo = Message.MergeForwardInfo(originChatID: self.originChatID)
                if let chatPB = entity.chats[String(self.originChatID)] {
                    mergeForwardInfo.originChat = Chat.transform(pb: chatPB)
                }
                mergeForwardInfo.fromChatChatters = self.fromChatChatters
                if subMessage.threadMessageType == .threadRootMessage,
                   let threadId = Int64(subMessage.threadId),
                   let thread = self.messageThreads[threadId] {
                    mergeForwardInfo.messageThread = thread
                    subMessage.replyInThreadCount = thread.replyCount
                    subMessage.replyInThreadTopRepliers = thread.topRepliers.compactMap({ chatterId in
                        if let value = self.fromChatChatters?["\(chatterId)"] {
                                return Chatter.transform(pb: value)
                            }
                             return nil
                    })
                }
                subMessage.mergeForwardInfo = mergeForwardInfo

                // 内层消息pack recaller
                if !pb.recallerID.isEmpty {
                    subMessage.atomicExtra.unsafeValue.recaller = try? Chatter.transformChatChatter(
                        entity: entity,
                        chatID: pb.chatID,
                        id: pb.recallerID
                    )
                }
            }
        }
    }

    public func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {
        fromChatChatters = messageLink.chatters
        for msg in messages {
            msg.content.complement(previewID: previewID, messageLink: messageLink, message: message)
        }

        // URLPreview
        self.messages.forEach { subMessage in
            if let id = Int64(self.messageId), let pb = messageLink.entities[id]?.message.content.mergeForwardContent.messages.first(where: { $0.id == subMessage.id }) {
                let entities = InlinePreviewEntity.transform(messageLink: messageLink, pb: pb)
                if subMessage.type == .text, var content = subMessage.content as? TextContent {
                    content.inlinePreviewEntities = entities
                    subMessage.content = content
                } else if subMessage.type == .post, var content = subMessage.content as? PostContent {
                    content.inlinePreviewEntities = entities
                    subMessage.content = content
                }
                // 合并转发页面不预览URL卡片，暂时不挂卡片数据
                subMessage.urlPreviewHangPointMap = pb.content.urlPreviewHangPointMap
            }
            if let chatterPB = messageLink.chatters[subMessage.fromId] {
                subMessage.atomicExtra.unsafeValue.fromChatter = Chatter.transform(pb: chatterPB)
            }
            if subMessage.threadMessageType == .threadRootMessage,
               let threadId = Int64(subMessage.threadId),
               let thread = self.messageThreads[threadId] {
                subMessage.replyInThreadCount = thread.replyCount
                subMessage.replyInThreadTopRepliers = thread.topRepliers.compactMap({ (chatterID) -> Chatter? in
                    if let chatterPB = messageLink.chatters["\(chatterID)"] {
                        return Chatter.transform(pb: chatterPB)
                    }
                    return nil
                })
                subMessage.replyInThreadLastReplies = thread.messages.suffix(5).compactMap { messagePB in
                    let currMessage = Message.transform(pb: messagePB)
                    if let chatterPB = messageLink.chatters[currMessage.fromId] {
                        currMessage.fromChatter = Chatter.transform(pb: chatterPB)
                        return currMessage
                    }
                    // 对齐fixMergeForwardContent中逻辑，没有Chatter，不显示回复
                    return nil
                }
            }
        }
    }
}
