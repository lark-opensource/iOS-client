//
//  TopUnReadMessagesTipViewModel.swift
//  Lark
//
//  Created by zc09v on 2018/5/14.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import LarkContainer
import LarkMessageCore
import LarkSDKInterface
import LarkFeatureGating

final class TopUnReadMessagesTipViewModel: BaseUnreadMessagesTipViewModel {
    private let readPositionBadgeCount: Int32
    private var minReadPositionBadgeCount: Int32?
    private lazy var unreadAtMessages: [Message] = []
    private let messageAPI: MessageAPI
    private let chatId: String
    private let pushCenter: PushNotificationCenter
    private let preloadMessagePosition: Int32

    init(
        userResolver: UserResolver,
        chatId: String,
        firstUnreadMessagePosition: Int32,
        messageAPI: MessageAPI,
        pushCenter: PushNotificationCenter,
        readPositionBadgeCount: Int32) {
        self.readPositionBadgeCount = readPositionBadgeCount
        self.messageAPI = messageAPI
        self.pushCenter = pushCenter
        self.chatId = chatId
        self.preloadMessagePosition = firstUnreadMessagePosition
        Self.logger.info("topUnReadMessagesTip trace init \(chatId) \(readPositionBadgeCount) \(firstUnreadMessagePosition)")
        super.init(userResolver: userResolver)
        observeState()
        observePush()
    }

    override func fetchDataWhenLoad() {
        self.fetchUnreadAtMessages()
        self.preloadMessages(position: preloadMessagePosition).subscribe().disposed(by: self.disposeBag)
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
            .flatMap { [weak self] (state) -> Observable<Void> in
                guard let self = self else { return .empty() }
                switch state {
                case .showUnReadAt(_, let position):
                    return self.preloadMessages(position: position)
                default:
                    return .empty()
                }
            }.subscribe().disposed(by: self.disposeBag)
    }

    private func fetchUnreadAtMessages() {
        messageAPI.fetchUnreadAtMessages(chatIds: [self.chatId], ignoreBadged: false, needResponse: true)
            .map({ [weak self] (chatMessagesMap) -> [Message] in
                return chatMessagesMap[self?.chatId ?? ""] ?? []
            })
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (unreadAtMessages) in
                self?.unreadAtMessages = unreadAtMessages.sorted(by: { (msg1, msg2) -> Bool in
                    return msg1.position > msg2.position
                })
                let unreadAtMessages = (self?.unreadAtMessages ?? [])
                for msg in unreadAtMessages {
                    Self.logger.info("topUnReadMessagesTip trace fetchUnreadAtMessages \(self?.chatId ?? "") \(msg.position) \(msg.badgeCount) \(msg.id)")
                }
                switch self?.state.value ?? .dismiss {
                case .dismiss, .showToLastMessage:
                    break
                case .showUnReadAt(let currentUnReadAtMsg, let minReadPosition):
                    for unreadAtMessage in unreadAtMessages where
                        (unreadAtMessage.badgeCount >= self?.readPositionBadgeCount ?? -1 &&
                            unreadAtMessage.position <= minReadPosition &&
                            unreadAtMessage.position > currentUnReadAtMsg.position) {
                                self?.state.accept(.showUnReadAt(unreadAtMessage, minReadPosition))
                                return
                    }
                case .showUnReadMessages(_, let minReadPosition):
                    for unreadAtMessage in unreadAtMessages where unreadAtMessage.position <= minReadPosition {
                        self?.state.accept(.showUnReadAt(unreadAtMessage, minReadPosition))
                        return
                    }
                @unknown default:
                    break
                }
            }).disposed(by: disposeBag)
    }

    private func observePush() {
        let chatId = self.chatId
        pushCenter.observable(for: PushMessageReadStates.self)
            .filter { $0.messageReadStates.chatID == chatId }
            .observeOn(self.dataScheduler)
            .map({ [weak self] (push) -> (badgeCount: Int32, position: Int32)? in
                let sorted = push.messageReadStates.readStatesExtra.sorted { (info1, info2) -> Bool in
                    return info1.value.position < info2.value.position
                }
                for state in sorted {
                    Self.logger.info("topUnReadMessagesTip trace messageReadStates \(chatId) \(state.value.position) \(state.value.badgeCount)")
                }
                if let extra = sorted.first?.value, self?.update(extra.badgeCount) ?? false {
                    return (badgeCount: extra.badgeCount, position: extra.position)
                }
                return nil
            }).subscribe(onNext: { [weak self] result in
                if let result = result {
                    self?.changeState(badgeCount: result.badgeCount, position: result.position)
                }
            }).disposed(by: disposeBag)
    }

    public func updateMessageRead(message: Message) {
        self.dataQueue.async { [weak self] in
            guard self?.update(message.badgeCount) ?? false else {
                return
            }
            self?.changeState(badgeCount: message.badgeCount, position: message.position)
        }
    }

    private func changeState(badgeCount: Int32, position: Int32) {
        Self.logger.info("topUnReadMessagesTip update changeState \(self.chatId) \(badgeCount) \(position) \(self.readPositionBadgeCount)")
        if badgeCount <= self.readPositionBadgeCount {
            self.state.accept(.dismiss)
        } else {
            let unreadAtMessages = self.unreadAtMessages
            for unreadAtMessage in unreadAtMessages where
                (unreadAtMessage.badgeCount >= self.readPositionBadgeCount &&
                    unreadAtMessage.position < position) {
                        self.state.accept(.showUnReadAt(unreadAtMessage, position))
                        return
            }
            let count = badgeCount - self.readPositionBadgeCount
            self.state.accept(.showUnReadMessages(count, position))
        }
    }

    private func update(_ newPositionBadgeCount: Int32) -> Bool {
        Self.logger.info("topUnReadMessagesTip update newPositionBadgeCount \(self.chatId) \(self.minReadPositionBadgeCount ?? -1)")
        if let minReadPositionBadgeCount = self.minReadPositionBadgeCount {
            if newPositionBadgeCount < minReadPositionBadgeCount {
                self.minReadPositionBadgeCount = newPositionBadgeCount
                return true
            } else {
                return false
            }
        } else {
            self.minReadPositionBadgeCount = newPositionBadgeCount
            return true
        }
    }
}
