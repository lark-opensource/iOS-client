//
//  ReplyInThreadReadServiceManager.swift
//  LarkThread
//
//  Created by liluobin on 2023/2/3.
//

import Foundation
import UIKit
import LarkModel
import RustPB
import LarkContainer
import LarkFeatureGating
import LarkKAFeatureSwitch
import LKCommonsLogging
import LarkSDKInterface
import LarkMessageCore
import LarkCore
import RxSwift

class ReplyInThreadReadServiceManager: UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(ReplyInThreadReadServiceManager.self, category: "ReplyInThreadReadServiceManager")
    var readService: ChatMessageReadService?
    private let chatWrapper: ChatPushWrapper
    private let threadWrapper: ThreadPushWrapper
    private let threadMessage: ThreadMessage
    private var disposeBag = DisposeBag()

    private let fromWhere: String
    private var isMock: Bool? {
        didSet {
            if oldValue != isMock {
                try? createReadService()
            }
        }
    }
    init(resolver: UserResolver,
         chatWrapper: ChatPushWrapper,
         threadWrapper: ThreadPushWrapper,
         threadMessage: ThreadMessage,
         fromWhere: String) {
        self.userResolver = resolver
        self.chatWrapper = chatWrapper
        self.threadWrapper = threadWrapper
        self.threadMessage = threadMessage
        self.fromWhere = fromWhere
        /// init 方法中生设置属性不会触发didSet方法
        self.isMock = threadWrapper.thread.value.isMock
        try? createReadService()
        threadWrapper.thread
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (thread) in
                guard let self = self else {
                    return
                }
                self.isMock = thread.isMock
            }).disposed(by: self.disposeBag)
    }

    private func createReadService() throws {
        guard let isMock = self.isMock else {
            return
        }
        let chat = self.chatWrapper.chat.value
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        let isRemind = chat.isRemind
        let isInBox = chat.isInBox
        let rootMessage = self.threadMessage.rootMessage
        if isMock {
            let messageAPI = try resolver.resolve(assert: MessageAPI.self)
            let featureGating = try userResolver.fg
            let audioToTextEnable = featureGating.staticFeatureGatingValue(with: .init(key: .audioToTextEnable))
                                    && featureGating.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
            let chatPushWrapper = self.chatWrapper
            readService = try resolver.resolve(assert: ChatMessageReadService.self,
                arguments: PutReadScene.chat(chat),
                chat.isTeamVisitorMode,
                audioToTextEnable,
                isRemind,
                isInBox,
                ["chat": chat,
                 "chatFromWhere": self.fromWhere] as [String: Any], { () -> Int32 in
                    return chatPushWrapper.chat.value.readPosition
                }, { (info: PutReadInfo) in
                    let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                        return chatIDAndMessageID.messageID
                    }
                    Self.logger.info(
                        """
                        UnreadReplyInThreadDetail: chat put read
                        \(channel.id)
                        \(rootMessage.id)
                        \(rootMessage.threadMessageType)
                        \(messageIDs)
                        \(info.maxPosition)
                        \(info.maxBadgeCount)
                        """
                    )
                    messageAPI.putReadMessages(
                        channel: channel,
                        messageIds: messageIDs,
                        maxPosition: info.maxPosition,
                        maxPositionBadgeCount: info.maxBadgeCount)
                }
            )
        } else {
            let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
            let threadPushWrapper = self.threadWrapper
            readService = try resolver.resolve( // user:checked
                assert: ChatMessageReadService.self,
                arguments: PutReadScene.replyInThread(chat),
                false,
                false,
                isRemind,
                isInBox,
                ["chat": chat,
                 "chatFromWhere": self.fromWhere] as [String: Any], { () -> Int32 in
                    return threadPushWrapper.thread.value.readPosition
                }, { (info: PutReadInfo) in
                    let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                        return chatIDAndMessageID.messageID
                    }
                    Self.logger.info(
                        """
                        UnreadReplyInThreadDetail: thread put read
                        \(channel.id)
                        \(rootMessage.id)
                        \(rootMessage.threadMessageType)
                        \(messageIDs)
                        \(info.maxPosition)
                        \(info.maxBadgeCount)
                        """
                    )
                    let maxBadgeCount = max(0, info.maxBadgeCount)
                    threadAPI.updateThreadMessagesMeRead(
                        channel: channel,
                        threadId: threadPushWrapper.thread.value.id,
                        messageIds: messageIDs,
                        maxPositionInThread: info.maxPosition,
                        maxPositionBadgeCountInThread: maxBadgeCount
                    )
                })
        }
    }
}
