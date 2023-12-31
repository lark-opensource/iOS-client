//
//  DownUnReadMessagesTipViewModel.swift
//  Lark
//
//  Created by zc09v on 2018/1/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LarkCore
import LarkMessageCore
import LarkSDKInterface
import LKCommonsLogging
import RustPB

final class DownUnReadMessagesTipViewModel: BaseUnreadMessagesTipViewModel {
    private var lastReadPosition: Int32
    private var unreadAtMessages: [Message] = []
    private let messageAPI: MessageAPI
    private let chatId: String
    private let updateChatPublish: PublishSubject<Chat> = PublishSubject<Chat>()
    private let pushMessageObservable: Observable<Message>
    private let pushChatObservable: Observable<Chat>
    private var preloadMessagePosition: Int32?

    init(userResolver: UserResolver,
         chatId: String,
         readPosition: Int32,
         lastMessagePosition: Int32,
         messageAPI: MessageAPI,
         pushCenter: PushNotificationCenter) {
        self.messageAPI = messageAPI
        self.chatId = chatId
        let updateChatOb = updateChatPublish.asObservable()
        let pushChatOb: Observable<Chat> = pushCenter.observable(for: PushChat.self).filter { $0.chat.id == chatId }.map { $0.chat }
        self.pushChatObservable = Observable.merge([pushChatOb, updateChatOb])
        self.pushMessageObservable = pushCenter.observable(for: PushChannelMessage.self)
            .filter { $0.message.channel.id == chatId }
            .map({ (push) -> Message in
                return push.message
            })
        self.preloadMessagePosition = lastMessagePosition
        self.lastReadPosition = readPosition
        super.init(userResolver: userResolver)
        observeState()
        observePush()
    }

    override func fetchDataWhenLoad() {
        self.fetchUnreadAtMessages()
    }

    private func preloadMessages(position: Int32) -> Observable<Void> {
        return self.messageAPI
            .fetchChatMessages(
                chatId: self.chatId,
                scene: .specifiedPosition(position),
                redundancyCount: ChatMessagesViewModel.redundancyCount,
                count: ChatMessagesViewModel.requestCount,
                expectDisplayWeights: nil,
                redundancyDisplayWeights: nil,
                needResponse: false).map({ (_) -> Void in return })
    }

    private func observeState() {
        self.state
            .distinctUntilChanged { (state1, state2) -> Bool in
                return state1 == state2
            }
            .observeOn(self.dataScheduler)
            .flatMap { [weak self] (state) -> Observable<Void> in
                guard let self = self else { return .empty() }
                switch state {
                case .showUnReadAt(let message, _):
                    return self.preloadMessages(position: message.position)
                case .showUnReadMessages, .showToLastMessage:
                    if let preloadMessagePosition = self.preloadMessagePosition {
                        self.preloadMessagePosition = nil
                        return self.preloadMessages(position: preloadMessagePosition)
                    }
                    return.empty()
                case .dismiss:
                    return .empty()
                }
            }.subscribe().disposed(by: self.disposeBag)
    }

    //远端获取未读at消息
    //仅用处理fetchUnreadAtMessages晚于badgeDriver首次回调的情况；因为如果badgeDriver先执行，fetchUnreadAtMessages还没回调，本地数据可能不准确，导致badgeDriver的执行不准确
    //早于的话本地底层数据会被更新，之后dataProvider.badgeDriver中的回调可以正确处理
    private func fetchUnreadAtMessages() {
        messageAPI.fetchUnreadAtMessages(chatIds: [self.chatId], ignoreBadged: false, needResponse: true).map({ [weak self] (chatMessagesMap) -> [Message] in
                return chatMessagesMap[self?.chatId ?? ""] ?? []
            })
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                //接口返回前，可能通过pushmsg加入了unreadAt,要merge
                let unreadAtMessages = self.unreadAtMessages.lf_mergeUnique(array: result,
                                                                            comparable: { (msg1, msg2) -> Int in
                                                                                return Int(msg1.position - msg2.position)
                                                                            },
                                                                            equitable: { (msg1, msg2) -> Message? in
                                                                                return (msg1.id == msg2.id) ? msg1 : nil
                                                                            },
                                                                            sequence: .ascending)
                BaseUnreadMessagesTipViewModel.logger.info(logId: "",
                                                           "chatTrace fetchUnreadAtMessages count",
                                                           params: ["count": "\(result.count)",
                                                                    "min": "\(unreadAtMessages.first?.position ?? -1)",
                                                                    "max": "\(unreadAtMessages.last?.position ?? -1)",
                                                                    "readPosition": "\(self.lastReadPosition)"])
                self.unreadAtMessages = unreadAtMessages
                switch self.state.value {
                case .dismiss:
                    break
                case .showToLastMessage:
                    if let unreadAtMessage = unreadAtMessages.first(where: { (unreadAtMsg) -> Bool in
                        return unreadAtMsg.position > self.lastReadPosition
                    }) {
                        self.state.accept(.showUnReadAt(unreadAtMessage, self.lastReadPosition))
                    }
                case .showUnReadAt(let currentUnReadAtMsg, let readPosition):
                    if let unreadAtMessage = unreadAtMessages.first(where: { (unreadAtMsg) -> Bool in
                        return unreadAtMsg.position > readPosition && unreadAtMsg.position < currentUnReadAtMsg.position
                    }) {
                        self.state.accept(.showUnReadAt(unreadAtMessage, readPosition))
                    }
                case .showUnReadMessages(_, let readPosition):
                    if let unreadAtMessage = unreadAtMessages.first(where: { (unreadAtMsg) -> Bool in
                        return unreadAtMsg.position > readPosition
                    }) {
                        self.state.accept(.showUnReadAt(unreadAtMessage, readPosition))
                    }
                }
        }).disposed(by: disposeBag)
    }

    private func observePush() {
        pushChatObservable
            .delay(
                .milliseconds(Int(CommonTable.scrollToBottomAnimationDuration * 1000)),
                scheduler: self.dataScheduler)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (chat) in
                let badge = chat.badge
                let readPosition = chat.readPosition
                if readPosition >= self?.lastReadPosition ?? -1 {
                    self?.lastReadPosition = readPosition
                    if badge > 0 {
                        let unreadAtMessages = self?.unreadAtMessages ?? []
                        for unreadAtMessage in unreadAtMessages where unreadAtMessage.position > readPosition {
                            self?.state.accept(.showUnReadAt(unreadAtMessage, readPosition))
                            return
                        }
                        self?.state.accept(.showUnReadMessages(badge, readPosition))
                    } else {
                        if self?.state.value ?? .dismiss != .showToLastMessage {
                            self?.state.accept(.dismiss)
                        }
                    }
                }
            }).disposed(by: disposeBag)
        pushMessageObservable
            .filter({ [weak self] (message) -> Bool in
                if (message.isAtMe || message.isAtAll)
                    && !message.meRead
                    && message.position > self?.lastReadPosition ?? -1 {
                    return true
                }
                return false
            })
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (message) in
                guard let `self` = self else { return }
                if message.position > self.unreadAtMessages.last?.position ?? -1 {
                    self.unreadAtMessages.append(message)
                }
                switch self.state.value {
                case .showUnReadAt:
                    break
                case .dismiss, .showToLastMessage:
                    self.state.accept(.showUnReadAt(message, self.lastReadPosition))
                case .showUnReadMessages(_, let readPosition):
                    self.state.accept(.showUnReadAt(message, readPosition))
                }
            }).disposed(by: disposeBag)
    }

    public func update(chat: Chat) {
        updateChatPublish.onNext(chat)
    }

    public func toLastMessageState() {
        switch self.state.value {
        case .dismiss:
            self.state.accept(.showToLastMessage)
        default:
            break
        }
    }

    public func disableLastMessageState() {
        switch self.state.value {
        case .showToLastMessage:
            self.state.accept(.dismiss)
        default:
            break
        }
    }
}
