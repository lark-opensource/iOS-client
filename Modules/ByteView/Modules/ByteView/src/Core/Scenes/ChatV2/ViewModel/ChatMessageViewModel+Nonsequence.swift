//
//  ChatMessageViewModel+Nonsequence.swift
//  ByteView
//
//  Created by wulv on 2020/12/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

extension ChatMessageViewModel {

    func appendPushMessage(_ cellModel: ChatMessageCellModel) {
        if case .sequence = ifPushMessageSequence(cellModel) {
            messagesStore.append(message: cellModel)
        }
    }

    func handleIfMessageNonsequence(cellModel: ChatMessageCellModel) {
        let ifSequence = ifPushMessageSequence(cellModel)
        if case let .nonsequence(item) = ifSequence,
           // 为防止一次拉取过多, 仅在推送的消息与数据源中最新消息相差小于一页时进行补空
           item.count <= Self.countPerPage {
            requestForNonsequenceItem(item)
        }
    }

    private func requestForNonsequenceItem(_ item: NonsequenceItem) {
        guard !isNonsequenceRequesting else { return }
        isNonsequenceRequesting = true

        let distance = requestTimeDistance(with: item)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + distance) { [weak self] in
            guard let self = self else { return }
            self.pullMessage(position: item.position,
                             isPrevious: item.direction.isPrevious,
                             count: item.count)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] messages in
                self?.isNonsequenceRequesting = false
                if messages.0.isEmpty {
                    // 视同补空失败
                    self?.raiseNonsequenceRequestCount(for: item)
                } else {
                    self?.clearLastNonsequence()
                }
            }, onError: { [weak self] _ in
                self?.isNonsequenceRequesting = false
                self?.raiseNonsequenceRequestCount(for: item)
            }).subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                let loadMessages = messages.0.map { self.constructCellModel(with: $0) }
                self.messagesStore.append(messages: loadMessages)
            }).disposed(by: self.disposeBag)
        }
    }
}

extension ChatMessageViewModel {

    enum SequenceStatus {
        case sequence // 连续
        case nonsequence(item: NonsequenceItem) // 不连续
        case duplication // 重复
    }

    private func ifPushMessageSequence(_ pushMessage: ChatMessageCellModel) -> SequenceStatus {
        guard messagesStore.numberOfMessages > 0, let lastPosition = messagesStore.lastPosition else { return .sequence }
        if lastPosition >= pushMessage.position {
            return .duplication
        } else if lastPosition < pushMessage.position - 1 {
            let item = NonsequenceItem(position: lastPosition + 1,
                                       count: pushMessage.position - lastPosition,
                                       direction: .down)
            return .nonsequence(item: item)
        } else {
            return .sequence
        }
    }
}

extension ChatMessageViewModel {

    struct NonsequenceItem: Hashable {
        let position: Int
        let count: Int
        let direction: LoadDirection

        static func == (lhs: NonsequenceItem, rhs: NonsequenceItem) -> Bool {
            return lhs.position == rhs.position &&
                lhs.count == rhs.count &&
                lhs.direction == rhs.direction
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(position)
            hasher.combine(count)
            hasher.combine(direction)
        }
    }

    private func lastNonsequenceRequestCount(item: NonsequenceItem) -> Int {
        guard let last = lastNonsequenceItem[item] else {
            return 0
        }
        return last
    }

    private func raiseNonsequenceRequestCount(for item: NonsequenceItem) {
        guard let last = lastNonsequenceItem[item] else {
            lastNonsequenceItem[item] = 1
            return
        }
        lastNonsequenceItem[item] = last + 1
    }

    private func clearLastNonsequence() {
        lastNonsequenceItem = [:]
    }

    private func requestTimeDistance(with item: NonsequenceItem) -> TimeInterval {
        return meeting.setting.messageRequestConfig.secondsDistance * Double(lastNonsequenceRequestCount(item: item))
    }
}
