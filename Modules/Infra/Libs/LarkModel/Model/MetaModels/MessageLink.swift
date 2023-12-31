//
//  MessageLink.swift
//  LarkModel
//
//  Created by Ping on 2023/5/4.
//

import RustPB

public struct MessageLink {
    public var token: String
    // 全量的messageID
    public var entityIDs: [Int64]
    public var entities: [Int64: Entity]
    public var chatInfo: Basic_V1_MessageLink.ChatInfo
    public var metaInfo: Basic_V1_MessageLink.MetaInfo
    public var chat: Chat

    public init(
        token: String,
        entityIDs: [Int64],
        entities: [Int64: Entity],
        chatInfo: Basic_V1_MessageLink.ChatInfo,
        metaInfo: Basic_V1_MessageLink.MetaInfo,
        chat: Chat
    ) {
        self.token = token
        self.entityIDs = entityIDs
        self.entities = entities
        self.chatInfo = chatInfo
        self.metaInfo = metaInfo
        self.chat = chat
    }

    public static func transform(previewID: String, messageLink: Basic_V1_MessageLink) -> MessageLink {
        var chat: Chat?
        if let chatPB = messageLink.chats["\(messageLink.metaInfo.fromChatID)"] {
            chat = Chat.transform(pb: chatPB)
        }
        return MessageLink(
            token: messageLink.token,
            entityIDs: messageLink.entityIds,
            entities: Entity.transform(previewID: previewID, messageLink: messageLink),
            chatInfo: messageLink.chatInfo,
            metaInfo: messageLink.metaInfo,
            chat: chat ?? createChat(messageLink: messageLink)
        )
    }

    private static func createChat(messageLink: Basic_V1_MessageLink) -> Chat {
        let chat = Chat.transform(pb: RustPB.Basic_V1_Chat())
        chat.name = messageLink.chatInfo.name
        chat.id = "\(messageLink.metaInfo.fromChatID)"
        chat.type = messageLink.chatInfo.type
        if messageLink.chatInfo.isAuth {
            chat.role = .member
        }
        chat.isSuper = false
        chat.isCrypto = false
        chat.oncallId = ""
        chat.isAllowPost = true
        return chat
    }
}

public extension MessageLink {
    struct Entity {
        public var message: Message
        public var thread: Basic_V1_Thread?

        public init(
            message: Message,
            thread: Basic_V1_Thread?
        ) {
            self.message = message
            self.thread = thread
        }

        public static func transform(previewID: String, messageLink: Basic_V1_MessageLink, needPackParentRootMessage: Bool = true) -> [Int64: Entity] {
            return messageLink.entities.mapValues({
                var entity = Entity.transform(pb: $0)
                entity.message = configMessageInfo(
                    previewID: previewID,
                    message: entity.message,
                    pb: $0,
                    messageLink: messageLink,
                    needPackParentRootMessage: needPackParentRootMessage
                )
                return entity
            })
        }

        private static func transform(
            previewID: String,
            messageID: Int64,
            messageLink: Basic_V1_MessageLink,
            needPackParentRootMessage: Bool = true
        ) -> Message? {
            guard let pb = messageLink.entities[messageID] else { return nil }
            let message = Message.transform(pb: pb.message)
            return configMessageInfo(
                previewID: previewID,
                message: message,
                pb: pb,
                messageLink: messageLink,
                needPackParentRootMessage: needPackParentRootMessage
            )
        }

        public static func transform(pb: Basic_V1_MessageLink.Entity) -> Entity {
            let message = Message.transform(pb: pb.message)
            return Entity(message: message, thread: pb.hasThread ? pb.thread : nil)
        }

        private static func configMessageInfo(
            previewID: String,
            message: Message,
            pb: Basic_V1_MessageLink.Entity,
            messageLink: Basic_V1_MessageLink,
            needPackParentRootMessage: Bool
        ) -> Message {
            if let chatterPB = messageLink.chatters[pb.message.fromID] {
                let chatter = Chatter.transform(pb: chatterPB)
                message.atomicExtra.unsafeValue.fromChatter = chatter
            }

            let orderedPreviewIDs = Message.getOrderedPreviewIDs(message: pb.message)
            message.orderedPreviewIDs = orderedPreviewIDs
            if let pair = messageLink.previewEntities[pb.message.id] {
                message.urlPreviewEntities = pair.previewEntity.filter({ orderedPreviewIDs.contains($0.key) }).mapValues({ URLPreviewEntity.transform(from: $0) })
            } else if message.urlPreviewHangPointMap.isEmpty,
                      let entities = URLPreviewEntity.transform(from: message) {
                // 都未接入中台，保持旧规则，多个URL不展示卡片；orderedPreviewIDs也只有一个
                message.orderedPreviewIDs = Array(entities.keys)
                message.urlPreviewEntities = entities
            }

            var content = message.atomicExtra.unsafeValue.content
            content.complement(previewID: previewID, messageLink: messageLink, message: message)
            message.atomicExtra.unsafeValue.content = content

            if !pb.message.reactions.isEmpty {
                message.reactions = pb.message.reactions.map({ (reaction) -> Reaction in
                    return Reaction.transform(messageLink: messageLink, pb: reaction)
                })
            }

            if needPackParentRootMessage, !pb.message.parentID.isEmpty, let parentID = Int64(pb.message.parentID), message.parentMessage == nil {
                message.atomicExtra.unsafeValue.parentMessage = transform(previewID: previewID, messageID: parentID, messageLink: messageLink)
            }

            if message.threadMessageType == .threadRootMessage {
                if pb.hasThread {
                    let thread = pb.thread
                    message.replyInThreadCount = thread.replyCount
                    message.replyInThreadTopRepliers = thread.topRepliers
                        .compactMap { (chatterID) -> Chatter? in
                            if let chatterPB = messageLink.chatters["\(chatterID)"] {
                                return Chatter.transform(pb: chatterPB)
                            }
                            return nil
                        }
                    var replyMessages: [Message] = []
                    // 重新排序，从旧->新
                    let replyIDs = thread.lastReplyIds.reversed()
                    for replyID in replyIDs {
                        if let id = Int64(replyID), let replyMessage = transform(previewID: previewID, messageID: id, messageLink: messageLink, needPackParentRootMessage: false) {
                            replyMessages.append(replyMessage)
                        }
                    }
                    message.replyInThreadLastReplies = replyMessages
                }

                if pb.hasMessageThread {
                    let messageThread = pb.messageThread
                    message.replyInThreadCount = messageThread.replyCount
                    message.replyInThreadTopRepliers = messageThread.topRepliers.compactMap({ chatterID in
                        if let chatterPB = messageLink.chatters["\(chatterID)"] {
                            return Chatter.transform(pb: chatterPB)
                        }
                        return nil
                    })
                    message.replyInThreadLastReplies = messageThread.replyEntityIds.suffix(5).compactMap { messageID in
                        // 话题回复时，也会有parentID，此时不能再pack parentMessage了，否则会递归调用
                        return transform(previewID: previewID, messageID: messageID, messageLink: messageLink, needPackParentRootMessage: false)
                    }
                }
            }

            if message.fatherMFMessage == nil {
                message.mergeMessageIdPath = [message.id]
            }

            removeReplyInThreadStyle(message: message)

            return message
        }

        // 如果是从话题回复详情页/话题模式群详情页拷贝的根消息和子消息链接，产品要求对齐普通转发样式，展示成普通消息
        private static func removeReplyInThreadStyle(message: Message) {
            if message.threadMessageType == .threadRootMessage,
               message.replyInThreadCount > 0,
               message.replyInThreadLastReplies.isEmpty {
                message.threadMessageType = .unknownThreadMessage
                message.displayMode = .default
            } else if message.threadMessageType == .threadReplyMessage {
                message.parentMessage = nil
                message.displayMode = .default
            }
        }
    }
}

public func += (_ left: inout [String: MessageLink], _ right: [String: MessageLink]) {
    left.merge(right) { _, new in
        return new
    }
}
