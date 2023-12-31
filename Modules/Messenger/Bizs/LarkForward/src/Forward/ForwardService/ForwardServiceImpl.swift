//
//  ForwardServiceImpl.swift
//  Lark
//
//  Created by zc09v on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import LarkExtensionCommon
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import RustPB
import ByteWebImage
import ThreadSafeDataStructure
import LarkFeatureGating
import UIKit
import LKCommonsLogging
import LarkRichTextCore
import LarkRustClient
import LarkContainer
import LarkAccountInterface
import LarkBaseKeyboard
import LarkStorage

typealias ForwardResponse = ([String], Im_V1_FilePermCheckBlockInfo?)

final class ForwardServiceImpl: ForwardService {

    let chatAPI: ChatAPI
    let sendMessageAPI: SendMessageAPI
    let imageProcessor: SendImageProcessor
    let sendThreadAPI: SendThreadAPI
    let disposeBag = DisposeBag()
    let messageAPI: MessageAPI
    let rustService: SDKRustService
    let passportUserService: PassportUserService
    static let logger = Logger.log(ForwardServiceImpl.self, category: "LarkForward.ForwardServiceImpl")
    let dispatchQueue = DispatchQueue(label: "ForwardServiceImpl")
    var shareVideoWithChatInfoArray: [Chat] = []

    init(
        chatAPI: ChatAPI,
        sendMessageAPI: SendMessageAPI,
        imageProcessor: SendImageProcessor,
        sendThreadAPI: SendThreadAPI,
        messageAPI: MessageAPI,
        rustService: SDKRustService,
        passportUserService: PassportUserService) {
        self.chatAPI = chatAPI
        self.sendMessageAPI = sendMessageAPI
        self.imageProcessor = imageProcessor
        self.sendThreadAPI = sendThreadAPI
        self.messageAPI = messageAPI
        self.rustService = rustService
        self.passportUserService = passportUserService
    }

    // nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
    func forward(content: String, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            chatModels.forEach({ (chatModel) in
                let content = RustPB.Basic_V1_RichText.text(content)
                self?.sendMessageAPI.sendText(context: nil,
                                              content: content,
                                              parentMessage: nil,
                                              chatId: chatModel.id,
                                              threadId: nil,
                                              createScene: .commonShare,
                                              sendMessageTracker: nil,
                                              stateHandler: { status in
                                                switch status {
                                                case .finishSendMessage(_, _, let msgId, _, _):
                                                    if let msgId = msgId {
                                                        self?.sendReplyMessage(extraText: extraText, messageIDs: [msgId])
                                                    }
                                                default:
                                                    break
                                                }
                                              })
            })
            return chatModels.map({ return $0.id })
        }
    }

    func forward(content: String, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            chatModels.forEach({ (chatModel) in
                let content = RustPB.Basic_V1_RichText.text(content)
                self?.sendMessageAPI.sendText(context: nil,
                                              content: content,
                                              parentMessage: nil,
                                              chatId: chatModel.id,
                                              threadId: nil,
                                              createScene: .shareMinutes,
                                              scheduleTime: nil,
                                              sendMessageTracker: nil,
                                              stateHandler: { status in
                                                switch status {
                                                case .finishSendMessage(_, _, let msgId, _, _):
                                                    if let msgId = msgId {
                                                        self?.sendReplyMessage(attributeExtraText: attributeExtraText, messageIDs: [msgId])
                                                    }
                                                default:
                                                    break
                                                }
                                              })
            })
            return chatModels.map({ return $0.id })
        }
    }

    func forwardWithResults(content: String, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[(String, Bool)]> {
        func createSendMessageObservable(content: String, chatModel: Chat) -> Observable<(String, Bool)> {
            return Observable.create { [weak self] ob -> Disposable in
                guard let self = self else {
                    return Disposables.create()
                }
                let content = RustPB.Basic_V1_RichText.text(content)
                self.sendMessageAPI.sendText(context: nil,
                                              content: content,
                                              parentMessage: nil,
                                              chatId: chatModel.id,
                                              threadId: nil,
                                              createScene: .commonShare,
                                              scheduleTime: nil,
                                              sendMessageTracker: nil,
                                              stateHandler: { [weak self] status in
                                                switch status {
                                                case .finishSendMessage(_, _, let msgId, _, _):
                                                    if let msgId = msgId {
                                                        self?.sendReplyMessage(attributeExtraText: attributeExtraText, messageIDs: [msgId])
                                                    }
                                                    ob.onNext((chatModel.id, true))
                                                    ob.onCompleted()
                                                case .errorSendMessage(_, _), .errorQuasiMessage:
                                                    ob.onNext((chatModel.id, false))
                                                    ob.onCompleted()
                                                default:
                                                    break
                                                }
                                              })
                return Disposables.create()
            }
            .timeout(.seconds(10), scheduler: MainScheduler.instance) // 不确定status的出口只有三种，容错处理
            .catchErrorJustReturn((chatModel.id, false))
        }
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap { (chats: [Chat]) -> Observable<[(String, Bool)]> in
                let obs = chats.map { chat in
                    createSendMessageObservable(content: content, chatModel: chat)
                }
                return Observable.combineLatest(obs)
            }
    }

    func forwardWithResults(content: String, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[(String, Bool)]> {
        func createSendMessageObservable(content: String, chatModel: Chat) -> Observable<(String, Bool)> {
            return Observable.create { [weak self] ob -> Disposable in
                guard let self = self else {
                    return Disposables.create()
                }
                let content = RustPB.Basic_V1_RichText.text(content)
                self.sendMessageAPI.sendText(context: nil,
                                             content: content,
                                             parentMessage: nil,
                                             chatId: chatModel.id,
                                             threadId: nil,
                                             createScene: .commonShare,
                                             sendMessageTracker: nil,
                                             stateHandler: { [weak self] status in
                                                switch status {
                                                case .finishSendMessage(_, _, let msgId, _, _):
                                                    if let msgId = msgId {
                                                        self?.sendReplyMessage(extraText: extraText, messageIDs: [msgId])
                                                    }
                                                    ob.onNext((chatModel.id, true))
                                                    ob.onCompleted()
                                                case .errorSendMessage(_, _), .errorQuasiMessage:
                                                    ob.onNext((chatModel.id, false))
                                                    ob.onCompleted()
                                                default:
                                                    break
                                                }
                                              })
                return Disposables.create()
            }
            .timeout(.seconds(10), scheduler: MainScheduler.instance) // 不确定status的出口只有三种，容错处理
            .catchErrorJustReturn((chatModel.id, false))
        }
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap { (chats: [Chat]) -> Observable<[(String, Bool)]> in
                let obs = chats.map { chat in
                    createSendMessageObservable(content: content, chatModel: chat)
                }
                return Observable.combineLatest(obs)
            }
    }

    func forward(originMergeForwardId: String?,
                 type: TransmitType,
                 message: Message,
                 checkChatIDs: [String],
                 to chatIds: [String],
                 to threadIDAndChatIDs: [(messageID: String, chatID: String)],
                 userIds: [String],
                 extraText: String,
                 from: ForwardMessageBody.From) -> Observable<ForwardResponse> {
        return self.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIds)
            .flatMap { [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else {
                    return .just(([], nil))
                }
                Tracer.trackForwardNum(chatModels, isPostscript: extraText.isEmpty, from: from, message: message)
                let sendChatIDs = chatModels
                    .filter {
                        // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                        // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                        let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIds.contains($0.id)
                        return onlySendChatIDsFilter
                    }
                    .map { $0.id }
                return self.forward(
                    originMergeForwardId: originMergeForwardId,
                    context: nil,
                    type: type,
                    to: sendChatIDs,
                    to: threadIDAndChatIDs.filter { chatModels.map { $0.id }.contains($1) }
                    ).do(onNext: { [weak self] (response) in
                        let parentMessageIDs = Array(response.messageIds.values) + response.message2Threads.keys
                        guard let `self` = self else { return }
                        self.sendReplyMessage(
                            extraText: extraText,
                            messageIDs: parentMessageIDs
                        )
                    }).map({ response in return (chatModels.map({ $0.id }), response.hasFilePermCheck ? response.filePermCheck : nil) })
            }
    }

    func forward(originMergeForwardId: String?,
                 type: TransmitType,
                 message: Message,
                 checkChatIDs: [String],
                 to chatIds: [String],
                 to threadIDAndChatIDs: [(messageID: String, chatID: String)],
                 userIds: [String],
                 attributeExtraText: NSAttributedString,
                 from: ForwardMessageBody.From) -> Observable<ForwardResponse> {
        return self.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIds)
            .flatMap { [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else {
                    return .just(([], nil))
                }
                Tracer.trackForwardNum(chatModels, isPostscript: attributeExtraText.length == 0, from: from, message: message)
                let sendChatIDs = chatModels
                    .filter {
                        // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                        // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                        let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIds.contains($0.id)
                        return onlySendChatIDsFilter
                    }
                    .map { $0.id }
                return self.forward(
                    originMergeForwardId: originMergeForwardId,
                    context: nil,
                    type: type,
                    to: sendChatIDs,
                    to: threadIDAndChatIDs.filter { chatModels.map { $0.id }.contains($1) }
                    ).do(onNext: { [weak self] (response) in
                        let parentMessageIDs = Array(response.messageIds.values) + response.message2Threads.keys
                        guard let `self` = self else { return }
                        self.sendReplyMessage(
                            attributeExtraText: attributeExtraText,
                            messageIDs: parentMessageIDs
                        )
                    }).map({ response in return (chatModels.map({ $0.id }), response.hasFilePermCheck ? response.filePermCheck : nil) })
            }
    }

    /// 逐条转发
    /// - Returns: 观察序列
    func batchTransmitForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        extraText: String) -> Observable<ForwardResponse> {
        //checkAndCreateChats 会检测当前的chat是否存在 不存在需要创建一个 比如转发给小A-> 但是从未跟小A聊天 需要创建一些chat
        return self.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIds)
            .flatMap({ [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else {
                    return .just(([], nil))
                }
                let sendChatIDs = chatModels
                    .filter {
                        // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                        // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                        let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIds.contains($0.id)
                        return onlySendChatIDsFilter
                    }.map { $0.id }
                return self.batchTransmit(
                    context: nil,
                    originMergeForwardId: originMergeForwardId,
                    messageIds: messageIds,
                    to: sendChatIDs
                ).do(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    if !extraText.isEmpty {
                        let extraContent = RustPB.Basic_V1_RichText.text(extraText)
                        sendChatIDs.forEach { (chatID) in
                            self.sendMessageAPI.sendText(
                                context: nil,
                                content: extraContent,
                                parentMessage: nil,
                                chatId: chatID,
                                threadId: nil,
                                stateHandler: nil
                            )
                        }
                    }
                }).map({ response in return (chatModels.map({ $0.id }), response.hasFilePermCheck ? response.filePermCheck : nil) })
            })
    }

    func batchTransmitForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        attributeExtraText: NSAttributedString) -> Observable<ForwardResponse> {
        //checkAndCreateChats 会检测当前的chat是否存在 不存在需要创建一个 比如转发给小A-> 但是从未跟小A聊天 需要创建一些chat
        return self.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIds)
            .flatMap({ [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else {
                    return .just(([], nil))
                }
                let sendChatIDs = chatModels
                    .filter {
                        // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                        // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                        let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIds.contains($0.id)
                        return onlySendChatIDsFilter
                    }.map { $0.id }
                return self.batchTransmit(
                    context: nil,
                    originMergeForwardId: originMergeForwardId,
                    messageIds: messageIds,
                    to: sendChatIDs
                ).do(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    if attributeExtraText.length != 0 {
                        if var richText = RichTextTransformKit.transformStringToRichText(string: attributeExtraText) {
                            richText.richTextVersion = 1
                            sendChatIDs.forEach { (chatID) in
                                self.sendMessageAPI.sendText(
                                    context: nil,
                                    content: richText,
                                    parentMessage: nil,
                                    chatId: chatID,
                                    threadId: nil,
                                    stateHandler: nil
                                )
                            }
                        }
                    }
                }).map({ response in return (chatModels.map({ $0.id }), response.hasFilePermCheck ? response.filePermCheck : nil) })
            })
    }

    private func sendReplyMessage(extraText: String, messageIDs: [String], threadModeChatIds: [String]? = nil) {
        if !extraText.isEmpty {
            let extraContent = RustPB.Basic_V1_RichText.text(extraText)
            self.messageAPI.fetchMessages(ids: messageIDs).subscribe(onNext: { [weak self] (messages) in
                guard let `self` = self else {
                    return
                }
                // 对每一个chat中新转发生成message，发送一条回复。
                messages.forEach({ (message) in
                    // 使用messageId 找出message实体，进行回复。
                    let context = APIContext(contextID: "")
                    let inThreadModeChat = threadModeChatIds?.contains(where: { $0 == message.channel.id }) ?? false
                    /// 转发到replyinThread中的消息 position都为 replyInThreadMessagePosition
                    let isReplyInThread = message.position == replyInThreadMessagePosition
                    //转发到话题模式群里时，转发的消息会直接创建成话题，所以回复也走isReplyInThread流程处理
                    context.set(key: APIContext.replyInThreadKey, value: isReplyInThread)
                    var parentMessage: Message?
                    if isReplyInThread {
                        // 如果是reply in thread 就是对thread根消息的回复 message.parentMessage
                        parentMessage = message.parentMessage
                    } else {
                        // 如果不是 reply in thread 就是对之前发送的消息的回复 message
                        // 话题模式转发也走这个分支，reply in thread 转发是根话题已经存在了，话题模式转发，根消息是转发当次生成的
                        parentMessage = message
                    }
                    var threadId: String?
                    if isReplyInThread || inThreadModeChat {
                        threadId = message.threadId
                    }
                    self.sendMessageAPI.sendText(
                        context: context,
                        content: extraContent,
                        parentMessage: parentMessage,
                        chatId: message.channel.id,
                        threadId: threadId,
                        stateHandler: nil
                    )
                })
            }).disposed(by: self.disposeBag)
        }
    }

    private func sendReplyMessage(attributeExtraText: NSAttributedString, messageIDs: [String], threadModeChatIds: [String]? = nil) {
        if attributeExtraText.length != 0 {
            if var richText = RichTextTransformKit.transformStringToRichText(string: attributeExtraText) {
                richText.richTextVersion = 1
                self.messageAPI.fetchMessages(ids: messageIDs).subscribe(onNext: { [weak self] (messages) in
                    guard let `self` = self else {
                        return
                    }
                    // 对每一个chat中新转发生成message，发送一条回复。
                    messages.forEach({ (message) in
                        // 使用messageId 找出message实体，进行回复。
                        let context = APIContext(contextID: "")
                        let inThreadModeChat = threadModeChatIds?.contains(where: { $0 == message.channel.id }) ?? false
                        /// 转发到replyinThread中的消息 position都为 replyInThreadMessagePosition
                        let isReplyInThread = message.position == replyInThreadMessagePosition
                        //转发到话题模式群里时，转发的消息会直接创建成话题，所以回复也走isReplyInThread流程处理
                        context.set(key: APIContext.replyInThreadKey, value: isReplyInThread || inThreadModeChat)
                        var parentMessage: Message?
                        if isReplyInThread {
                            // 如果是reply in thread 就是对thread根消息的回复 message.parentMessage
                            parentMessage = message.parentMessage
                        } else {
                            // 如果不是 reply in thread 就是对之前发送的消息的回复 message
                            // 话题模式转发也走这个分支，reply in thread 转发是根话题已经存在了，话题模式转发，根消息是转发当次生成的
                            parentMessage = message
                        }
                        var threadId: String?
                        if isReplyInThread || inThreadModeChat {
                            threadId = message.threadId
                        }
                        self.sendMessageAPI.sendText(
                            context: context,
                            content: richText,
                            parentMessage: parentMessage,
                            chatId: message.channel.id,
                            threadId: threadId,
                            stateHandler: nil
                        )
                    })
                }).disposed(by: self.disposeBag)
            }
        }
    }

    func mergeForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        title: String,
        extraText: String,
        needQuasiMessage: Bool) -> Observable<ForwardResponse> {
        return self.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIds)
            .flatMap({ [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else {
                    return .just(([], nil))
                }
                let sendChatIDs = chatModels
                    .filter {
                        // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                        // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                        let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIds.contains($0.id)
                        return onlySendChatIDsFilter
                    }
                    .map { $0.id }
                return self.mergeForward(
                    context: nil,
                    originMergeForwardId: originMergeForwardId,
                    messageIds: messageIds,
                    to: sendChatIDs,
                    to: threadIDAndChatIDs.filter { chatModels.map { $0.id }.contains($1) },
                    title: title,
                    needQuasiMessage: needQuasiMessage
                ).do(onNext: { [weak self] (response) in
                    guard let `self` = self else { return }
                    let parentMessageIDs = Array(response.messageIds.values) + response.message2Threads.keys
                    self.sendReplyMessage(
                        extraText: extraText,
                        messageIDs: parentMessageIDs
                    )
                }).map({ response in return (chatModels.map({ $0.id }), response.hasFilePermCheck ? response.filePermCheck : nil) })
            })
    }

    func mergeForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        title: String,
        attributeExtraText: NSAttributedString,
        needQuasiMessage: Bool) -> Observable<ForwardResponse> {
        return self.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIds)
            .flatMap({ [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else {
                    return .just(([], nil))
                }
                let sendChatIDs = chatModels
                    .filter {
                        // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                        // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                        let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIds.contains($0.id)
                        return onlySendChatIDsFilter
                    }
                    .map { $0.id }
                return self.mergeForward(
                    context: nil,
                    originMergeForwardId: originMergeForwardId,
                    messageIds: messageIds,
                    to: sendChatIDs,
                    to: threadIDAndChatIDs.filter { chatModels.map { $0.id }.contains($1) },
                    title: title,
                    needQuasiMessage: needQuasiMessage
                ).do(onNext: { [weak self] (response) in
                    guard let `self` = self else { return }
                    let parentMessageIDs = Array(response.messageIds.values) + response.message2Threads.keys
                    self.sendReplyMessage(
                        attributeExtraText: attributeExtraText,
                        messageIDs: parentMessageIDs
                    )
                }).map({ response in return (chatModels.map({ $0.id }), response.hasFilePermCheck ? response.filePermCheck : nil) })
            })
    }

    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        title: String,
        isLimit: Bool,
        extraText: String) -> Observable<ForwardResponse> {
            return self.mergeForward(originMergeForwardId: originMergeForwardId,
                                     threadID: threadID,
                                     needCopyReaction: needCopyReaction,
                                     checkChatIDs: checkChatIDs,
                                     to: chatIDs,
                                     to: threadIDAndChatIDs,
                                     threadModeChatIds: [],
                                     title: title,
                                     isLimit: isLimit, extraText: extraText)
    }

    // swiftlint:disable function_parameter_count
    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        threadModeChatIds: [String],
        title: String,
        isLimit: Bool,
        extraText: String) -> Observable<ForwardResponse> {
        return self.threadMergeForward(
            originMergeForwardId: originMergeForwardId,
            threadID: threadID,
            needCopyReaction: needCopyReaction,
            to: chatIDs,
            to: threadIDAndChatIDs,
            title: title,
            limited: isLimit
        ).do(onNext: { [weak self] (response) in
            let parentMessageIDs = Array(response.messageIds.values) + response.message2Threads.keys
            guard let `self` = self else { return }
            self.sendReplyMessage(
                extraText: extraText,
                messageIDs: parentMessageIDs,
                threadModeChatIds: threadModeChatIds
            )
        }).map({ response in return (checkChatIDs, response.hasFilePermCheck ? response.filePermCheck : nil) })
    }
    // swiftlint:enable function_parameter_count

    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        title: String,
        isLimit: Bool,
        attributeExtraText: NSAttributedString) -> Observable<ForwardResponse> {
            return self.mergeForward(originMergeForwardId: originMergeForwardId,
                                     threadID: threadID,
                                     needCopyReaction: needCopyReaction,
                                     checkChatIDs: checkChatIDs,
                                     to: chatIDs,
                                     to: threadIDAndChatIDs,
                                     threadModeChatIds: [],
                                     title: title, isLimit: isLimit,
                                     attributeExtraText: attributeExtraText)
    }

    // swiftlint:disable function_parameter_count
    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        threadModeChatIds: [String],
        title: String,
        isLimit: Bool,
        attributeExtraText: NSAttributedString) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)> {
            return self.threadMergeForward(
                originMergeForwardId: originMergeForwardId,
                threadID: threadID,
                needCopyReaction: needCopyReaction,
                to: chatIDs,
                to: threadIDAndChatIDs,
                title: title,
                limited: isLimit
            ).do(onNext: { [weak self] (response) in
                let parentMessageIDs = Array(response.messageIds.values) + response.message2Threads.keys
                guard let `self` = self else { return }
                self.sendReplyMessage(
                    attributeExtraText: attributeExtraText,
                    messageIDs: parentMessageIDs,
                    threadModeChatIds: threadModeChatIds
                )
            }).map({ response in return (checkChatIDs, response.hasFilePermCheck ? response.filePermCheck : nil) })
    }
    // swiftlint:enable function_parameter_count

    func checkAndCreateChats(chatIds: [String], userIds: [String]) -> Observable<[Chat]> {
        var results: [Chat] = []
        var userIdsHasNoChat: [String] = []

        return chatAPI.fetchChats(by: chatIds, forceRemote: false)
            .do(onNext: { (chatsMap) in
                let chats = chatsMap.compactMap({ $1 })
                results.append(contentsOf: chats)
            })
            .catchErrorJustReturn([:])
            .flatMap({ _ -> Observable<[Chat]> in
                return self.chatAPI.fetchLocalP2PChatsByUserIds(uids: userIds)
                    .do(onNext: { (chatsDic) in
                        userIds.forEach { (userId) in
                            if let chat = chatsDic[userId] {
                                results.append(chat)
                            } else {
                                userIdsHasNoChat.append(userId)
                            }
                        }
                    })
                    .catchErrorJustReturn([:])
                    .flatMap({ _ -> Observable<[Chat]> in
                        if !userIdsHasNoChat.isEmpty {
                            return self.chatAPI.createP2pChats(uids: userIdsHasNoChat).map {
                                results.append(contentsOf: $0)
                                return results
                            }
                        } else {
                            return .just(results)
                        }
                    })
            })
            .observeOn(MainScheduler.instance)
    }

    func forwardCopyFromFolderMessage(folderMessageId: String,
                                      key: String,
                                      chatIds: [String],
                                      userIds: [String],
                                      threadIDAndChatIDs: [(threadID: String, chatID: String)],
                                      extraText: String) -> Observable<ForwardResponse> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap({ [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else { return .just(([], nil)) }
                var sendChannelTypes: [SendChannelType] = chatModels.map { .chat(id: $0.id) }
                sendChannelTypes.append(contentsOf: threadIDAndChatIDs.map { .thread(threadID: $0.threadID, chatID: $0.chatID) })

                return self.forwardCopyFromFolderMessage(
                    context: nil,
                    folderMessageId: folderMessageId,
                    key: key,
                    sendChannelTypes: sendChannelTypes
                )
                .do(onNext: { [weak self] (response) in
                    guard let `self` = self else { return }
                    let parentMessageIDs = response.respInfo.filter { $0.hasMessageID }.map { $0.messageID }
                    self.sendReplyMessage(extraText: extraText, messageIDs: parentMessageIDs)
                })
                    .map { response in
                        var chatArray = chatModels.map({ $0.id })
                        chatArray.lf_appendContentsIfNotContains(threadIDAndChatIDs.map { $0.chatID })
                        return (chatArray, response.hasFilePermCheck ? response.filePermCheck : nil)
                    }
            })

    }

    func forwardCopyFromFolderMessage(folderMessageId: String,
                                      key: String,
                                      chatIds: [String],
                                      userIds: [String],
                                      threadIDAndChatIDs: [(threadID: String, chatID: String)],
                                      attributeExtraText: NSAttributedString) -> Observable<ForwardResponse> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap({ [weak self] (chatModels) -> Observable<ForwardResponse> in
                guard let `self` = self else { return .just(([], nil)) }
                var sendChannelTypes: [SendChannelType] = chatModels.map { .chat(id: $0.id) }
                sendChannelTypes.append(contentsOf: threadIDAndChatIDs.map { .thread(threadID: $0.threadID, chatID: $0.chatID) })

                return self.forwardCopyFromFolderMessage(
                    context: nil,
                    folderMessageId: folderMessageId,
                    key: key,
                    sendChannelTypes: sendChannelTypes
                )
                .do(onNext: { [weak self] (response) in
                    guard let `self` = self else { return }
                    let parentMessageIDs = response.respInfo.filter { $0.hasMessageID }.map { $0.messageID }
                    self.sendReplyMessage(attributeExtraText: attributeExtraText, messageIDs: parentMessageIDs)
                })
                    .map { response in
                        var chatArray = chatModels.map({ $0.id })
                        chatArray.lf_appendContentsIfNotContains(threadIDAndChatIDs.map { $0.chatID })
                        return (chatArray, response.hasFilePermCheck ? response.filePermCheck : nil)
                    }
            })

    }

    func share(shareChatterId: String,
               message: String?,
               chatIds: [String],
               userIds: [String],
               threadIDAndChatIDs: [(threadID: String, chatID: String)]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            let stateHandler: (SendMessageState) -> Void = { [weak self] state in
                if case .finishSendMessage(_, _, let messageId, _, _) = state {
                    if let id = messageId {
                        self?.sendReplyMessage(extraText: message ?? "", messageIDs: [id])
                    }
                }
            }

            chatModels.forEach { (chatModel) in
                self?.sendMessageAPI.sendShareUserCardMessage(context: nil,
                                                              shareChatterId: shareChatterId,
                                                              sendChannelType: .chat(id: chatModel.id),
                                                              createScene: .commonShare,
                                                              sendMessageTracker: nil,
                                                              stateHandler: stateHandler)
            }
            threadIDAndChatIDs.forEach { (threadIDAndChatID) in
                self?.sendMessageAPI.sendShareUserCardMessage(context: nil,
                                                              shareChatterId: shareChatterId,
                                                              sendChannelType: .thread(threadID: threadIDAndChatID.threadID, chatID: threadIDAndChatID.chatID),
                                                              createScene: .commonShare,
                                                              sendMessageTracker: nil,
                                                              stateHandler: stateHandler)
            }

            var chatArray = chatModels.map({ $0.id })
            chatArray.lf_appendContentsIfNotContains(threadIDAndChatIDs.map { $0.chatID })
            return chatArray
        }
    }

    func share(shareChatterId: String,
               attributeMessage: NSAttributedString?,
               chatIds: [String],
               userIds: [String],
               threadIDAndChatIDs: [(threadID: String, chatID: String)]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            let stateHandler: (SendMessageState) -> Void = { [weak self] state in
                if case .finishSendMessage(_, _, let messageId, _, _) = state {
                    if let id = messageId {
                        self?.sendReplyMessage(attributeExtraText: attributeMessage ?? NSAttributedString(string: ""), messageIDs: [id])
                    }
                }
            }

            chatModels.forEach { (chatModel) in
                self?.sendMessageAPI.sendShareUserCardMessage(context: nil,
                                                              shareChatterId: shareChatterId,
                                                              sendChannelType: .chat(id: chatModel.id),
                                                              createScene: .commonShare,
                                                              sendMessageTracker: nil,
                                                              stateHandler: stateHandler)
            }
            threadIDAndChatIDs.forEach { (threadIDAndChatID) in
                self?.sendMessageAPI.sendShareUserCardMessage(context: nil,
                                                              shareChatterId: shareChatterId,
                                                              sendChannelType: .thread(threadID: threadIDAndChatID.threadID, chatID: threadIDAndChatID.chatID),
                                                              createScene: .commonShare,
                                                              sendMessageTracker: nil,
                                                              stateHandler: stateHandler)
            }

            var chatArray = chatModels.map({ $0.id })
            chatArray.lf_appendContentsIfNotContains(threadIDAndChatIDs.map { $0.chatID })
            return chatArray
        }
    }

    /// 转发群名片
    func share(chat: Chat, message: String?, to chatIds: [String], userIds: [String]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            chatModels.forEach({ (shareTo) in
                self?.sendMessageAPI.sendGroupShare(context: nil, sharChatId: chat.id, chatId: shareTo.id, threadId: nil, createScene: .commonShare, stateHandler: { (state) in
                    if case .finishSendMessage(_, _, let messageId, _, _) = state {
                        if let id = messageId, let message = message, !message.isEmpty {
                            self?.sendReplyMessage(extraText: message, messageIDs: [id])
                        }
                    }
                })
            })
            return chatModels.map({ $0.id })
        }
    }

    func share(chat: Chat, attributeMessage: NSAttributedString?, to chatIds: [String], userIds: [String]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            chatModels.forEach({ (shareTo) in
                self?.sendMessageAPI.sendGroupShare(context: nil, sharChatId: chat.id, chatId: shareTo.id, threadId: nil, createScene: .commonShare, stateHandler: { (state) in
                    if case .finishSendMessage(_, _, let messageId, _, _) = state {
                        if let id = messageId, let attributeMessage = attributeMessage, attributeMessage.length != 0 {
                            self?.sendReplyMessage(attributeExtraText: attributeMessage, messageIDs: [id])
                        }
                    }
                })
            })
            return chatModels.map({ $0.id })
        }
    }

    /// 群名片转发至话题时同时需要话题的channelID(chatID)和threadID,threadMessageIdDic中key为channelID,value为threadID,若仅有channelID转发会生成新话题
    func share(chat: Chat, attributeMessage: NSAttributedString?, threadMessageIdDic: [String: String], to chatIds: [String], userIds: [String]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            chatModels.forEach({ (shareTo) in
                let threadId = threadMessageIdDic[shareTo.id]
                self?.sendMessageAPI.sendGroupShare(context: nil, sharChatId: chat.id, chatId: shareTo.id, threadId: threadId, createScene: .shareGroupChat, stateHandler: { (state) in
                    if case .finishSendMessage(_, _, let messageId, _, _) = state {
                        if let id = messageId, let attributeMessage = attributeMessage, attributeMessage.length != 0 {
                            self?.sendReplyMessage(attributeExtraText: attributeMessage, messageIDs: [id])
                        }
                    }
                })
            })
            return chatModels.map({ $0.id })
        }
    }

    func share(image: UIImage, message: String?, to chatIds: [String], userIds: [String]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            guard let `self` = self else { return [] }
            chatModels.forEach({ (chatModel) in
                let forwardSendImage = SendImageUploadByForward(sendMessageAPI: self.sendMessageAPI, chatModel: chatModel)
                // 生成imageRequest
                let sendImageRequest = SendImageRequest(
                    input: .image(image),
                    sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true, needConvertToWebp: LarkImageService.shared.imageUploadWebP, scene: .Forward, fromType: .image)),
                    uploader: forwardSendImage)
                sendImageRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
                SendImageManager.shared
                    .sendImage(request: sendImageRequest)
                    .subscribe(onNext: { [weak self] messageId in
                        ForwardServiceImpl.logger.info("share image onNext: \(messageId)")
                        if let id = messageId {
                            self?.sendReplyMessage(extraText: message ?? "", messageIDs: [id])
                        }
                    }, onError: { error in
                        ForwardServiceImpl.logger.error("share image error: \(error)")
                    }, onCompleted: {
                        ForwardServiceImpl.logger.info("share image onCompleted")
                    }).disposed(by: self.disposeBag)
            })
            return chatModels.map({ $0.id })
        }
    }

    func share(image: UIImage, attributeMessage: NSAttributedString?, to chatIds: [String], userIds: [String]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            guard let `self` = self else { return [] }
            chatModels.forEach({ (chatModel) in
                let forwardSendImage = SendImageUploadByForward(sendMessageAPI: self.sendMessageAPI, chatModel: chatModel)
                // 生成imageRequest
                let sendImageRequest = SendImageRequest(
                    input: .image(image),
                    sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true, needConvertToWebp: LarkImageService.shared.imageUploadWebP, scene: .Forward, fromType: .image)),
                    uploader: forwardSendImage)
                sendImageRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
                SendImageManager.shared
                    .sendImage(request: sendImageRequest)
                    .subscribe(onNext: { [weak self] messageId in
                        ForwardServiceImpl.logger.info("share image onNext: \(messageId)")
                        if let id = messageId {
                            self?.sendReplyMessage(attributeExtraText: attributeMessage ?? NSAttributedString(string: ""), messageIDs: [id])
                        }
                    }, onError: { error in
                        ForwardServiceImpl.logger.error("share image error: \(error)")
                    }, onCompleted: {
                        ForwardServiceImpl.logger.info("share image onCompleted")
                    }).disposed(by: self.disposeBag)
            })
            return chatModels.map({ $0.id })
        }
    }

    func shareWithResults(image: UIImage, attributeMessage: NSAttributedString?, to chatIds: [String], userIds: [String]) -> Observable<[(String, Bool)]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).flatMap { (chatModels) -> Observable<[(String, Bool)]> in
            let obSequence = chatModels.map({ (chatModel) -> Observable<(String, Bool)> in
                let forwardSendImage = SendImageUploadByForward(sendMessageAPI: self.sendMessageAPI, chatModel: chatModel)
                // 生成imageRequest
                let sendImageRequest = SendImageRequest(
                    input: .image(image),
                    sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true, needConvertToWebp: LarkImageService.shared.imageUploadWebP, scene: .Forward, fromType: .image)),
                    uploader: forwardSendImage)
                sendImageRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
                return SendImageManager.shared
                    .sendImage(request: sendImageRequest)
                    .do(onNext: { [weak self] messageId in
                        ForwardServiceImpl.logger.info("share image onNext: \(messageId)")
                        if let id = messageId {
                            self?.sendReplyMessage(attributeExtraText: attributeMessage ?? NSAttributedString(string: ""), messageIDs: [id])
                        }
                    }, onError: {
                        ForwardServiceImpl.logger.error("share image error: \($0)")
                    }, onCompleted: {
                        ForwardServiceImpl.logger.info("share image onCompleted")
                    })
                    .map { _ in
                        (chatModel.id, true)
                    }
                    .catchErrorJustReturn((chatModel.id, false))
            })
            return Observable.combineLatest(obSequence)
        }
    }

    func shareWithResults(image: UIImage, message: String?, to chatIds: [String], userIds: [String]) -> Observable<[(String, Bool)]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap { (chatModels) -> Observable<[(String, Bool)]> in
                let obSequence = chatModels.map({ (chatModel) -> Observable<(String, Bool)> in
                    let forwardSendImage = SendImageUploadByForward(sendMessageAPI: self.sendMessageAPI, chatModel: chatModel)
                    // 生成imageRequest
                    let sendImageRequest = SendImageRequest(
                        input: .image(image),
                        sendImageConfig: SendImageConfig(
                            checkConfig: SendImageCheckConfig(isOrigin: true, needConvertToWebp: LarkImageService.shared.imageUploadWebP, scene: .Forward, fromType: .image)),
                        uploader: forwardSendImage)
                    sendImageRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
                    return SendImageManager.shared
                        .sendImage(request: sendImageRequest)
                        .do(onNext: { [weak self] messageId in
                            ForwardServiceImpl.logger.info("share image onNext: \(messageId)")
                            if let id = messageId {
                                self?.sendReplyMessage(extraText: message ?? "", messageIDs: [id])
                            }
                        }, onError: {
                            ForwardServiceImpl.logger.error("share image error: \($0)")
                        }, onCompleted: {
                            ForwardServiceImpl.logger.info("share image onCompleted")
                        })
                            .map { _ in
                                (chatModel.id, true)
                            }
                            .catchErrorJustReturn((chatModel.id, false))
                })
                return Observable.combineLatest(obSequence)
            }
    }

    func share(imageUrls: [URL], extraText: String?, to chatIds: [String], userIds: [String]) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).map { [weak self] (chatModels) -> [String] in
            guard let `self` = self else { return [] }
            chatModels.forEach { chatModel in
                if let extraText = extraText, !extraText.isEmpty {
                    let extraContent = RustPB.Basic_V1_RichText.text(extraText)
                    self.sendMessageAPI.sendText(context: nil,
                                                 content: extraContent,
                                                 parentMessage: nil,
                                                 chatId: chatModel.id,
                                                 threadId: nil,
                                                 stateHandler: nil)
                }
                self.shareImages(imageUrls, chatId: chatModel.id)
            }
            return chatModels.map({ $0.id })
        }
    }
    // enable-lint: duplicated_code
}

extension ForwardServiceImpl {
    // nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
    func share(fileUrl: String, fileName: String, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[(String, Bool)]> {
        func createSendFileObservable(fileUrl: String, fileName: String, chatModel: Chat) -> Observable<(String, Bool)> {
            return Observable.create { [weak self] ob -> Disposable in
                guard let self = self else {
                    return Disposables.create()
                }
                self.sendMessageAPI.sendFile(context: nil,
                                             path: fileUrl,
                                             name: fileName,
                                             parentMessage: nil,
                                             removeOriginalFileAfterFinish: false,
                                             chatId: chatModel.id,
                                             threadId: nil,
                                             createScene: .commonShare,
                                             sendMessageTracker: nil,
                                             stateHandler: { [weak self] status in
                                                switch status {
                                                case .finishSendMessage(_, _, let msgId, _, _):
                                                    if let msgId = msgId {
                                                        self?.sendReplyMessage(extraText: extraText, messageIDs: [msgId])
                                                    }
                                                    ob.onNext((chatModel.id, true))
                                                    ob.onCompleted()
                                                case .errorSendMessage(_, _), .errorQuasiMessage:
                                                    ob.onNext((chatModel.id, false))
                                                    ob.onCompleted()
                                                default:
                                                    break
                                                }
                                              })
                return Disposables.create()
            }
            .timeout(.seconds(10), scheduler: MainScheduler.instance) // 不确定status的出口只有三种，容错处理
            .catchErrorJustReturn((chatModel.id, false))
        }
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap { (chats: [Chat]) -> Observable<[(String, Bool)]> in
                let obs = chats.map { chat in
                    createSendFileObservable(fileUrl: fileUrl, fileName: fileName, chatModel: chat)
                }
                return Observable.combineLatest(obs)
            }
    }

    func share(fileUrl: String, fileName: String, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[(String, Bool)]> {
        func createSendFileObservable(fileUrl: String, fileName: String, chatModel: Chat) -> Observable<(String, Bool)> {
            return Observable.create { [weak self] ob -> Disposable in
                guard let self = self else {
                    return Disposables.create()
                }
                self.sendMessageAPI.sendFile(context: nil,
                                             path: fileUrl,
                                             name: fileName,
                                             parentMessage: nil,
                                             removeOriginalFileAfterFinish: false,
                                             chatId: chatModel.id,
                                             threadId: nil,
                                             createScene: .commonShare,
                                             sendMessageTracker: nil,
                                             stateHandler: { [weak self] status in
                                                switch status {
                                                case .finishSendMessage(_, _, let msgId, _, _):
                                                    if let msgId = msgId {
                                                        self?.sendReplyMessage(attributeExtraText: attributeExtraText, messageIDs: [msgId])
                                                    }
                                                    ob.onNext((chatModel.id, true))
                                                    ob.onCompleted()
                                                case .errorSendMessage(_, _), .errorQuasiMessage:
                                                    ob.onNext((chatModel.id, false))
                                                    ob.onCompleted()
                                                default:
                                                    break
                                                }
                                              })
                return Disposables.create()
            }
            .timeout(.seconds(10), scheduler: MainScheduler.instance) // 不确定status的出口只有三种，容错处理
            .catchErrorJustReturn((chatModel.id, false))
        }
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds)
            .flatMap { (chats: [Chat]) -> Observable<[(String, Bool)]> in
                let obs = chats.map { chat in
                    createSendFileObservable(fileUrl: fileUrl, fileName: fileName, chatModel: chat)
                }
                return Observable.combineLatest(obs)
            }
    }

    func addChatInfosInShareVideo(chat: Chat) {
        shareVideoWithChatInfoArray.append(chat)
    }

    func getAndDeleteChatInfoInShareVideo() -> [Chat] {
        let temp = shareVideoWithChatInfoArray
        shareVideoWithChatInfoArray = []
        return temp
    }

    func extensionShare(content data: Data, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).flatMap({ [weak self] (chatModels) -> Observable<[String]> in
            return Observable<[String]>.create({ (observer) -> Disposable in
                let error = NSError(domain: "ShareExtension.readData.error", code: NSPropertyListReadStreamError, userInfo: nil) as Error
                guard let chat = chatModels.first,
                    let content: ShareContent = ShareContent(data),
                    let `self` = self else {
                        observer.onError(error)
                        return Disposables.create()
                }
                let shareType: String
                switch content.contentType {
                case .text:
                    guard let item = ShareTextItem(content.contentData) else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "text"
                    let content = RustPB.Basic_V1_RichText.text(item.text)
                    self.sendMessageAPI.sendText(context: nil,
                                                 content: content,
                                                 parentMessage: nil,
                                                 chatId: chat.id,
                                                 threadId: nil,
                                                 createScene: .commonShare,
                                                 sendMessageTracker: nil,
                                                 stateHandler: nil)
                case .image:
                    guard let urls = ShareImageItem(content.contentData)?.images, !urls.isEmpty else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "image"
                    self.shareImages(urls, chatId: chat.id)
                case .movie:
                    shareType = "movie"
                    self.addChatInfosInShareVideo(chat: chat)
                case .fileUrl:
                    guard let item = ShareFileItem(content.contentData) else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "file"
                    self.sendExtensionShareFile(item, chatId: chat.id)
                case .multiple:
                    guard let item = ShareMultipleItem(content.contentData) else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "multiple"
                    self.sendExtensionShareMutiple(item, chatId: chat.id)
                @unknown default:
                    assert(false, "new value")
                    shareType = "unknown"
                }

                if !extraText.isEmpty {
                    let extraContent = RustPB.Basic_V1_RichText.text(extraText)
                    self.sendMessageAPI.sendText(context: nil,
                                                 content: extraContent,
                                                 parentMessage: nil,
                                                 chatId: chat.id,
                                                 threadId: nil,
                                                 createScene: .commonShare,
                                                 sendMessageTracker: nil,
                                                 stateHandler: nil)
                }

                Tracer.trackSysShare(shareType: shareType)
                ForwardServiceImpl.logger.info("extension share type: \(shareType)")
                observer.onNext(chatModels.map({ $0.id }))
                observer.onCompleted()
                return Disposables.create()
            })
        })
    }

    func extensionShare(content data: Data, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[String]> {
        return self.checkAndCreateChats(chatIds: chatIds, userIds: userIds).flatMap({ [weak self] (chatModels) -> Observable<[String]> in
            return Observable<[String]>.create({ (observer) -> Disposable in
                let error = NSError(domain: "ShareExtension.readData.error", code: NSPropertyListReadStreamError, userInfo: nil) as Error
                guard let chat = chatModels.first,
                    let content: ShareContent = ShareContent(data),
                    let `self` = self else {
                        observer.onError(error)
                        return Disposables.create()
                }
                let shareType: String
                switch content.contentType {
                case .text:
                    guard let item = ShareTextItem(content.contentData) else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "text"
                    let content = RustPB.Basic_V1_RichText.text(item.text)
                    self.sendMessageAPI.sendText(context: nil,
                                                 content: content,
                                                 parentMessage: nil,
                                                 chatId: chat.id,
                                                 threadId: nil,
                                                 createScene: .commonShare,
                                                 sendMessageTracker: nil,
                                                 stateHandler: nil)
                case .image:
                    guard let urls = ShareImageItem(content.contentData)?.images, !urls.isEmpty else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "image"
                    self.shareImages(urls, chatId: chat.id)
                case .movie:
                    shareType = "movie"
                    self.addChatInfosInShareVideo(chat: chat)
                case .fileUrl:
                    guard let item = ShareFileItem(content.contentData) else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "file"
                    self.sendExtensionShareFile(item, chatId: chat.id)
                case .multiple:
                    guard let item = ShareMultipleItem(content.contentData) else {
                        observer.onError(error)
                        return Disposables.create()
                    }
                    shareType = "multiple"
                    self.sendExtensionShareMutiple(item, chatId: chat.id)
                @unknown default:
                    assert(false, "new value")
                    shareType = "unknown"
                }

                if attributeExtraText.length != 0 {
                    if var richText = RichTextTransformKit.transformStringToRichText(string: attributeExtraText) {
                        richText.richTextVersion = 1
                        self.sendMessageAPI.sendText(context: nil,
                                                     content: richText,
                                                     parentMessage: nil,
                                                     chatId: chat.id,
                                                     threadId: nil,
                                                     createScene: .commonShare,
                                                     sendMessageTracker: nil,
                                                     stateHandler: nil)
                    }
                }

                Tracer.trackSysShare(shareType: shareType)

                observer.onNext(chatModels.map({ $0.id }))
                observer.onCompleted()
                return Disposables.create()
            })
        })
    }

    private func shareImages(_ images: [URL], chatId: String) {
        /// `Data(contentsOf: url)` may lead dead lock with first dyld_stub_binder called, so bring it to sub-thread.
        dispatchQueue.async { [weak self] in
            guard let `self` = self else { return }
            let dataArray: [Data] = images.compactMap { url -> Data? in
                return try? Data.read(from: url.asAbsPath())
            }
            let sendImageByExtension = SendImageUploadByExtension(urls: images, chatId: chatId, sendMessageAPI: self.sendMessageAPI)
            let sendImageRequest = SendImageRequest(
                input: .datas(dataArray),
                sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true, needConvertToWebp: LarkImageService.shared.imageUploadWebP, scene: .Forward, fromType: .image)),
                uploader: sendImageByExtension)
            sendImageRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            SendImageManager.shared.sendImage(request: sendImageRequest).subscribe(onCompleted: {
            })
        }
    }

    private func sendExtensionShareFile(_ file: ShareFileItem, chatId: String) {
        self.sendMessageAPI.sendFile(context: nil,
                                     path: file.url.path,
                                     name: file.name,
                                     parentMessage: nil,
                                     removeOriginalFileAfterFinish: true,
                                     chatId: chatId,
                                     threadId: nil,
                                     createScene: .commonShare,
                                     sendMessageTracker: nil,
                                     stateHandler: nil)
    }

    private func sendExtensionShareMutiple(_ file: ShareMultipleItem, chatId: String) {
        if let imageItem = file.imageItem as? ShareImageItem,
           let urls = imageItem.images as? [URL],
           !urls.isEmpty {
            self.shareImages(urls, chatId: chatId)
        }

        for fileItem: ShareFileItem in file.fileItems {
            self.sendMessageAPI.sendFile(context: nil,
                                         path: fileItem.url.path,
                                         name: fileItem.name,
                                         parentMessage: nil,
                                         removeOriginalFileAfterFinish: true,
                                         chatId: chatId,
                                         threadId: nil,
                                         createScene: .commonShare,
                                         sendMessageTracker: nil,
                                         stateHandler: nil)
        }
    }
    // enable-lint: duplicated_code
}

/// ForwardComponent
extension ForwardServiceImpl {
    public func forwardMessageInComponent(selectItems: [ForwardItem],
                                          forwardContent: ForwardAlertContent,
                                          forwardParam: ForwardContentParam,
                                          additionNote: NSAttributedString?) -> Observable<ForwardComponentResponse> {
        let additionNote = additionNote ?? NSAttributedString(string: "")
        let ids = self.itemsToTargetIds(selectItems)
        // 参照历史逻辑，chatIds数组包含群聊目标和话题目标的chatID
        return self.checkAndCreateChats(chatIds: ids.groupTargetIds, userIds: ids.userTargetIds).flatMap { [weak self] chatTargetModels -> Observable<ForwardComponentResponse> in
            guard let self = self else { return .just(([], nil)) }
            let forwardResultItems = chatTargetModels.map {
                var type = ""
                switch $0.type {
                case .p2P: type = "p2P"
                case .group: type = "group"
                case .topicGroup: type = "topicGroup"
                default: break
                }
                return ForwardResultItem(isSuccess: true,
                                         type: type,
                                         name: $0.name,
                                         chatID: $0.id,
                                         isCrossTenant: $0.isCrossTenant)
            } + ids.threadTargets.map {
                return ForwardResultItem(isSuccess: true,
                                         type: "thread",
                                         name: nil,
                                         chatID: $0.key,
                                         threadID: $0.value,
                                         isCrossTenant: nil)
            }
            let tracker = self.getTracker(contentParm: forwardParam)
            let startTime = CACurrentMediaTime()
            return self.createSendOb(chatTargetIds: chatTargetModels.map { $0.id },
                                     threadTargetIds: ids.threadTargets.map { (messageID: $0.value, chatID: $0.key) },
                                     threadModeChatIds: chatTargetModels.filter { $0.displayInThreadMode }.map { $0.id },
                                     replyInThread: Dictionary(uniqueKeysWithValues: selectItems.map { ($0.id, $0.type == ForwardItemType.replyThreadMessage) }),
                                     tracker: tracker,
                                     additionNote: additionNote,
                                     forwardContent: forwardContent,
                                     forwardContentParam: forwardParam,
                                     forwardResultItems: forwardResultItems).do(onNext: { _ in
                if let tracker = tracker {
                    tracker.end(sdkCost: CACurrentMediaTime() - startTime)
                }
                if let content = forwardContent as? MessageForwardAlertContent {
                    Tracer.trackForwardNum(chatTargetModels,
                                           isPostscript: additionNote.length == 0,
                                           from: content.from,
                                           message: content.message)
                }
                if let content = forwardContent as? ShareChatAlertContent {
                    self.trackChatShareSend(content: content,
                                            chatCount: chatTargetModels.count,
                                            additionNote: additionNote)

                }
            })
        }
    }

    private func createSendOb(chatTargetIds: [String],
                              threadTargetIds: [(messageID: String, chatID: String)],
                              threadModeChatIds: [String]?,
                              replyInThread: [String: Bool],
                              tracker: ShareAppreciableTracker?,
                              additionNote: NSAttributedString,
                              forwardContent: ForwardAlertContent,
                              forwardContentParam: ForwardContentParam,
                              forwardResultItems: [ForwardResultItem?]) -> Observable<ForwardComponentResponse> {
        let chatTargetsTuple: [ForwardTarget] = chatTargetIds.map { ($0, nil, false) }
        let threadTargetsTuple: [ForwardTarget] = threadTargetIds.map { ($0.chatID, $0.messageID, replyInThread[$0.messageID] ?? false) }
        let targetsTuple = chatTargetsTuple + threadTargetsTuple
        var ob = Observable<ForwardComponentResponse>.empty()
        switch forwardContentParam {
        case .transmitSingleMessage(let param):
            ob = self.forwardSingleMessage(chatTargetIds: chatTargetIds,
                                           threadTargetIds: threadTargetIds,
                                           threadModeChatIds: threadModeChatIds,
                                           messageForwardParam: param,
                                           additionNote: additionNote,
                                           forwardResultItems: forwardResultItems)
        case .transmitMergeMessage(param: let param):
            ob = self.forwardMergeMessage(chatTargetIds: chatTargetIds,
                                          threadTargetIds: threadTargetIds,
                                          threadModeChatIds: threadModeChatIds,
                                          mergeParam: param,
                                          additionNote: additionNote,
                                          forwardResultItems: forwardResultItems)
        case .transmitBatchMessage(param: let param):
            ob = self.forwardBatchMessage(chatTargetIds,
                                          param, additionNote,
                                          forwardResultItems)
        case .sendUserCardMessage(let param):
            ob = self.shareUserCardMessage(shareChatterID: param.shareChatterId,
                                           threadModeChatIds: threadModeChatIds,
                                           targetsTuple: targetsTuple,
                                           additionNote: additionNote,
                                           forwardResultItems: forwardResultItems,
                                           tracker: tracker)
        case .sendImageMessage(let param):
            ob = self.shareImage(sourceImage: param.sourceImage,
                                 threadModeChatIds: threadModeChatIds,
                                 targetsTuple: targetsTuple,
                                 additionNote: additionNote,
                                 forwardResultItems: forwardResultItems,
                                 tracker: tracker)
        case .sendMultipleImageMessage(let param):
            ob = self.shareMultipleImage(imageUrls: param.imagePaths,
                                         threadModeChatIds: threadModeChatIds,
                                         targetsTuple: targetsTuple,
                                         additionNote: additionNote,
                                         forwardResultItems: forwardResultItems,
                                         tracker: tracker)
        case .sendGroupCardMessage(let param):
            ob = shareGroupCard(shareChatID: param.shareChatId,
                                threadModeChatIds: threadModeChatIds,
                                targetsTuple: targetsTuple,
                                additionNote: additionNote,
                                forwardResultItems: forwardResultItems,
                                tracker: tracker)
        case .sendTextMessage(let param):
            ob = shareText(text: param.textContent,
                           threadModeChatIds: threadModeChatIds,
                           targetsTuple: targetsTuple,
                           additionNote: additionNote,
                           forwardResultItems: forwardResultItems,
                           tracker: tracker)
        case .sendFileMessage(let param):
            ob = shareFile(filePath: param.filePath,
                           fileName: param.fileName,
                           threadModeChatIds: threadModeChatIds,
                           targetsTuple: targetsTuple,
                           additionNote: additionNote,
                           forwardResultItems: forwardResultItems,
                           tracker: tracker)
        default:
            break
        }
        return ob
    }

    public func itemsToTargetIds(_ items: [ForwardItem]) -> ForwardTargetIds {
        var groupTargetIds: [String] = []
        var userTargetIds: [String] = []
        var filterIds: [String] = []
        var threadTargets: [String: String] = [:]
        items.forEach { (item) in
            switch item.type {
            case .chat:
                groupTargetIds.append(item.id)
            case .user, .myAi:
                userTargetIds.append(item.id)
            case .bot:
                userTargetIds.append(item.id)
            case .generalFilter:
                filterIds.append(item.id)
            case .threadMessage, .replyThreadMessage:
                if let chatID = item.channelID {
                    threadTargets[chatID] = item.id
                }
            case .unknown:
                break
            @unknown default:
                break
            }
        }
        return (groupTargetIds: groupTargetIds, userTargetIds: userTargetIds, threadTargets: threadTargets, filterIds: filterIds)
    }

    /// items: 包含一组发送目标的属性，如目标类型、是否发送成功等
    /// targetTuple: 当前处理目标的chatID/threadID/是否转发到消息话题
    private func getCurrentForwardResultItem(items: [ForwardResultItem?],
                                             targetTuple: ForwardTarget) -> ForwardResultItem? {
        let chatID = targetTuple.chatID
        let threadID = targetTuple.threadID
        var isThreadTarget = false
        if let threadID = threadID, !threadID.isEmpty {
            isThreadTarget = true
        }
        var item: ForwardResultItem?
        if let currentItem = items.first(where: {
            return isThreadTarget ? ($0?.threadID == threadID) : ($0?.chatID == chatID)
        }) {
            item = currentItem
        }
        return item
    }

    private func setForwardResultItemIsSuccess(forwardResultItem: ForwardResultItem?, isSuccess: Bool) -> ForwardResultItem? {
        return forwardResultItem.map {
            var tempItem = $0
            tempItem.isSuccess = isSuccess
            return tempItem
        }
    }

    private func getStateHandler(observer: AnyObserver<ForwardComponentResponse>,
                                 threadModeChatIds: [String]?,
                                 additionNote: NSAttributedString,
                                 tracker: ShareAppreciableTracker?,
                                 forwardResultItem: ForwardResultItem?,
                                 errorMsg: String) -> ((SendMessageState) -> Void) {
        return { [weak self] state in
            switch state {
            case .finishSendMessage(_, _, let messageId, _, _):
                if let id = messageId {
                    self?.sendReplyMessage(attributeExtraText: additionNote,
                                           messageIDs: [id],
                                           threadModeChatIds: threadModeChatIds)
                }
                let item = self?.setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: true)
                observer.onNext(([item], nil))
                observer.onCompleted()
            case .errorSendMessage(cid: _, let error):
                if let tracker = tracker {
                    tracker.error(error)
                }
                Self.logger.error(errorMsg, error: error)
                observer.onError(error)
            default:
                break
            }
        }
    }

    private func getTracker(contentParm: ForwardContentParam) -> ShareAppreciableTracker? {
        var tracker: ShareAppreciableTracker?
        switch contentParm {
        case .transmitSingleMessage(_), .transmitMergeMessage(_), .transmitBatchMessage(_), .sendImageMessage(_), .sendTextMessage(_), .sendFileMessage(_):
            break
        case .sendUserCardMessage(_):
            tracker = ShareAppreciableTracker(pageName: "ForwardComponentViewController",
                                              fromType: .userCard)
        case .sendGroupCardMessage(_):
            tracker = ShareAppreciableTracker(pageName: "ForwardComponentViewController",
                                              fromType: .groupCard)
        default:
            break
        }
        return tracker
    }

    /// 单条消息转发
    private func forwardSingleMessage(chatTargetIds: [String],
                                      threadTargetIds: [(messageID: String, chatID: String)],
                                      threadModeChatIds: [String]?,
                                      messageForwardParam: MessageForwardParam,
                                      additionNote: NSAttributedString,
                                      forwardResultItems: [ForwardResultItem?]) -> Observable<ForwardComponentResponse> {
        return ForwardServiceImpl.forward(originMergeForwardId: messageForwardParam.originMergeForwardId,
                                          chatTargets: chatTargetIds,
                                          threadTargets: threadTargetIds,
                                          type: messageForwardParam.type,
                                          client: self.rustService,
                                          context: nil).do(onNext: { [weak self] response in
            guard let self = self else { return }
            let msgIds = Array(response.messageIds.values) + response.message2Threads.keys
            self.sendReplyMessage(attributeExtraText: additionNote,
                                  messageIDs: msgIds,
                                  threadModeChatIds: threadModeChatIds)

        }).map { response in
            // 返回chatID，权限拦截弹窗
            return (forwardResultItems, response.hasFilePermCheck ? response.filePermCheck : nil)
        }
    }

    /// 合并消息转发以及私有话题帖子转发
    private func forwardMergeMessage(chatTargetIds: [String],
                                     threadTargetIds: [(messageID: String, chatID: String)],
                                     threadModeChatIds: [String]?,
                                     mergeParam: MergeForwardParam,
                                     additionNote: NSAttributedString,
                                     forwardResultItems: [ForwardResultItem?]) -> Observable<ForwardComponentResponse> {
        return ForwardServiceImpl.mergeForward(originMergeForwardId: mergeParam.originMergeForwardId,
                                               needCopyReaction: true,
                                               messageIds: mergeParam.messageIds,
                                               to: chatTargetIds,
                                               to: threadTargetIds,
                                               quasiTitle: mergeParam.quasiTitle,
                                               needQuasiMessage: mergeParam.needQuasiMessage,
                                               mergeFowardMessageType: mergeParam.type,
                                               threadID: mergeParam.threadID,
                                               limited: mergeParam.limited,
                                               client: self.rustService,
                                               context: nil).do(onNext: { [weak self] response in
            guard let self = self else { return }
            let msgIds = Array(response.messageIds.values) + response.message2Threads.keys
            self.sendReplyMessage(attributeExtraText: additionNote,
                                  messageIDs: msgIds,
                                  threadModeChatIds: threadModeChatIds)
        }).map { response in
            // 返回chatID，权限拦截弹窗
            return (forwardResultItems, response.hasFilePermCheck ? response.filePermCheck : nil)
        }
    }

    /// 逐条消息转发
    private func forwardBatchMessage(_ chatTargetIds: [String],
                                     _ batchParam: BatchForwardParam,
                                     _ additionNote: NSAttributedString,
                                     _ forwardResultItems: [ForwardResultItem?]) -> Observable<ForwardComponentResponse> {
        return ForwardServiceImpl.batchTransmit(originMergeForwardId: batchParam.originMergeForwardId,
                                                messageIds: batchParam.messageIds,
                                                to: chatTargetIds,
                                                client: self.rustService,
                                                context: nil).do(onNext: { [weak self] _ in
            // 逐条转发只支持发无引用关系的普通附言，且目标不支持帖子
            guard let self = self else { return }
            if additionNote.length != 0,
               var additionContent = RichTextTransformKit.transformStringToRichText(string: additionNote) {
                additionContent.richTextVersion = 1
                chatTargetIds.forEach { (chatID) in
                    self.sendMessageAPI.sendText(
                        context: nil,
                        content: additionContent,
                        parentMessage: nil,
                        chatId: chatID,
                        threadId: nil,
                        stateHandler: nil)
                }
            }
        }).map { response in
            return (forwardResultItems.map { [weak self] in
                guard let self = self else { return nil }
                return self.setForwardResultItemIsSuccess(forwardResultItem: $0, isSuccess: true)
            }, response.hasFilePermCheck ? response.filePermCheck : nil)
        }
    }

    // nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
    // TODO: 在转发单测建设需求中完成逻辑优化
    private func shareUserCardMessage(shareChatterID: String,
                                      threadModeChatIds: [String]?,
                                      targetsTuple: [ForwardTarget],
                                      additionNote: NSAttributedString,
                                      forwardResultItems: [ForwardResultItem?],
                                      tracker: ShareAppreciableTracker?) -> Observable<ForwardComponentResponse> {
        let ob = Observable.combineLatest(targetsTuple.map { [weak self] (chatID, threadID, replyInThread) in
            guard let self = self else { return Observable<ForwardComponentResponse>.empty() }
            let targetTuple = (chatID: chatID, threadID: threadID, replyInThread: replyInThread)
            let forwardResultItem = self.getCurrentForwardResultItem(items: forwardResultItems, targetTuple: targetTuple)
            var sendChannelType = SendChannelType.chat(id: targetTuple.chatID)
            if let threadID = targetTuple.threadID, !threadID.isEmpty {
                sendChannelType = SendChannelType.thread(threadID: threadID, chatID: targetTuple.chatID)
            }
            let messageOb = Observable<ForwardComponentResponse>.create { [weak self] observer in
                guard let self = self else { return Disposables.create() }
                let context = APIContext(contextID: "")
                context.set(key: APIContext.replyInThreadKey, value: replyInThread)
                self.sendMessageAPI.sendShareUserCardMessage(context: context,
                                                             shareChatterId: shareChatterID,
                                                             sendChannelType: sendChannelType,
                                                             createScene: .commonShare,
                                                             sendMessageTracker: nil,
                                                             stateHandler: self.getStateHandler(observer: observer,
                                                                                                threadModeChatIds: threadModeChatIds,
                                                                                                additionNote: additionNote,
                                                                                                tracker: tracker,
                                                                                                forwardResultItem: forwardResultItem,
                                                                                                errorMsg: "share user card failed"))
                return Disposables.create()
            }.catchErrorJustReturn(([setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: false)], nil))
            return messageOb
        }).flatMap { res -> Observable<ForwardComponentResponse> in return Observable.from(res) }
        return ob
    }

    private func shareGroupCard(shareChatID: String,
                                threadModeChatIds: [String]?,
                                targetsTuple: [ForwardTarget],
                                additionNote: NSAttributedString,
                                forwardResultItems: [ForwardResultItem?],
                                tracker: ShareAppreciableTracker?) -> Observable<ForwardComponentResponse> {
        let ob = Observable.combineLatest(targetsTuple.map { [weak self] (chatID, threadID, replyInThread) in
            guard let self = self else { return Observable<ForwardComponentResponse>.empty() }
            let targetTuple = (chatID: chatID, threadID: threadID, replyInThread: replyInThread)
            let forwardResultItem = self.getCurrentForwardResultItem(items: forwardResultItems, targetTuple: targetTuple)
            let messageOb = Observable<ForwardComponentResponse>.create { [weak self] observer in
                guard let self = self else { return Disposables.create() }
                let context = APIContext(contextID: "")
                context.set(key: APIContext.replyInThreadKey, value: replyInThread)
                self.sendMessageAPI.sendGroupShare(context: context,
                                                   sharChatId: shareChatID,
                                                   chatId: targetTuple.chatID,
                                                   threadId: targetTuple.threadID,
                                                   createScene: .shareGroupChat,
                                                   stateHandler: self.getStateHandler(observer: observer,
                                                                                      threadModeChatIds: threadModeChatIds,
                                                                                      additionNote: additionNote,
                                                                                      tracker: tracker,
                                                                                      forwardResultItem: forwardResultItem,
                                                                                      errorMsg: "share group card failed"))
                return Disposables.create()
            }.catchErrorJustReturn(([setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: false)], nil))
            return messageOb
        }).flatMap { res -> Observable<ForwardComponentResponse> in return Observable.from(res) }
        return ob
    }

    private func shareText(text: String,
                           threadModeChatIds: [String]?,
                           targetsTuple: [ForwardTarget],
                           additionNote: NSAttributedString,
                           forwardResultItems: [ForwardResultItem?],
                           tracker: ShareAppreciableTracker?) -> Observable<ForwardComponentResponse> {
        let ob = Observable.combineLatest(targetsTuple.map { [weak self] (chatID, threadID, replyInThread) in
            guard let self = self else { return Observable<ForwardComponentResponse>.empty() }
            let targetTuple = (chatID: chatID, threadID: threadID, replyInThread: replyInThread)
            let forwardResultItem = self.getCurrentForwardResultItem(items: forwardResultItems, targetTuple: targetTuple)
            let messageOb = Observable<ForwardComponentResponse>.create { [weak self] observer in
                guard let self = self else { return Disposables.create() }
                let context = APIContext(contextID: "")
                context.set(key: APIContext.replyInThreadKey, value: replyInThread)
                self.sendMessageAPI.sendText(context: context,
                                             content: RustPB.Basic_V1_RichText.text(text),
                                             parentMessage: nil,
                                             chatId: targetTuple.chatID,
                                             threadId: targetTuple.threadID,
                                             createScene: .commonShare,
                                             sendMessageTracker: nil,
                                             stateHandler: self.getStateHandler(observer: observer,
                                                                                threadModeChatIds: threadModeChatIds,
                                                                                additionNote: additionNote,
                                                                                tracker: tracker,
                                                                                forwardResultItem: forwardResultItem,
                                                                                errorMsg: "share text failed"))
                return Disposables.create()
            }.catchErrorJustReturn(([setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: false)], nil))
            return messageOb
        }).flatMap { res -> Observable<ForwardComponentResponse> in return Observable.from(res) }
        return ob
    }

    private func shareFile(filePath: String,
                           fileName: String,
                           threadModeChatIds: [String]?,
                           targetsTuple: [ForwardTarget],
                           additionNote: NSAttributedString,
                           forwardResultItems: [ForwardResultItem?],
                           tracker: ShareAppreciableTracker?) -> Observable<ForwardComponentResponse> {
        let ob = Observable.combineLatest(targetsTuple.map { [weak self] (chatID, threadID, replyInThread) in
            guard let self = self else { return Observable<ForwardComponentResponse>.empty() }
            let targetTuple = (chatID: chatID, threadID: threadID, replyInThread: replyInThread)
            let forwardResultItem = self.getCurrentForwardResultItem(items: forwardResultItems, targetTuple: targetTuple)
            let messageOb = Observable<ForwardComponentResponse>.create { [weak self] observer in
                guard let self = self else { return Disposables.create() }
                let context = APIContext(contextID: "")
                context.set(key: APIContext.replyInThreadKey, value: replyInThread)
                self.sendMessageAPI.sendFile(context: context,
                                             path: filePath,
                                             name: fileName,
                                             parentMessage: nil,
                                             removeOriginalFileAfterFinish: false,
                                             chatId: targetTuple.chatID,
                                             threadId: targetTuple.threadID,
                                             createScene: .commonShare,
                                             sendMessageTracker: nil,
                                             stateHandler: self.getStateHandler(observer: observer,
                                                                                threadModeChatIds: threadModeChatIds,
                                                                                additionNote: additionNote,
                                                                                tracker: tracker,
                                                                                forwardResultItem: forwardResultItem,
                                                                                errorMsg: "share text failed"))
                return Disposables.create()
            }.catchErrorJustReturn(([setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: false)], nil))
            return messageOb
        }).flatMap { res -> Observable<ForwardComponentResponse> in return Observable.from(res) }
        return ob
    }

    private func shareImage(sourceImage: UIImage,
                            threadModeChatIds: [String]?,
                            targetsTuple: [ForwardTarget],
                            additionNote: NSAttributedString,
                            forwardResultItems: [ForwardResultItem?],
                            tracker: ShareAppreciableTracker?) -> Observable<ForwardComponentResponse> {
        let ob = Observable.combineLatest(targetsTuple.map { [weak self] (chatID, threadID, replyInThread) in
            guard let self = self else { return Observable<ForwardComponentResponse>.empty() }
            let targetTuple = (chatID: chatID, threadID: threadID, replyInThread: replyInThread)
            let forwardResultItem = self.getCurrentForwardResultItem(items: forwardResultItems, targetTuple: targetTuple)
            let forwardSendImage = SendImageUploadByForwardComponent(sendMessageAPI: self.sendMessageAPI,
                                                                     forwardTarget: targetTuple)
            // 生成imageRequest
            let sendImageRequest = SendImageRequest(
                input: .image(sourceImage),
                sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true,
                                                                                   scene: .Forward,
                                                                                   fromType: .image)),
                uploader: forwardSendImage)
            sendImageRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            return SendImageManager.shared
                .sendImage(request: sendImageRequest)
                .do(onNext: { [weak self] messageId in
                    ForwardServiceImpl.logger.info("share image onNext: \(String(describing: messageId))")
                    if let id = messageId {
                        self?.sendReplyMessage(attributeExtraText: additionNote, messageIDs: [id])
                    }
                }).map { [weak self] _ in
                    let item = self?.setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: true)
                    return ([item], nil)
                }.catchErrorJustReturn(([self.setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: false)], nil))
        }).flatMap { res -> Observable<ForwardComponentResponse> in return Observable.from(res) }
        return ob
    }

    private func shareMultipleImage(imageUrls: [URL],
                                    threadModeChatIds: [String]?,
                                    targetsTuple: [ForwardTarget],
                                    additionNote: NSAttributedString,
                                    forwardResultItems: [ForwardResultItem?],
                                    tracker: ShareAppreciableTracker?) -> Observable<ForwardComponentResponse> {
        let ob = Observable.combineLatest(targetsTuple.map { [weak self] (chatID, threadID, replyInThread) in
            guard let self = self else { return Observable<ForwardComponentResponse>.empty() }
            let targetTuple = (chatID: chatID, threadID: threadID, replyInThread: replyInThread)
            let forwardResultItem = self.getCurrentForwardResultItem(items: forwardResultItems, targetTuple: targetTuple)
            let forwardSendImages = SendImageUploadByForwardComponent(sendMessageAPI: self.sendMessageAPI,
                                                                      forwardTarget: targetTuple,
                                                                      imageUrls: imageUrls)

            let sendImagesRequest = SendImageRequest(
                input: .datas(imageUrls.compactMap { try? Data.read(from: $0.asAbsPath()) }),
                sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true,
                                                                                   scene: .Forward,
                                                                                   fromType: .image)),
                uploader: forwardSendImages)
            sendImagesRequest.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            return SendImageManager.shared
                .sendImage(request: sendImagesRequest)
                .do(onNext: { [weak self] messageId in
                    ForwardServiceImpl.logger.info("share image onNext: \(String(describing: messageId))")
                    if let id = messageId {
                        self?.sendReplyMessage(attributeExtraText: additionNote, messageIDs: [id])
                    }
                }).map { [weak self] _ in
                    let item = self?.setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: true)
                    return ([item], nil)
                }.catchErrorJustReturn(([self.setForwardResultItemIsSuccess(forwardResultItem: forwardResultItem, isSuccess: false)], nil))
        }).flatMap { res -> Observable<ForwardComponentResponse> in return Observable.from(res) }
        return ob
    }
    // enable-lint: duplicated_code

    private func trackChatShareSend(content: ShareChatAlertContent, chatCount: Int, additionNote: NSAttributedString) {
        Tracer.trackChatConfigShareConfirmed(isExternal: content.fromChat.isCrossTenant,
                                             isPublic: content.fromChat.isPublic)
        Tracer.trackImChatSettingChatForwardClick(chatId: content.fromChat.id,
                                                  isAdmin: passportUserService.user.userID == content.fromChat.ownerId,
                                                  chatCount: chatCount,
                                                  msgCount: additionNote.string.count,
                                                  isMsg: additionNote.length != 0)
    }
}

public typealias ForwardTarget = (chatID: String, threadID: String?, replyInThread: Bool)

final class SendImageUploadByForwardComponent: LarkSendImageUploader {
    typealias AbstractType = String?
    private let sendMessageAPI: SendMessageAPI
    private let forwardTarget: ForwardTarget
    private let imageUrls: [URL]
    private var sendImagesTrackInfoList: [(String, TrackImageInfo)] = []
    private var sendImagesIndex: Int = 0
    init(sendMessageAPI: SendMessageAPI,
         forwardTarget: ForwardTarget,
         imageUrls: [URL] = []) {
        self.sendMessageAPI = sendMessageAPI
        self.forwardTarget = forwardTarget
        self.imageUrls = imageUrls
    }

    private func getSourceImageTrackInfo(sourceImage: UIImage, imageInfo: ImageMessageInfo) -> TrackImageInfo {
        var trackInfo = TrackImageInfo()
        trackInfo.colorSpaceName = sourceImage.bt.colorSpaceName
        trackInfo.contentLength = sourceImage.bt.dataCount
        trackInfo.fallToFile = false
        trackInfo.imageType = imageInfo.imageType
        trackInfo.isOrigin = true
        trackInfo.resourceHeight = sourceImage.size.height
        trackInfo.resourceWidth = sourceImage.size.width
        trackInfo.uploadWidth = imageInfo.sendImageSource.originImage.image?.size.width ?? 0
        trackInfo.uploadHeight = imageInfo.sendImageSource.originImage.image?.size.height ?? 0
        trackInfo.uploadLength = imageInfo.sendImageSource.originImage.data?.count ?? 0
        return trackInfo
    }

    private func getImageMessageInfoFrom(sourceImage: UIImage,
                                         imageSourceResult: Result<ImageSourceResult, CompressError>,
                                         ob: AnyObserver<AbstractType>) -> ImageMessageInfo? {
        return ImageMessageInfo(originalImageSize: sourceImage.size,
                                sendImageSource: SendImageSource(cover: nil,
                                                                 origin: { () -> ImageSourceResult in
            if sourceImage.bt.isAnimatedImage,
               let gifData = sourceImage.bt.originData {
                return ImageSourceResult(sourceType: .gif,
                                         data: gifData,
                                         image: sourceImage)
            }
            switch imageSourceResult {
            case .success(let imageSourceResult):
                return imageSourceResult
            case .failure(let error):
                ob.onError(error)
                return ImageSourceResult(sourceType: .unknown,
                                         data: nil,
                                         image: nil)
            }
        }))
    }

    private func getImageMessageInfosFrom(imageUrls: [URL]) -> [ImageMessageInfo] {
        self.sendImagesIndex = 0
        self.sendImagesTrackInfoList.removeAll()
        return imageUrls.compactMap { [weak self] (url) -> ImageMessageInfo? in
            guard let self = self else { return nil }
            if let data = try? Data.read(from: url.asAbsPath()),
               // 修正图片方向，避免显示错误
               let image = try? ByteImage(data) {
                let imageInfo = ImageMessageInfo(
                    originalImageSize: image.size,
                    sendImageSource: SendImageSource(cover: nil, origin: { () -> ImageSourceResult in
                        // gif图不进行转格式，image需要修正方向，逻辑摘自PHAsset.imageInfo
                        if let gifData = image.animatedImageData {
                            return ImageSourceResult(sourceType: .gif, data: gifData, image: image, colorSpaceName: image.bt.colorSpaceName)
                        } else {
                            // 只转一下格式即可，质量等保持不变
                            return ImageSourceResult(sourceType: .jpeg,
                                                     data: data,
                                                     image: image,
                                                     colorSpaceName: image.bt.colorSpaceName)
                        }
                    })
                )
                let trackInfo = self.getSourceImageTrackInfo(sourceImage: image, imageInfo: imageInfo)
                let key = url.absoluteString + "\(self.sendImagesIndex)"
                self.sendImagesTrackInfoList.append((key, trackInfo))
                sendImagesIndex += 1
                ForwardTracker.startTrack(key, scene: .Share)
                return imageInfo
            }
            return nil
        }
    }

    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable.create { [weak self] observer in
            let input = request.getInput()
            guard let self = self else {
                observer.onError(CompressError.requestRelease)
                return Disposables.create()
            }
            if case .datas(_) = input {
                let imageMessageInfoArray = self.getImageMessageInfosFrom(imageUrls: self.imageUrls)
                self.sendMessageAPI.sendImages(contexts: nil,
                                               parentMessage: nil,
                                               useOriginal: true,
                                               imageMessageInfos: imageMessageInfoArray,
                                               chatId: self.forwardTarget.chatID,
                                               threadId: self.forwardTarget.threadID,
                                               createScene: .commonShare,
                                               sendMessageTracker: nil) { index, state in
                    if index < self.sendImagesTrackInfoList.count {
                        let (key, trackInfo) = self.sendImagesTrackInfoList[index]
                        switch state {
                        case .finishSendMessage(_, _, _, _, _):
                            observer.onNext(nil)
                            ForwardTracker.end(key, info: trackInfo)
                        case .errorSendMessage(_, let error):
                            ForwardTracker.failed(key, error: error)
                            observer.onError(error)
                        default:
                            break
                        }
                    }
                    observer.onCompleted()
                }
            }
            if case let .image(sourceImage) = input,
               let imageSourceResult = request.getCompressResult()?.first?.result,
               let imageMessageInfo = self.getImageMessageInfoFrom(sourceImage: sourceImage,
                                                                   imageSourceResult: imageSourceResult,
                                                                   ob: observer) {
                ForwardTracker.startTrack(self.forwardTarget.chatID, scene: .Share)
                self.sendMessageAPI.sendImage(
                    context: nil,
                    parentMessage: nil,
                    useOriginal: true,
                    imageMessageInfo: imageMessageInfo,
                    chatId: self.forwardTarget.chatID,
                    threadId: self.forwardTarget.threadID,
                    createScene: .commonShare,
                    sendMessageTracker: nil) { state in
                    switch state {
                    case .finishSendMessage(_, _, let messageId, _, _):
                        observer.onNext(messageId)
                        ForwardTracker.end(self.forwardTarget.chatID,
                                            info: self.getSourceImageTrackInfo(sourceImage: sourceImage,
                                                                                imageInfo: imageMessageInfo))
                        observer.onCompleted()
                    case .errorSendMessage(_, let error):
                        ForwardTracker.failed(self.forwardTarget.chatID, error: error)
                        observer.onError(error)
                    default:
                        break
                    }
                }
            }
            return Disposables.create()
        }
    }
}

/// 只用于转发
final class SendImageUploadByExtension: LarkSendImageUploader {
    typealias AbstractType = String?
    private let urls: [URL]
    private let chatId: String
    private let sendMessageAPI: SendMessageAPI
    init(urls: [URL], chatId: String, sendMessageAPI: SendMessageAPI) {
        self.urls = urls
        self.chatId = chatId
        self.sendMessageAPI = sendMessageAPI
    }
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable.create { [weak self] observer in
            guard let `self` = self
            else {
                observer.onError(CompressError.requestRelease)
                return Disposables.create()
            }
            var trackInfoList: [(String, TrackImageInfo)] = []
            var index = 0
            let imageMessageInfos = self.urls.compactMap { (url) -> ImageMessageInfo? in
                let start = CACurrentMediaTime()
                if let data = try? Data.read(from: url.asAbsPath()),
                   // 修正图片方向，避免显示错误
                   let image = try? ByteImage(data) {
                    let imageInfo = ImageMessageInfo(
                        originalImageSize: image.size,
                        sendImageSource: SendImageSource(cover: nil, origin: { () -> ImageSourceResult in
                            // gif图不进行转格式，image需要修正方向，逻辑摘自PHAsset.imageInfo
                            if let gifData = image.animatedImageData {
                                return ImageSourceResult(sourceType: .gif, data: gifData, image: image, colorSpaceName: image.bt.colorSpaceName)
                            } else {
                                // 只转一下格式即可，质量等保持不变
                                return ImageSourceResult(sourceType: .jpeg,
                                                            data: data,
                                                            image: image,
                                                            colorSpaceName: image.bt.colorSpaceName)
                            }
                        })
                    )
                    var trackInfo = TrackImageInfo()
                    trackInfo.colorSpaceName = imageInfo.sendImageSource.originImage.colorSpaceName
                    trackInfo.contentLength = image.bt.dataCount
                    trackInfo.fallToFile = false
                    trackInfo.imageType = imageInfo.imageType
                    trackInfo.isOrigin = true
                    trackInfo.resourceHeight = image.size.height
                    trackInfo.resourceWidth = image.size.width
                    trackInfo.uploadWidth = imageInfo.sendImageSource.originImage.image?.size.width ?? 0
                    trackInfo.uploadHeight = imageInfo.sendImageSource.originImage.image?.size.height ?? 0
                    trackInfo.uploadLength = imageInfo.sendImageSource.originImage.data?.count ?? 0
                    let key = url.absoluteString + "\(index)"
                    trackInfoList.append((key, trackInfo))
                    index += 1
                    ForwardTracker.startTrack(url.absoluteString, scene: .Share)
                    return imageInfo
                }
                return nil
            }
            self.sendMessageAPI.sendImages(contexts: nil,
                                           parentMessage: nil,
                                           useOriginal: true,
                                           imageMessageInfos: imageMessageInfos,
                                           chatId: self.chatId,
                                           threadId: nil,
                                           createScene: .commonShare,
                                           sendMessageTracker: nil) { index, state in
                if index < trackInfoList.count {
                    let (key, trackInfo) = trackInfoList[index]
                    switch state {
                    case .finishSendMessage(_, _, _, _, _):
                        observer.onNext(nil)
                        ForwardTracker.end(key, info: trackInfo)
                    case .errorSendMessage(cid: _, let error):
                        ForwardTracker.failed(key, error: error)
                        observer.onError(error)
                    default:
                        break
                    }
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

final class SendImageUploadByForward: LarkSendImageUploader {
    typealias AbstractType = String?
    private let sendMessageAPI: SendMessageAPI
    private let chatModel: Chat
    init(sendMessageAPI: SendMessageAPI, chatModel: Chat) {
        self.sendMessageAPI = sendMessageAPI
        self.chatModel = chatModel
    }
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable.create { [weak self] observer in
            let input = request.getInput()
            guard let `self` = self,
                  let imageSourceResult = request.getCompressResult()?.first?.result,
                  case .image(let sourceImage) = input
            else {
                observer.onError(CompressError.requestRelease)
                return Disposables.create()
            }
            let imageInfo = ImageMessageInfo(
                originalImageSize: sourceImage.size,
                sendImageSource: SendImageSource(
                    cover: nil,
                    origin: { () -> ImageSourceResult in
                        if sourceImage.bt.isAnimatedImage, let gifData = sourceImage.bt.originData {
                            return ImageSourceResult(sourceType: .gif, data: gifData, image: sourceImage.lu.fixOrientation())
                        }
                        switch imageSourceResult {
                        case .success(let imageSourceResult):
                            return imageSourceResult
                        case .failure(let error):
                            observer.onError(error)
                            return ImageSourceResult(sourceType: .unknown, data: nil, image: nil)
                        }
                    }))
            var trackInfo = TrackImageInfo()
            trackInfo.colorSpaceName = sourceImage.bt.colorSpaceName
            trackInfo.contentLength = sourceImage.bt.dataCount
            trackInfo.fallToFile = false
            trackInfo.imageType = imageInfo.imageType
            trackInfo.isOrigin = true
            trackInfo.resourceHeight = sourceImage.size.height
            trackInfo.resourceWidth = sourceImage.size.width
            trackInfo.uploadWidth = imageInfo.sendImageSource.originImage.image?.size.width ?? 0
            trackInfo.uploadHeight = imageInfo.sendImageSource.originImage.image?.size.height ?? 0
            trackInfo.uploadLength = imageInfo.sendImageSource.originImage.data?.count ?? 0
            ForwardTracker.startTrack(self.chatModel.id, scene: .Share)
            self.sendMessageAPI.sendImage(
                context: nil,
                parentMessage: nil,
                useOriginal: true,
                imageMessageInfo: imageInfo,
                chatId: self.chatModel.id,
                threadId: nil,
                createScene: .commonShare,
                sendMessageTracker: nil) { state in
                switch state {
                case .finishSendMessage(_, _, let messageId, _, _):
                    observer.onNext(messageId)
                    ForwardTracker.end(self.chatModel.id, info: trackInfo)
                    observer.onCompleted()
                case .errorSendMessage(_, let error):
                    ForwardTracker.failed(self.chatModel.id, error: error)
                    observer.onError(error)
                default: break
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - 向SDK发请求
typealias TransmitRequest = RustPB.Im_V1_TransmitRequest
typealias MergeForwardMessagesRequest = RustPB.Im_V1_MergeForwardMessagesRequest
typealias BatchTransmitRequest = RustPB.Im_V1_BatchTransmitRequest
fileprivate extension ForwardServiceImpl {
    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    func forward(
        originMergeForwardId: String?,
        context: APIContext?,
        type: TransmitType,
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)]
    ) -> Observable<RustPB.Im_V1_TransmitResponse> {
        return ForwardServiceImpl.forward(
            originMergeForwardId: originMergeForwardId,
            chatTargets: chatIds,
            threadTargets: threadIDAndChatIDs,
            type: type,
            client: self.rustService,
            context: context
        ).subscribeOn(scheduler)
    }

    func mergeForward(
        context: APIContext?,
        originMergeForwardId: String?,
        messageIds: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        title: String,
        needQuasiMessage: Bool
    ) -> Observable<RustPB.Im_V1_MergeForwardMessagesResponse> {
        return ForwardServiceImpl.mergeForward(
            originMergeForwardId: originMergeForwardId,
            needCopyReaction: false,
            messageIds: messageIds,
            to: chatIds,
            to: threadIDAndChatIDs,
            quasiTitle: title,
            needQuasiMessage: needQuasiMessage,
            client: self.rustService,
            context: context
        ).subscribeOn(scheduler)
    }

    func batchTransmit(
        context: APIContext?,
        originMergeForwardId: String?,
        messageIds: [String],
        to chatIds: [String]
    ) -> Observable<RustPB.Im_V1_BatchTransmitResponse> {
        return ForwardServiceImpl.batchTransmit(
            originMergeForwardId: originMergeForwardId,
            messageIds: messageIds,
            to: chatIds,
            client: self.rustService,
            context: context
        ).subscribeOn(scheduler)
    }

    func forwardCopyFromFolderMessage(context: APIContext?,
                                      folderMessageId: String,
                                      key: String,
                                      sendChannelTypes: [SendChannelType]) -> Observable<RustPB.Im_V1_ShareAsMessageResponse> {
        return ForwardServiceImpl.forwardCopyFromFolderMessage(
            context: context,
            client: self.rustService,
            folderMessageId: folderMessageId,
            key: key,
            sendChannelTypes: sendChannelTypes
        ).subscribeOn(scheduler)
    }

    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    func threadMergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        title: String,
        limited: Bool
    ) -> Observable<RustPB.Im_V1_MergeForwardMessagesResponse> {
        return ForwardServiceImpl.threadMergeForward(
            originMergeForwardId: originMergeForwardId,
            needCopyReaction: needCopyReaction,
            messageIds: [threadID],
            to: chatIds,
            to: threadIDAndChatIDs,
            quasiTitle: title,
            needQuasiMessage: true,
            mergeFowardMessageType: .mergeThread,
            threadID: threadID,
            limited: limited,
            client: self.rustService,
            context: nil
        ).subscribeOn(scheduler)
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
fileprivate extension ForwardServiceImpl {
    class func forward(
        originMergeForwardId: String?,
        chatTargets chatIds: [String],
        threadTargets threadIDAndChatIDs: [(messageID: String, chatID: String)],
        type: TransmitType,
        client: SDKRustService,
        context: APIContext?
    ) -> Observable<RustPB.Im_V1_TransmitResponse> {
        var req = TransmitRequest()
        req.chatIds = chatIds
        req.id = type.id
        req.type = TransmitRequest.TypeEnum(rawValue: type.rawValue) ?? .unknown
        if let originMergeForwardId = originMergeForwardId {
            req.originMergeForwardID = originMergeForwardId
        }
        let threadTargets: [Im_V1_Transmit2ThreadTarget] = threadIDAndChatIDs.map {
            var threadTarget = Im_V1_Transmit2ThreadTarget()
            threadTarget.threadID = $0.messageID
            threadTarget.channelID = $0.chatID
            return threadTarget
        }
        req.threadTargets = threadTargets

        var pack = RequestPacket(message: req)
        pack.parentID = context?.contextID
        return client.async(pack).map { (response: RustPB.Im_V1_TransmitResponse) -> RustPB.Im_V1_TransmitResponse in
            return response
        }
    }

    class func mergeForward(
        originMergeForwardId: String?,
        needCopyReaction: Bool,
        messageIds: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        quasiTitle: String,
        needQuasiMessage: Bool,
        mergeFowardMessageType: RustPB.Basic_V1_MergeFowardMessageType? = nil,
        threadID: String? = nil,
        limited: Bool? = nil,
        client: SDKRustService,
        context: APIContext?) -> Observable<RustPB.Im_V1_MergeForwardMessagesResponse> {
            var req = MergeForwardMessagesRequest()
            req.chatIds = chatIds
            req.messageIds = messageIds
            req.quasiTitle = quasiTitle
            // PM 策略，当本地缺失部分消息实体从而导致上屏的假消息也就是会话记录内容不全时，选择不去创建假消息
            req.needQuasiMessage = needQuasiMessage
            let threadTargets: [Im_V1_Transmit2ThreadTarget] = threadIDAndChatIDs.map {
                var threadTarget = Im_V1_Transmit2ThreadTarget()
                threadTarget.threadID = $0.messageID
                threadTarget.channelID = $0.chatID
                return threadTarget
            }
            if let originMergeForwardId = originMergeForwardId {
                req.originMergeForwardID = originMergeForwardId
            }
            req.needCopyReaction = true
            req.threadTargets = threadTargets
            // default messageType
            if let type = mergeFowardMessageType {
                req.type = type
            }
            // merge thread need threadID
            if let threadID = threadID {
                req.threadID = threadID
            }
            // default false, close server limite verity
            if let limited = limited {
                req.limited = limited
            }
            var pack = RequestPacket(message: req)
            pack.parentID = context?.contextID
            return client.async(pack).map { (response: RustPB.Im_V1_MergeForwardMessagesResponse) -> RustPB.Im_V1_MergeForwardMessagesResponse in
                return response
            }
        }

    class func batchTransmit(
        originMergeForwardId: String?,
        messageIds: [String],
        to chatIds: [String],
        client: SDKRustService,
        context: APIContext?) -> Observable<RustPB.Im_V1_BatchTransmitResponse> {
            var req = BatchTransmitRequest()
            req.targets = chatIds.map({ (chatID)  in
                var a = Im_V1_TransmitTarget()
                a.chatID = chatID
                return a
            })
            if let originMergeForwardId = originMergeForwardId {
                req.originMergeForwardID = originMergeForwardId
            }
            req.messageIds = messageIds
            var pack = RequestPacket(message: req)
            pack.parentID = context?.contextID
            return client.async(pack).map { (response: Im_V1_BatchTransmitResponse) -> Im_V1_BatchTransmitResponse in
                return response
            }
        }

    class func forwardCopyFromFolderMessage(
        context: APIContext?,
        client: SDKRustService,
        folderMessageId: String,
        key: String,
        sendChannelTypes: [SendChannelType]) -> Observable<RustPB.Im_V1_ShareAsMessageResponse> {
            var request = RustPB.Im_V1_ShareAsMessageRequest()
            var shareObject = Im_V1_ShareObject()
            shareObject.fileManagerObject.fileKey = key
            shareObject.fileManagerObject.originMessageID = folderMessageId
            request.shareObject = [shareObject]

            var shareTargets: [Im_V1_ShareTarget] = []
            sendChannelTypes.forEach { (type) in
                switch type {
                case .chat(let id):
                    var target = Im_V1_ShareTarget()
                    var toChat = Im_V1_ShareTarget.Chat()
                    toChat.chatID = id
                    target.toChat = toChat
                    shareTargets.append(target)
                case .thread(let threadID, let chatID):
                    var target = Im_V1_ShareTarget()
                    var toThread = Im_V1_ShareTarget.Thread()
                    toThread.chatID = chatID
                    toThread.threadID = threadID
                    target.toThread = toThread
                    shareTargets.append(target)
                case .unknown:
                    assertionFailure()
                    return
                @unknown default:
                    assertionFailure()
                    return
                }
            }
            request.targets = shareTargets

            var pack = RequestPacket(message: request)
            pack.parentID = context?.contextID
            return client.async(pack).map { (response: RustPB.Im_V1_ShareAsMessageResponse) -> RustPB.Im_V1_ShareAsMessageResponse in
                return response
            }
        }

    class func threadMergeForward(
        originMergeForwardId: String?,
        needCopyReaction: Bool,
        messageIds: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        quasiTitle: String,
        needQuasiMessage: Bool,
        mergeFowardMessageType: RustPB.Basic_V1_MergeFowardMessageType? = nil,
        threadID: String? = nil,
        limited: Bool? = nil,
        client: SDKRustService,
        context: APIContext?) -> Observable<RustPB.Im_V1_MergeForwardMessagesResponse> {
            var req = MergeForwardMessagesRequest()
            req.chatIds = chatIds
            req.messageIds = messageIds
            req.quasiTitle = quasiTitle
            // PM 策略，当本地缺失部分消息实体从而导致上屏的假消息也就是会话记录内容不全时，选择不去创建假消息
            req.needQuasiMessage = needQuasiMessage
            let threadTargets: [Im_V1_Transmit2ThreadTarget] = threadIDAndChatIDs.map {
                var threadTarget = Im_V1_Transmit2ThreadTarget()
                threadTarget.threadID = $0.messageID
                threadTarget.channelID = $0.chatID
                return threadTarget
            }
            if let originMergeForwardId = originMergeForwardId {
                req.originMergeForwardID = originMergeForwardId
            }
            req.needCopyReaction = true
            req.threadTargets = threadTargets
            // default messageType
            if let type = mergeFowardMessageType {
                req.type = type
            }
            // merge thread need threadID
            if let threadID = threadID {
                req.threadID = threadID
            }
            // default false, close server limite verity
            if let limited = limited {
                req.limited = limited
            }
            var pack = RequestPacket(message: req)
            pack.parentID = context?.contextID
            return client.async(pack).map { (response: RustPB.Im_V1_MergeForwardMessagesResponse) -> RustPB.Im_V1_MergeForwardMessagesResponse in
                return response
            }
        }
}
