//
//  ThreadListDataSource.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/8/22.
//

import Foundation
import LarkModel
import LarkMessageBase
import LKCommonsLogging
import LarkAccountInterface
import RustPB
import LarkSDKInterface

private struct ThreadListDataSourceLog {
   static let logger = Logger.log(ThreadListDataSourceLog.self, category: "Thread")
}

/// ThreadListDataSource 主要运用在无IM特性的列表中，目前用在广场和我参与的话题
final class ThreadListDataSource<T> {

    var currentChatterID: String

    //处理一条消息
    enum HandleThreadMessageScene {
        case addMessage
        case deleteMessage
        case updateMessage
        case none
    }

    private(set) var cellViewModels: [ThreadCellViewModel] = []
    /// 同一个Chat情景下获取Chat，在ThreadList中有2种情况。1. 所有话题存在同一个Chat。2. 所有话题不属于同一个Chat。
    private let getChat: (() -> Chat)?

    private let getTopicGroup: (() -> TopicGroup?)?

    /// 创建ThreadListDataSource对象
    ///
    /// - Parameters:
    ///   - getChat: (() -> Chat)? 在小组模式中获取统一Chat。其他模式（话题不是属于统一Chat）下使用ThreadMessage中的Chat模型
    ///   - currentChatterID: String
    ///   - vmFactory: ThreadCellViewModelFactory
    init(currentChatterID: String,
         getChat: (() -> Chat)? = nil,
         getTopicGroup: (() -> TopicGroup?)? = nil
    ) {
        self.currentChatterID = currentChatterID
        self.getChat = getChat
        self.getTopicGroup = getTopicGroup
    }

    func onResize() {
        for cellvm in self.cellViewModels {
            cellvm.onResize()
        }
    }

    // MARK: - 数据处理
    /// 在头部增加一条话题
    private func insert(newMessage: ThreadMessage, processThreadMessage: (ThreadMessage) -> [ThreadCellViewModel]) -> Bool {
        let newCellVMs = processThreadMessage(newMessage)
        if newCellVMs.isEmpty {
            return false
        }
        if cellViewModels.isEmpty {
            self.cellViewModels += newCellVMs
        } else {
            self.cellViewModels.insert(contentsOf: newCellVMs, at: 0)
        }
        return true
    }

    private func tailAppend(newMessage: ThreadMessage, processThreadMessage: (ThreadMessage) -> [ThreadCellViewModel]) -> Bool {
        let newCellVMs = processThreadMessage(newMessage)
        if newCellVMs.isEmpty {
            return false
        }
        cellViewModels.append(contentsOf: newCellVMs)
        return true
    }

    /// 过滤数据
    func filterDataProcess(filter: (CellViewModel<ThreadContext>) -> Bool) {
        cellViewModels = cellViewModels.filter { (cellVM) -> Bool in
            return filter(cellVM)
        }
    }

    /// 整体替换数据。return ture有数据且替换成功, false 无数据。
    func replace(
        messages: [T],
        filter: ((T) -> Bool)? = nil,
        concurrent: (Int, (Int) -> Void) -> Void,
        processMessage: @escaping (T) -> [ThreadCellViewModel]
    ) -> Bool {
        var showMessages = messages
        if let filter = filter {
            showMessages = messages.filter { (message) -> Bool in
                return filter(message)
            }
        }

        if showMessages.isEmpty {
            self.cellViewModels = []
            return false
        }
        self.cellViewModels = self.concurrentProcess(
            messages: showMessages,
            concurrent: concurrent,
            processMessage: processMessage
        )
        return true
    }

    // 末尾插入一段数据
    func tailAppend(
        messages: [T],
        concurrent: (Int, (Int) -> Void) -> Void,
        processMessage: @escaping (T) -> [ThreadCellViewModel]
    ) -> Bool {
        if messages.isEmpty {
            return false
        }
        let result = self.concurrentProcess(
            messages: messages,
            concurrent: concurrent,
            processMessage: processMessage
        )
        if result.isEmpty {
            return false
        }
        self.cellViewModels.append(contentsOf: result)
        return true
    }

    func headInsert(
        messages: [T],
        concurrent: (Int, (Int) -> Void) -> Void,
        processMessage: @escaping (T) -> [ThreadCellViewModel]
    ) -> Bool {
        if messages.isEmpty {
            return false
        }
        let result = self.concurrentProcess(
            messages: messages,
            concurrent: concurrent,
            processMessage: processMessage
        )
        if result.isEmpty {
            return false
        }

        if self.cellViewModels.isEmpty {
            self.cellViewModels.append(contentsOf: result)
        } else {
            self.cellViewModels.insert(contentsOf: result, at: 0)
        }

        return true
    }

    // 处理threadMessages

    /// 处理ThreadMessage
    ///
    /// - Parameters:
    ///   - threadMessage: ThreadMessage
    ///   - removeFilter: (ThreadMessage) -> Bool 移除时的外部过滤条件前提条件。
    ///   - addFilter: (ThreadMessage) -> Bool 需要添加新话题时的过滤条件。
    /// - Returns: HandleThreadMessageScene
    func handle(
        threadMessage: ThreadMessage,
        removeFilter: (ThreadMessage) -> Bool,
        addFilter: (ThreadMessage) -> (isAdd: Bool, isInsert: Bool),
        processThreadMessage: (ThreadMessage) -> [ThreadCellViewModel]
    ) -> HandleThreadMessageScene {
        // 存在这条消息
        if let cellIndex = self.index(message: threadMessage),
           let messageCellVM = self.cellViewModels[cellIndex] as? ThreadMessageCellViewModel {
            // 外部过滤条件 决定是否移除话题
            if removeFilter(threadMessage) {
                self.cellViewModels.remove(at: cellIndex)
                return .deleteMessage
            } // 在当前屏幕，那就只是更新数据
            else {
                if let metaModel = createThreadMetaData(threadMessage: threadMessage) {
                    messageCellVM.update(metaModel: metaModel)
                    return .updateMessage
                } else {
                    ThreadListDataSourceLog.logger.error("LarkThread error: handle threadMessage no chat")
                    return .none
                }
            }
        }

        // 新增话题。外部过滤条件 决定是否过滤话题
        if removeFilter(threadMessage) {
            return .none
        }

        // 添加过滤条件 && 插入threadMessage
        let addFilter = addFilter(threadMessage)
        guard addFilter.isAdd else {
            return .none
        }
        let addResult: Bool
        if addFilter.isInsert {
            addResult = self.insert(newMessage: threadMessage, processThreadMessage: processThreadMessage)
        } else {
            addResult = self.tailAppend(newMessage: threadMessage, processThreadMessage: processThreadMessage)
        }
        if addResult {
            return .addMessage
        }
        return .none
    }

    /// delete threadMessage in memery data. 移除cellViewModels中的threadMessage
    func delete(by index: () -> Int?) -> Bool {
        if let cellIndex = index() {
            self.cellViewModels.remove(at: cellIndex)
            return true
        }

        return false
    }

    func concurrentProcess(
        messages: [T],
        concurrent: (Int, (Int) -> Void) -> Void,
        processMessage: @escaping (T) -> [ThreadCellViewModel]) -> [ThreadCellViewModel] {
        var newCellViewModels = [[ThreadCellViewModel]](repeating: [], count: messages.count)
        newCellViewModels.withUnsafeMutableBufferPointer { (vms) -> Void in
            concurrent(messages.count) { i in
                vms[i] = processMessage(messages[i])
            }
        }
        return newCellViewModels.flatMap { $0 }
    }

    // MARK: - Helper
    func createThreadMetaData(threadMessage: ThreadMessage) -> ThreadMessageMetaModel? {
        // ThreadMessage属于同一个Chat
        if let getChat = self.getChat,
            let getTopicGroup = self.getTopicGroup {
            return ThreadMessageMetaModel(
                threadMessage: threadMessage,
                getChat: getChat,
                getTopicGroup: getTopicGroup
            )
        }

        // ThreadMessage属于不同Chat的情况
        if let chat = threadMessage.chat {
            return ThreadMessageMetaModel(
                threadMessage: threadMessage,
                getChat: {
                    return chat
                },
                getTopicGroup: {
                    return threadMessage.topicGroup
                }
            )
        }

        return nil
    }

    func update(rootMessage: Message) -> Bool {
        //消息更新
        if let cellIndex = self.index(messageId: rootMessage.id) {
            if let messageCellVM = self.cellViewModels[cellIndex] as? ThreadMessageCellViewModel {
                // 只有自己无痕撤回（删除）话题 立即生效，其他人删除的不会立即生效。
                if rootMessage.isNoTraceDeleted && (rootMessage.recallerId == self.currentChatterID || rootMessage.fromId == self.currentChatterID) {
                    self.cellViewModels.remove(at: cellIndex)
                    return true
                } else {
                    messageCellVM.update(rootMessage: rootMessage)
                    return true
                }
            } else if let systemCellVM = self.cellViewModels[cellIndex] as? ThreadSystemCellViewModel {
                systemCellVM.update(rootMessage: rootMessage)
                return true
            }
        }
        return false
    }

    /// 通过message找到对应index
    func index(message: ThreadMessage) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                let model = messageCellVM.getRootMessage()
                if model.localStatus != .success || (model.localStatus == .success && model.cid == model.id) {
                    return model.cid == message.cid
                }
                return model.id == message.id
            }
            return false
        }
    }

    func update(thread: RustPB.Basic_V1_Thread) -> Bool {
        // 存在对应Thread
        if let cellIndex = self.index(messageId: thread.id),
            let messageCellVM = self.cellViewModels[cellIndex] as? ThreadMessageCellViewModel {
            messageCellVM.update(thread: thread)
            return true
        }

        return false
    }

    func update(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        for messageId in messageIds {
            if update(messageId: messageId, doUpdate: doUpdate) {
                hasChange = true
            }
        }
        return hasChange
    }

    /// - Parameters:
    ///   - id: id is messageId or messageCid
    func cellViewModel(by id: String) -> ThreadCellViewModel? {
        return self.cellViewModels.first { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                let message = messageCellVM.getRootMessage()
                return message.id == id || message.cid == id
            }
            return false
        }
    }

    /// 通过messageId找到对应index
    func index(messageId: String) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                return messageCellVM.getRootMessage().id == messageId
            }
            return false
        }
    }

    /// 数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    func update(original: (ThreadMessage) -> ThreadMessage?) -> Bool {
        var updateIndexs: [Int] = []
        for (index, cellVM) in self.cellViewModels.enumerated() {
            if let messageCellVM = cellVM as? ThreadMessageCellViewModel,
                let threadMessage = original(messageCellVM.threadMessage) {
                    if let chat = threadMessage.chat {
                        let metaData = ThreadMessageMetaModel(
                            threadMessage: threadMessage,
                            getChat: {
                                return chat
                            },
                            getTopicGroup: {
                                return threadMessage.topicGroup
                            }
                        )
                        messageCellVM.update(metaModel: metaData)
                        updateIndexs.append(index)
                    } else {
                        ThreadListDataSourceLog.logger.error("LarkThread error: processMessages threadMessage no chat")
                    }
            }
        }
        return updateIndexs.isEmpty ? false : true
    }

    /// 更新Message，包括了rootMessage和replyMessage
    private func update(messageId: String, doUpdate: (Message) -> Message?) -> Bool {
        for cellVM in self.cellViewModels {
            if let messageCellVM = cellVM as? ThreadMessageCellViewModel {
                // rootMessage
                if messageCellVM.getRootMessage().id == messageId {
                    if let newMessage = doUpdate(messageCellVM.getRootMessage()) {
                        messageCellVM.update(rootMessage: newMessage)
                        return true
                    }
                }// 回复预览消息
                else {
                    var threadMessage = messageCellVM.getThreadMessage()
                    for (index, replyMessage) in threadMessage.replyMessages.enumerated() {
                        if messageId == replyMessage.id, let newMessage = doUpdate(replyMessage) {
                            threadMessage.replyMessages[index] = newMessage
                            messageCellVM.update(threadMessage: threadMessage)
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}
