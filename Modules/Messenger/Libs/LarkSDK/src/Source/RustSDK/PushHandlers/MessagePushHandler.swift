//
//  MessagePushHandler.swift
//  Lark
//
//  Created by qihongye on 2017/12/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LarkModel
import LarkContainer
import LarkSDKInterface
import LarkSendMessage
import EENotification
import NotificationUserInfo
import LKCommonsLogging
import LarkAccountInterface

final class MessagePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(MessagePushHandler.self, category: "Rust.PushHandler")
    private let disposeBag = DisposeBag()

    private var userPushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private var packer: MessagePacker? { try? userResolver.resolve(assert: MessagePacker.self) }
    private var passportUserService: PassportUserService? { try? userResolver.resolve(assert: PassportUserService.self) }
    private var chatterManager: ChatterManagerProtocol? { try? userResolver.resolve(assert: ChatterManagerProtocol.self) }
    private var sendMessageAPI: SendMessageAPI? { try? userResolver.resolve(assert: SendMessageAPI.self) }
    private var sendThreadAPI: SendThreadAPI? { try? userResolver.resolve(assert: SendThreadAPI.self) }

    func process(push message: RustPB.Im_V1_PushMessageResponse) {
        do {
            if self.passportUserService?.user == nil { return }
            guard let currentChatter = self.chatterManager?.currentChatter else { return }

            try handleMessagePush(message: message, currentUser: currentChatter)
            handleChat(entity: message.entity)
            handleThread(entity: message.entity)
            handleAIRoundInfo(aiRoundInfos: message.aiLastRoundInfos)
        } catch {
            MessagePushHandler.logger.error("收到消息Push，无法转化", error: error)
        }
    }

    private func handleAIRoundInfo(aiRoundInfos: [Im_V1_AIRoundInfo]) {
        let infos = aiRoundInfos.map { AIRoundInfo.from(rustPB: $0) }
        guard !infos.isEmpty else { return }
        self.userPushCenter?.post(PushAIRoundInfo(aiRoundInfos: infos))
    }

    func handleChat(entity: RustPB.Basic_V1_Entity) {
        if entity.chats.isEmpty {
            return
        }
        let chatsMap = RustAggregatorTransformer.transformToChatsMap(
            fromEntity: entity
        )
        chatsMap.values.forEach {
            self.userPushCenter?.post(PushChat(chat: $0))
            Self.logger.info("chatTrace receive pushMessage handleChat \($0.id) \($0.badge) \( $0.lastVisibleMessagePosition) \( $0.lastMessagePosition) \($0.displayInThreadMode)")
        }
    }

    func handleThread(entity: RustPB.Basic_V1_Entity) {
        if entity.threads.isEmpty {
            return
        }
        let threads = entity.threads.compactMap { (_, thread) -> RustPB.Basic_V1_Thread in
            return thread
        }
        self.userPushCenter?.post(PushThreads(threads: threads))
    }

    func handleMessagePush(message: RustPB.Im_V1_PushMessageResponse, currentUser: LarkModel.Chatter) throws {
        var quasiMessageIds: [String] = []
        var messageIds: [String] = []
        var ephemeralIds: [String] = []
        var foldMessageItems: [String: Message] = [:]
        for messageItem in message.messageItems {
            switch messageItem.itemType {
            case .normalMessage:
                messageIds.append(messageItem.itemID)
            case .quasiMessage:
                quasiMessageIds.append(messageItem.itemID)
            case .ephemeralMessage:
                ephemeralIds.append(messageItem.itemID)
            case .messageFold:
                if let foldId = Int64(messageItem.itemID),
                   let foldDetail = message.entity.messageFoldDetails[foldId] {
                    var foldMessageEntity = message.entity
                    /// entity.messages可能没有FoldMessage，造成Message.transform.content不能更新
                    if foldMessageEntity.messages[foldDetail.message.id] == nil {
                        foldMessageEntity.messages[foldDetail.message.id] = foldDetail.message
                    }
                    let foldMessage = Message.transform(entity: foldMessageEntity, pb: foldDetail.message, currentChatterID: currentUser.id)
                    if foldId != foldMessage.foldId {
                        assertionFailure("SDK error data")
                    }
                    self.configFoldRootMessageWith(foldMessage: foldMessage, entity: message.entity)
                    messageIds.append(foldMessage.id)
                    foldMessageItems[foldMessage.id] = foldMessage
                }
            case .unknownMessage:
                break
            @unknown default:
                assert(false, "new value")
                break
            }
        }
        try self.handleQuasiMessagePush(entity: message.entity, quasiMessageIds: quasiMessageIds, currentUser: currentUser)
        try self.handleMessagePush(entity: message.entity, messageIds: messageIds, foldMessages: foldMessageItems, currentChatterId: currentUser.id)
        try self.handleMessagePush(entity: message.entity, messageIds: ephemeralIds, currentChatterId: currentUser.id, msgItemType: .ephemeralMessage)
    }

    func handleQuasiMessagePush(entity: RustPB.Basic_V1_Entity,
                                quasiMessageIds: [String],
                                currentUser: LarkModel.Chatter) throws {
        if quasiMessageIds.isEmpty {
            return
        }
        let messages = RustAggregatorTransformer
            .transformToQuasiMessageModels(entity: entity, messageIds: quasiMessageIds)
            .map({ (msg) -> LarkModel.Message in
                msg.fromChatter = currentUser
                return msg
            })
            .sorted(by: RustMessageModule.sortMessages)

        var pushMessages: [LarkModel.Message] = []
        var pushThreadMessages: [ThreadMessage] = []

        for msg in messages {
            if let quasiThread = entity.quasiThreads[msg.threadId], quasiThread.id == msg.id {
                let threadMessage = ThreadMessage(thread: quasiThread.transformToRustThread(), rootMessage: msg)
                if !(sendThreadAPI?.dealPush(thread: threadMessage, sendThreadType: .threadChat) ?? false) {
                    pushThreadMessages.append(threadMessage)
                }
                MessagePushHandler.logger.debug("handleQuasiThreadMessagePush messageId: \(msg.cid) \(msg.position) \(msg.localStatus) \(msg.threadId)")
            } else {
                if !(sendMessageAPI?.dealPushMessage(message: msg) ?? false) {
                    pushMessages.append(msg)
                    self.userPushCenter?.post(PushChannelMessage(message: msg))
                }
                MessagePushHandler.logger.debug("handleQuasiMessagePush messageId: \(msg.cid) \(msg.position) \(msg.localStatus)")
            }
        }
        self.userPushCenter?.post(PushChannelMessages(messages: pushMessages))
        self.userPushCenter?.post(PushThreadMessages(messages: pushThreadMessages))
    }

    func handleMessagePush(entity: RustPB.Basic_V1_Entity,
                           messageIds: [String],
                           foldMessages: [String: Message] = [:],
                           currentChatterId: String,
                           msgItemType: RustPB.Im_V1_PushMessageResponse.MessageItem.ItemType = .normalMessage) throws {
        if messageIds.isEmpty, foldMessages.isEmpty {
            return
        }
        var foldMessagesMap = foldMessages
        var messages: [LarkModel.Message] = []
        if msgItemType == .normalMessage {
            if !messageIds.isEmpty {
                messages = RustAggregatorTransformer
                    .transformToMessageModels(fromEntity: entity,
                                              messageIds: messageIds,
                                              currentChatterId: currentChatterId)
            }
            if !foldMessagesMap.isEmpty {
                messages = messages.map { message in
                    if message.isFoldRootMessage,
                       let foldMessage = foldMessagesMap[message.id] {
                        foldMessagesMap.removeValue(forKey: message.id)
                        return foldMessage
                    }
                    return message
                }
                /// 如果messages中还有消息未替换完成，直接添加到数组后，后续会按postion排序
                if !foldMessagesMap.isEmpty {
                    messages.append(contentsOf: foldMessages.values)
                }
            }
            messages = messages.sorted(by: RustMessageModule.sortMessages)
            /// 将fold挂在message上
            messages.forEach { message in
                if message.isFoldRootMessage, message.foldDetailInfo == nil {
                    self.configFoldRootMessageWith(foldMessage: message, entity: entity)
                }
            }
        } else if msgItemType == .ephemeralMessage {
            messages = RustAggregatorTransformer
                       .transformToMessageModels(fromEntity: entity, messageIds: messageIds, currentChatterId: currentChatterId)
        }

        messages = messages.filter { (message) -> Bool in
            if message.isDeleted || message.isRecalled || message.isBurned {
                self.userPushCenter?.post(PushChannelMessage(message: message))
                self.userPushCenter?.post(PushChannelMessages(messages: [message]))
                /// 这里Chat消息需要过滤去, 由于小组的消息特殊性,还需要继续处理
                if message.threadId.isEmpty {
                    return false
                }
                return true
            }
            return true
        }
        if messages.isEmpty {
            return
        }
        pack(messages, onCompleted: { [weak self] (msgs) in
            guard let `self` = self else { return }
            var pushMessages: [LarkModel.Message] = []
            var pushThreadMessages: [ThreadMessage] = []
            func dealMessage(_ msg: LarkModel.Message) {
                if !(self.sendMessageAPI?.dealPushMessage(message: msg) ?? false) {
                    pushMessages.append(msg)
                    self.userPushCenter?.post(PushChannelMessage(message: msg))
                }
            }

            for msg in msgs {
                // thread中rootMessage 或是 thread中lastReplyMessage
                if let thread = entity.threads[msg.threadId] {
                    // 新推送过来的消息，处理 Topic 上最近的回复message。
                    let replyMessages = try? ThreadMessage.transformReplyMessages(entity: entity, currentChatterID: currentChatterId, replyIds: thread.lastReplyIds)
                    var rootMessageTmp: LarkModel.Message?
                    // 当前msg就是rootMessage
                    if msg.id == thread.id {
                        rootMessageTmp = msg
                        // 如果是chat里thread消息, 需要更新下root
                        if msg.threadMessageType != .unknownThreadMessage {
                            dealMessage(msg)
                        }
                    } else {
                        // 当前msg是话题中回复消息，先pushMessage
                        dealMessage(msg)
                        // 更新了回复消息，需要更新threadMessage消息，尝试重从entity中获取rootMessage
                        if let message = try? LarkModel.Message.transform(
                            entity: entity,
                            id: msg.rootId,
                            currentChatterID: currentChatterId
                            ) {
                            rootMessageTmp = message
                        }
                    }
                    // 新推送过来的消息，处理 Topic 上的最近@消息
                    let latestAtMessages = try? ThreadMessage.transformLatestAtMessages(entity: entity, currentChatterID: currentChatterId, latestAtIds: thread.latestAtMessageID)

                    // 都无法获取rootMessage 不更新数据，return掉。
                    guard let rootMessage = rootMessageTmp else {
                        MessagePushHandler.logger.error("handleMessagePush ThreadMessage rootMessage 获取失败: \(msg.id) \(msg.threadId)")
                        return
                    }

                    let threadMessage = ThreadMessage(
                        thread: thread,
                        rootMessage: rootMessage,
                        replyMessages: replyMessages ?? [],
                        latestAtMessages: latestAtMessages ?? []
                    )
                    if !(self.sendThreadAPI?.dealPush(thread: threadMessage, sendThreadType: .threadChat) ?? false) {
                        pushThreadMessages.append(threadMessage)
                    }
                } // 处理普通message
                else {
                    dealMessage(msg)
                }
            }
            self.userPushCenter?.post(PushChannelMessages(messages: pushMessages))
            self.userPushCenter?.post(PushThreadMessages(messages: pushThreadMessages))
        })
    }

    private func configFoldRootMessageWith(foldMessage: Message, entity: RustPB.Basic_V1_Entity) {
        guard let foldDetail = entity.messageFoldDetails[foldMessage.foldId] else {
            return
        }
        foldMessage.foldDetailInfo = foldDetail
        let chatters = entity.chatChatters[foldMessage.channel.id]?.chatters ?? entity.chatters
        let foldUsers: [FoldUserInfo] = foldDetail.userCounts.compactMap { obj in
            if let chatter = chatters["\(obj.userID)"] {
                return FoldUserInfo(chatter: Chatter.transform(pb: chatter),
                                    count: obj.count)
            }
            return nil
        }
        foldMessage.foldUsers = foldUsers
        if let chatter = chatters["\(foldDetail.recallUserID)"] {
            foldMessage.foldRecaller = Chatter.transform(pb: chatter)
        }
    }

}

fileprivate extension MessagePushHandler {
    func pack(_ messages: [LarkModel.Message], onCompleted: @escaping ([LarkModel.Message]) -> Void) {
        packer?.asyncPack(messages)
            .subscribe(onNext: { (messages) in
                onCompleted(messages)
            })
            .disposed(by: disposeBag)
    }
}
