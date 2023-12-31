//
//  ChatMessageStore.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

protocol ChatMessageStoreDelegate: AnyObject {
    func newMessagesDidAppend(messages: [ChatMessageCellModel])
    func unreadMessageDidChange()
}

final class ChatMessageStore {

    /// 冻结态: 新消息只被保存，不刷新列表，但参与未读消息计数；当冻结态取消时更新到全部消息列表并刷新 UI
    private(set) var isFrozen = false
    weak var delegate: ChatMessageStoreDelegate?

    /// 使用-1标记没有已读记录(全都未读)
    private static let defaultReadPosition: Int = -1

    // 未开启分组讨论或者在主会场时为会议 ID，否则为 breakoutRoomID
    private let meetingID: String

    private var messages: [ChatMessageCellModel] = []
    /// 暂存消息列表，不展示在页面上，但会参与未读消息计数。
    /// 当用户选中某个消息弹出菜单栏时收到新消息推送时，在菜单栏消失之前新消息暂存在这里，防止新消息触发 reloadData 导致菜单栏和选中状态显示异常
    private var frozenMessages: [ChatMessageCellModel] = []
    /// 最新的一条已读消息
    private var readMessage: ChatMessageCellModel?
    /// 当前聊天室内最新消息，首次进入会议会拉一次，用于该场景下未读消息数量计算
    private var latestMessage: ChatMessageCellModel?

    /// 最新的一条未读消息
    /// 如果有未读消息 (unreadMessageCount != 0): latestMessage == unreadMessage，不一定 == messages.last
    /// 如果所有消息均已读 (unreadMessageCount == 0): latestMessage == messages.last, unreadMessage == nil
    private(set) var unreadMessage: ChatMessageCellModel?
    /// 未读消息的数量。
    /// 5.14 新增：unreadMessageCount 不一定等于 unreadMessage.position - readMessage.position，要对自己设备发送的消息进行过滤
    private(set) var unreadMessageCount = 0
    /// 每场会议/分组讨论中聊天已读消息位置的记录
    private lazy var readPositions = ChatMessageCache<Int>(storage: storage, key: .readMessage, valueKey: meetingID)
    /// 每场会议/分组讨论中聊天消息浏览位置的记录
    private lazy var scanningPositions = ChatMessageCache<Int>(storage: storage, key: .scanningMessage, valueKey: meetingID)
    /// 每场会议/讨论组中，自本设备已读消息以后，本设备已发送且未读的消息位置
    private lazy var sentMessagePositions = ChatMessageCache<[Int]>(storage: storage, key: .sentPositions, valueKey: meetingID)

    let storage: UserStorage
    init(storage: UserStorage, meetingID: String, delegate: ChatMessageStoreDelegate? = nil) {
        self.storage = storage
        self.meetingID = meetingID
        self.delegate = delegate
    }

    // MARK: - Getter

    func message(at index: Int) -> ChatMessageCellModel? {
        if index < messages.count {
            return messages[index]
        } else {
            return nil
        }
    }

    func messageIndex(for position: Int) -> Int? {
        guard let message = message(for: position) else { return nil }
        return messages.firstIndex(of: message)
    }

    func message(for id: String) -> ChatMessageCellModel? {
        messages.first { $0.id == id }
    }

    func messageIndex(for id: String) -> Int? {
        guard let message = messages.first(where: { $0.id == id }) else { return nil }
        return messages.firstIndex(of: message)
    }

    var numberOfMessages: Int { messages.count }

    var numberOfFrozenMessages: Int { frozenMessages.count }

    var firstPosition: Int {
        messages.first?.position ?? 0
    }

    var lastPosition: Int? {
        messages.last?.position
    }

    var currentReadPosition: Int {
        readPositions.values[meetingID] ?? Self.defaultReadPosition
    }

    var currentScanningPosition: Int {
        scanningPositions.values[meetingID] ?? Self.defaultReadPosition
    }

    var currentUnreadSentCountFromSelf: Int {
        sentMessagePositions.values[meetingID]?.count ?? 0
    }

    var messagesAllUnread: Bool {
        currentScanningPosition == Self.defaultReadPosition
    }

    // MARK: - Modifier

    func append(messages: [ChatMessageCellModel]) {
        if isFrozen {
            self.frozenMessages = unionMessage(with: self.frozenMessages, and: messages)
            updateLatestMessage(lastMessageForFrozen)
        } else {
            self.messages = unionMessage(with: self.messages, and: messages)

            if readMessage == nil {
                readMessage = self.message(for: currentReadPosition)
            }

            updateLatestMessage(self.messages.last)
        }
        delegate?.newMessagesDidAppend(messages: self.messages)
    }

    func append(message: ChatMessageCellModel) {
        append(messages: [message])
    }

    func send(message: ChatMessageCellModel) {
        var positions = sentMessagePositions.values[meetingID] ?? []
        if let index = positions.firstIndex(where: { $0 >= message.position }) {
            positions.insert(message.position, at: index)
        } else {
            positions.append(message.position)
        }
        sentMessagePositions.setValue(positions)

        append(message: message)
    }

    func updateExpiredMsgPosition(position: Int32?) {
        guard let position = position,
              Int(position) > self.currentReadPosition else {
            return
        }
        let pos = Int(position)
        readPositions.setValue(pos)

        var positions = sentMessagePositions.values[meetingID] ?? []
        positions.removeAll(where: { $0 <= pos })
        sentMessagePositions.setValue(positions)
        updateUnreadMessage()
    }

    /// 更新已读消息，完成后会执行未读消息数变更的回调
    func updateReadMessage(at indexPath: IndexPath) {
        guard let currentReadMessage = message(at: indexPath.row) else { return }

        // 更新最新已读消息位置
        var newReadMessage: ChatMessageCellModel?
        if let message = readMessage, currentReadMessage.position > message.position {
            newReadMessage = currentReadMessage
        } else if currentReadMessage.position > currentReadPosition {
            newReadMessage = currentReadMessage
        }
        if let message = newReadMessage, readMessage != message {
            readMessage = message
            readPositions.setValue(message.position)

            var positions = sentMessagePositions.values[meetingID] ?? []
            positions.removeAll(where: { $0 <= message.position })
            sentMessagePositions.setValue(positions)

            updateUnreadMessage()
        }

        // 更新本次浏览位置
        scanningPositions.setValue(currentReadMessage.position)
    }

    /// 更新当前最新消息，完成后会执行未读消息数变更的回调
    func updateLatestMessage(_ latestMessage: ChatMessageCellModel?) {

        if let current = self.latestMessage {
            if let message = latestMessage, current.position < message.position {
                // 如果 self.latestMessage 不为空，比较 position
                self.latestMessage = message
            }
        } else {
            // 如果当前 self.latestMessage 为空，直接赋值更新
            self.latestMessage = latestMessage
        }

        updateUnreadMessage()
    }

    func freezeMessages() {
        isFrozen = true
    }

    func unfreezeMessages() {
        isFrozen = false
        append(messages: frozenMessages)
        frozenMessages = []
    }

    // MARK: - Private

    private func message(for position: Int) -> ChatMessageCellModel? {
        messages.first { $0.position == position }
    }

    /// 更新最新未读消息记录和总未读消息数，并发送回调
    private func updateUnreadMessage() {
        if let last = latestMessage, last.position > currentReadPosition {
            unreadMessage = last
            unreadMessageCount = max(last.position - currentReadPosition - currentUnreadSentCountFromSelf, 0)
        } else {
            unreadMessage = nil
            unreadMessageCount = 0
        }
        delegate?.unreadMessageDidChange()
    }

    private func unionMessage(with first: [ChatMessageCellModel], and second: [ChatMessageCellModel]) -> [ChatMessageCellModel] {
        let set = Set(first)
        let unioned = set.union(second.filter { $0.meetingID == meetingID })
        let sorted = unioned.sorted(by: messageSortRule)
        return sorted
    }

    private var messageSortRule: (ChatMessageCellModel, ChatMessageCellModel) -> Bool {
        return { (lhs, rhs) -> Bool in
            return lhs.position < rhs.position
        }
    }

    private var lastMessageForFrozen: ChatMessageCellModel? {
        if let lastFrozenMessage = frozenMessages.last {
            let lastMessage = messages.last
            return lastFrozenMessage.position > (lastMessage?.position ?? 0) ? lastFrozenMessage : lastMessage
        } else {
            return messages.last
        }
    }
}

private class ChatMessageCache<T: Codable & Equatable> {

    private let storage: UserStorage
    private let key: UserStorageKey
    private let valueKey: String

    lazy var values: [String: T] = {
        storage.value(forKey: key) ?? [:]
    }()

    init(storage: UserStorage, key: UserStorageKey, valueKey: String) {
        self.storage = storage
        self.key = key
        self.valueKey = valueKey
    }

    func setValue(_ value: T) {
        guard values[valueKey] != value else { return }
        values[valueKey] = value
        storage.setValue(values, forKey: key)
    }
}
