//
//  SendThreadAPI.swift
//  LarkSDK
//
//  Created by zc09v on 2019/2/27.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import RustPB

public struct ThreadMessage {
    public var thread: RustPB.Basic_V1_Thread
    public var rootMessage: Message
    public var replyMessages: [Message]
    /// 最近的@消息
    public var latestAtMessages: [Message]
    public var chat: Chat?
    public var topicGroup: TopicGroup?
    /// 推荐列表中存在impressionID，广场使用
    public var impressionID: String?
    /// 当前thread所属filterId，小组里与我相关tab使用
    public var filterId: String?

    public init(
        chat: Chat? = nil,
        topicGroup: TopicGroup? = nil,
        thread: RustPB.Basic_V1_Thread,
        rootMessage: Message,
        replyMessages: [Message] = [Message](),
        latestAtMessages: [Message] = [Message](),
        impressionID: String? = nil,
        filterId: String? = nil
    ) {
        self.topicGroup = topicGroup
        self.thread = thread
        self.rootMessage = rootMessage
        self.replyMessages = replyMessages
        self.latestAtMessages = latestAtMessages
        self.chat = chat
        self.impressionID = impressionID
        self.filterId = filterId
    }

    public var id: String {
        //thread.id == rootMessage.id
        return self.thread.id
    }

    public var channel: RustPB.Basic_V1_Channel {
        return self.thread.channel
    }

    public var position: Int32 {
        return self.thread.position
    }

    public var isBadged: Bool {
        return self.thread.isBadged
    }

    public var badgeCount: Int32 {
        return self.thread.badgeCount
    }

    public var createTime: TimeInterval {
        return self.rootMessage.createTime
    }

    public var localStatus: Message.LocalStatus {
        get {
            return self.rootMessage.localStatus
        }
        set {
            self.rootMessage.localStatus = newValue
        }
    }

    public var cid: String {
        return self.rootMessage.cid
    }

    public var isVisible: Bool {
        return self.thread.isVisible
    }

    public var isDecryptoFail: Bool {
        return self.rootMessage.isDecryptoFail
    }

    public var isNoTraceDeleted: Bool {
        return self.thread.isNoTraceDeleted || self.rootMessage.isNoTraceDeleted
    }

    public var messageLanguage: String {
        return rootMessage.messageLanguage
    }

    public static func transform(
        entity: RustPB.Basic_V1_Entity,
        id: String,
        currentChatterID: String
    ) throws -> ThreadMessage {
        guard let pb = entity.threads[id] else {
            throw LarkModelError.entityIncompleteData(message: "entity.thraeds缺少相关thread id: \(id)")
        }
        guard let root = try? Message.transform(
            entity: entity,
            id: pb.rootMessageID,
            currentChatterID: currentChatterID
        ) else {
            throw LarkModelError.entityIncompleteData(
                message: "entity.messages缺少thread相关rootMessage id: \(pb.rootMessageID)"
            )
        }

        guard let replyMessages = try? ThreadMessage.transformReplyMessages(
            entity: entity,
            currentChatterID: currentChatterID,
            replyIds: pb.lastReplyIds
        ) else {
            throw LarkModelError.entityIncompleteData(message: "entity.messages缺少thread相关reply message ids: \(id)")
        }

        guard let latestAtMessages = try? ThreadMessage.transformLatestAtMessages(
            entity: entity,
            currentChatterID: currentChatterID,
            latestAtIds: pb.latestAtMessageID
        ) else {
            throw LarkModelError.entityIncompleteData(message: "entity.messages缺少thread相关latest at message ids: \(id)")
        }

        var chat: LarkModel.Chat?
        if let chatEntity = entity.chats[pb.channel.id] {
            chat = LarkModel.Chat.transform(
                entity: entity,
                chatOptionInfo: nil,
                pb: chatEntity
            )
        }

        var topicGroup: TopicGroup?
        if let topicGroupEntity = entity.topicGroups[pb.channel.id] {
            topicGroup = TopicGroup.transform(pb: topicGroupEntity)
        }

        return ThreadMessage(
            chat: chat,
            topicGroup: topicGroup,
            thread: pb,
            rootMessage: root,
            replyMessages: replyMessages,
            latestAtMessages: latestAtMessages
        )
    }

    public static func transformReplyMessages(
        entity: RustPB.Basic_V1_Entity,
        currentChatterID: String,
        replyIds: [String]
    ) throws -> [Message] {
        var replyMessages = [Message]()
        // 重新排序，从旧->新
        for replyId in replyIds.reversed() {
            guard let replyMessage = try? Message.transform(
                entity: entity,
                id: replyId,
                currentChatterID: currentChatterID
            ) else {
                throw LarkModelError.entityIncompleteData(
                    message: "entity.messages缺少thread相关reply message id: \(replyId)"
                )
            }
            replyMessages.append(replyMessage)
        }

        return replyMessages
    }

    public static func transformLatestAtMessages(
        entity: RustPB.Basic_V1_Entity,
        currentChatterID: String,
        latestAtIds: [String]
    ) throws -> [Message] {
        var latestAtMessages = [Message]()
        for latestAtId in latestAtIds {
            guard let replyMessage = try? Message.transform(
                entity: entity,
                id: latestAtId,
                currentChatterID: currentChatterID
            ) else {
                throw LarkModelError.entityIncompleteData(
                    message: "entity.messages缺少thread相关latest at message id: \(latestAtId)"
                )
            }
            latestAtMessages.append(replyMessage)
        }

        return latestAtMessages
    }

    public static func transformQuasi(
        entity: RustPB.Basic_V1_Entity,
        id: String,
        currentChatterID: String
    ) throws -> ThreadMessage {
        guard let quasiPB = entity.quasiThreads[id] else {
            throw LarkModelError.entityIncompleteData(message: "entity.quasiThraeds缺少相关thread id: \(id)")
        }
        let pb = quasiPB.transformToRustThread()
        guard let root = try? Message.transformQuasi(entity: entity, cid: id) else {
            throw LarkModelError.entityIncompleteData(message: "entity.messages缺少quasiThread相关id: \(id)")
        }

        var chat: LarkModel.Chat?
        if let chatEntity = entity.chats[pb.channel.id] {
          chat = LarkModel.Chat.transform(
              entity: entity,
              chatOptionInfo: nil,
              pb: chatEntity
          )
        }

        var topicGroup: TopicGroup?
        if let topicGroupEntity = entity.topicGroups[pb.channel.id] {
          topicGroup = TopicGroup.transform(pb: topicGroupEntity)
        }

        return ThreadMessage(
            chat: chat,
            topicGroup: topicGroup,
            thread: pb,
            rootMessage: root
        )
    }
}

public extension RustPB.Basic_V1_QuasiThread {
    func transformToRustThread() -> RustPB.Basic_V1_Thread {
        var thread = RustPB.Basic_V1_Thread()
        thread.id = self.id
        thread.channel = self.channel
        thread.topic = self.topic
        thread.position = self.position
        thread.isVisible = true
        thread.isFollow = true
        return thread
    }
}
