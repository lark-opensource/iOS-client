//
//  ReplyInThreadDataSource.swift
//  LarkThread
//
//  Created by liluobin on 2022/4/21.
//

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessageCore
import LarkMessageBase
import RustPB
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer

final class ReplyInThreadDataSource: PageContextWrapper {
    var pageContext: PageContext { vmFactory.context }
    let threadMessageIndex = 0
    let replysIndex = 1
    private static let logger = Logger.log(ReplyInThreadDataSource.self, category: "Business.ReplyInThread")
    private(set) lazy var cellViewModels: [[CellViewModel]] = {
        return [[vmFactory.create(with: ThreadDetailMetaModel(message: threadMessage.rootMessage, getChat: chat),
                                  metaModelDependency: self.getCellDependency())], []]
    }()
    @PageContext.InjectedLazy private var translateService: NormalTranslateService?
    private(set) var threadId: String
    var minPosition: Int32
    var maxPosition: Int32
    private let vmFactory: ThreadReplyMessageCellViewModelFactory
    private var missedMessagePositions: [Int32] = []
    private var readPositionBadgeCount: Int32?
    private (set) var threadMessage: ThreadMessage
    private let chat: () -> Chat
    public var forwardPreviewBottomTipBlock: ((Int, Int32) -> [ThreadDetailCellViewModel])?
    var contentPreferMaxWidth: ((Message) -> CGFloat)?
    var threadMessageCellViewModel: ThreadDetailCellViewModel {
        return self.cellViewModels[threadMessageIndex][0]
    }

    var rootMessage: Message {
        return self.threadMessage.rootMessage
    }

    var editingMessage: Message? {
        didSet {
            if let oldValue = oldValue {
                if let index = self.indexReply(messageId: oldValue.id),
                   let messageVM = self.cellViewModels[replysIndex][index] as? ThreadReplyMessageCellViewModel {
                    messageVM.isEditing = false
                } else if let threadMessageCellViewModel = threadMessageCellViewModel as? ThreadReplyMessageCellViewModel {
                    threadMessageCellViewModel.isEditing = false
                }
            }
            if let newValue = editingMessage {
                if let index = self.indexReply(messageId: newValue.id),
                   let messageVM = self.cellViewModels[replysIndex][index] as? ThreadReplyMessageCellViewModel {
                    messageVM.isEditing = true
                } else if let threadMessageCellViewModel = threadMessageCellViewModel as? ThreadReplyMessageCellViewModel {
                    threadMessageCellViewModel.isEditing = true
                }
            }
        }
    }

    init(
        chat: @escaping () -> Chat,
        threadMessage: ThreadMessage,
        vmFactory: ThreadReplyMessageCellViewModelFactory,
        minPosition: Int32 = -1,
        maxPosition: Int32 = -1
    ) {
        self.chat = chat
        self.vmFactory = vmFactory
        self.minPosition = minPosition
        self.maxPosition = maxPosition
        self.threadId = threadMessage.id
        self.threadMessage = threadMessage
    }

    //整体替换
    func replaceReplys(
        messages: [Message],
        invisiblePositions: [Int32],
        missedPositions: [Int32] = [],
        readPositionBadgeCount: Int32? = nil,
        concurrent: (Int, (Int) -> Void) -> Void) {
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS minMax beforeChange \(self.threadId) \(self.minPosition) \(self.maxPosition) \(messages.count)")
        self.minPosition = messages.first?.threadPosition ?? self.minPosition
        self.maxPosition = messages.last?.threadPosition ?? self.maxPosition
        self.readPositionBadgeCount = readPositionBadgeCount
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS minMax afterChange \(self.threadId) \(self.minPosition) \(self.maxPosition)")
        if !invisiblePositions.isEmpty {
            self.minPosition = min(invisiblePositions.first ?? 0, self.minPosition)
            self.maxPosition = max(invisiblePositions.last ?? 0, self.maxPosition)
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS minMax change by invisiblePositions \(self.threadId) \(invisiblePositions.first) \(invisiblePositions.last)")
        }
        if !missedPositions.isEmpty {
            self.minPosition = min(missedPositions.first ?? 0, self.minPosition)
            self.maxPosition = max(missedPositions.last ?? 0, self.maxPosition)
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS minMax change by missedPositions \(self.threadId) \(missedPositions.first) \(missedPositions.last)")
        }
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS messagesCount \(self.threadId) \(messages.count)")

        if messages.isEmpty {
            self.cellViewModels[replysIndex] = []
            return
        }
        self.cellViewModels[replysIndex] = self.concurrentProcess(messages: messages, concurrent: concurrent)
        if let block = forwardPreviewBottomTipBlock {
            let cellModels = block(messages.count, threadMessage.thread.replyCount)
            self.cellViewModels[replysIndex] += cellModels
        }
    }

    //处理一条消息
    enum HandleMessageScene {
        case newMessage
        case updateMessage
        case messageSendSuccess
        case none
    }

    func handle(message: Message) -> HandleMessageScene {
        guard message.isVisible else {
            //只有连续的不可见消息才可以更新maxMessagePosition
            if message.threadPosition == self.maxPosition + 1 {
                self.maxPosition = message.threadPosition
            }
            return .none
        }
        /// 二次编辑翻译
        if !chat().isCrypto {
            translateService?.translateMessage(translateParam: MessageTranslateParameter(message: message,
                                                                                        source: .common(id: message.id),
                                                                                        chat: chat()),
                                              isFromMessageUpdate: true)
        }
        if self.updateRoot(message: message) {
            return .updateMessage
        }
        //消息更新
        if let cellIndex = self.indexReply(message: message) {
            if let messageCellVM = self.cellViewModels[replysIndex][cellIndex] as? ThreadReplyMessageCellViewModel {
                let contentMessage = messageCellVM.content.message
                if (messageCellVM.message.localStatus == .process || messageCellVM.message.localStatus == .fakeSuccess || messageCellVM.message.cid == messageCellVM.message.id), message.localStatus == .success {
                    //发送状态变成功状态
                    messageCellVM.update(metaModel: ThreadDetailMetaModel(message: message, getChat: chat))
                    ReplyInThreadDataSource.logger.info(
                        "threadReplyTrace replyInThreadDS msg sendSuccess: \(self.threadId) \(message.cid) \(message.id) \(message.threadPosition) \(self.maxPosition)"
                    )
                    //位置不变，但lastMsgPos还是要更新的
                    if message.threadPosition > self.maxPosition {
                        ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS missedMessages: \(self.threadId) \(message.id) \(message.threadPosition) \(self.maxPosition)")
                        /*有些情况下(网不好)，当消息被发送后，服务器返回的实际pos与之前的quasimsgPos之间可能会有n个其他消息，
                         因自己发送的消息必须上屏，不做连续性检测(maxMessagePosition会被更新),这样会导致中间会丢消息，且这些消息后面push过来后因不符合连续性检测，
                         无法上屏,把这些消息记录下*/
                        for pos in self.maxPosition + 1 ..< message.threadPosition {
                            self.missedMessagePositions.append(pos)
                        }
                        self.maxPosition = message.threadPosition
                    }
                    return .messageSendSuccess
                } else {
                    ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS update: \(self.threadId) \(message.id) \(message.cid) \(message.threadPosition)")
                    if message.isRecalled {
                        let recallVM = self.vmFactory.create(with: ThreadDetailMetaModel(message: message, getChat: chat),
                                                             metaModelDependency: self.getCellDependency())
                        self.cellViewModels[replysIndex][cellIndex] = recallVM
                    } else {
                        messageCellVM.update(metaModel: ThreadDetailMetaModel(message: message, getChat: chat))
                    }
                    return .updateMessage
                }
            } // 已经撤回的消息，还是可能更新用户名、重新编辑入口
            else if message.isRecalled, let messageCellVM = self.cellViewModels[replysIndex][cellIndex] as? ThreadDetailRecallCellViewModel {
                messageCellVM.update(metaModel: ThreadDetailMetaModel(message: message, getChat: chat))
                return .updateMessage
            } else if let systemCellVM = self.cellViewModels[replysIndex][cellIndex] as? ThreadDetailSystemCellViewModel {
                systemCellVM.update(metaModel: ThreadDetailMetaModel(message: message, getChat: chat))
                return .updateMessage
            }
        }
        if message.threadPosition == self.maxPosition + 1 {//新消息
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS handle newMsg: \(self.threadId) \(message.id) \(message.threadPosition)")
            self.append(newReply: message)
            return .newMessage
        } else if let missedIndex = missedMessagePositions.firstIndex(of: message.threadPosition) {
            missedMessagePositions.remove(at: missedIndex)
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS handle missedMessage: \(self.threadId) \(message.id) \(message.threadPosition)")
            self.append(newReply: message)
            return .newMessage
        } else if message.localStatus != .success && self.indexReply(cid: message.cid) == nil {//新的发送态消息(因为时序和引用问题，发的新消息可能直接跳过发送态，直接进入失败态)
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS handle process quasimsg: \(self.threadId) \(message.cid)  \(message.threadPosition)")
            self.append(newReply: message)
            return .newMessage
        } else if message.threadPosition > self.maxPosition { //有新消息，但新消息已经不连续了，后续消息都不会接收
            ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS handle discontinuous newMsg: \(self.threadId) \(message.id) \(message.threadPosition)")
            return .none
        }
        return .none
    }

    //前插一段数据
    func headInsert(messages: [Message], invisiblePositions: [Int32], concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        guard let dataMinPosition = self.minPosition(messages: messages, invisiblePositions: invisiblePositions),
            let dataMaxPosition = self.maxPosition(messages: messages, invisiblePositions: invisiblePositions),
            dataMinPosition <= self.minPosition,
            dataMaxPosition >= self.minPosition else {
                ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS headInsert: \(self.threadId) no valid intersection was obtained")
                return false
        }
        let replyCids = self.replyCids()
        //去重，只留小于的
        let showMessages = messages.filter { (msg) -> Bool in
            if msg.threadPosition <= self.minPosition, !replyCids.contains(msg.cid) {
                return true
            }
            return false
        }
        self.minPosition = dataMinPosition
        if showMessages.isEmpty {
            return false
        }
        let result = self.concurrentProcess(messages: showMessages,
                                            concurrent: concurrent)
        self.cellViewModels[replysIndex].insert(contentsOf: result, at: 0)
        return true
    }

    //后插一段数据
    func tailAppend(messages: [Message], invisiblePositions: [Int32], concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        guard let dataMinPosition = self.minPosition(messages: messages, invisiblePositions: invisiblePositions),
            let dataMaxPosition = self.maxPosition(messages: messages, invisiblePositions: invisiblePositions),
            dataMinPosition <= self.maxPosition,
            dataMaxPosition >= self.maxPosition else {
                ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS headInsert: \(self.threadId) no valid intersection was obtained")
                return false
        }
        let replyCids = self.replyCids()
        //去重，只留大于的
        let showMessages = messages.filter { (msg) -> Bool in
            /// 这里有个很小概率偶现的问题，会把跟消息拉取到，暂时加个过滤
            if msg.threadPosition < 0 {
                Self.logger.error("this data get root message --msg.id： \(msg.id) ---msg.threadId： \(msg.threadId) --- msg.position:\(msg.position)")
                return false
            }
            if msg.threadPosition >= self.maxPosition, !replyCids.contains(msg.cid) {
                return true
            }
            return false
        }
        self.maxPosition = dataMaxPosition
        if showMessages.isEmpty {
            return false
        }
        self.cellViewModels[replysIndex].append(contentsOf: self.concurrentProcess(messages: showMessages,
                                                                                     concurrent: concurrent))
        return true
    }

    //插入缺失的消息
    func insertMiss(
        messages: [Message],
        readPositionBadgeCount: Int32? = nil,
        concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        let missMessages = messages.filter { (msg) -> Bool in
            return msg.threadPosition >= self.minPosition && msg.threadPosition <= self.maxPosition
        }
        guard !missMessages.isEmpty else {
            return false
        }
        let currentMessages = self.cellViewModels[replysIndex].compactMap { (cellvm) -> Message? in
            return (cellvm as? HasMessage)?.message
        }
        let mergeMessages = missMessages.lf_mergeUnique(
            array: currentMessages,
            comparable: { (msg1, msg2) -> Int in
                //考虑假消息，如果position相同(msg1.threadPosition - msg2.threadPosition == 0)，说明currentMessages中有假消息，假消息排在后面, 返回0符合预期
                return Int(msg1.threadPosition - msg2.threadPosition)
            },
            equitable: { (msg1, msg2) -> Message? in
                return (msg1.id == msg2.id) ? msg1 : nil
            },
            sequence: .ascending)
        self.cellViewModels[replysIndex] = self.concurrentProcess(messages: mergeMessages, concurrent: concurrent)

        return true
    }

    func refreshRenders() {
        for cellvm in self.cellViewModels[threadMessageIndex] {
            cellvm.calculateRenderer()
        }
        for cellvm in self.cellViewModels[replysIndex] {
            cellvm.calculateRenderer()
        }
    }

    // MARK: 更新消息

    /// 使用 RustPB.Basic_V1_Thread 更新CellViewModel
    ///
    /// - Parameter thread: RustPB.Basic_V1_Thread
    /// - Returns: 是否更新成功
    @discardableResult
    func update(thread: RustPB.Basic_V1_Thread) -> Bool {
        if self.threadId == thread.id,
            let rootCellViewModel = self.cellViewModels[threadMessageIndex].first as? ThreadReplyRootCellViewModel {
            rootCellViewModel.update(thread: thread)
            self.threadMessage.thread = thread
            return true
        }
        return false
    }

    /// 通过ThreadMessage更新根消息CellViewModel
    ///
    /// - Parameter threadMessage: ThreadMessage
    /// - Returns: 是否更新成功
    @discardableResult
    func update(threadMessage: ThreadMessage) -> Bool {
        if self.threadId == threadMessage.id,
            let rootCellViewModel = self.cellViewModels[threadMessageIndex].first as? ThreadReplyRootCellViewModel {
            self.threadMessage = threadMessage
            rootCellViewModel.update(thread: threadMessage.thread)
            rootCellViewModel.update(metaModel: ThreadDetailMetaModel(message: threadMessage.rootMessage, getChat: chat))
            // RootThread 更新时也需要刷新已有子消息vm内的根消息拷贝, 重新触发update
            self.cellViewModels[replysIndex].forEach { cellViewModel in
                if let cellViewModel = cellViewModel as? ThreadReplyMessageCellViewModel {
                    cellViewModel.message.rootMessage = threadMessage.rootMessage
                    cellViewModel.update(metaModel: ThreadDetailMetaModel(message: cellViewModel.message, getChat: chat))
                }
            }
            /// 二次编辑翻译
            if !chat().isCrypto {
                translateService?.translateMessage(translateParam: MessageTranslateParameter(message: threadMessage.rootMessage,
                                                                                            source: .common(id: threadMessage.rootMessage.id),
                                                                                            chat: chat()),
                                                  isFromMessageUpdate: true)
            }
            return true
        }
        return false
    }

    /// 指定doUpdate更新方法，更新messageIds对应多个cellViewModel
    ///
    /// - Parameters:
    ///   - messageIds: [String]
    ///   - doUpdate: (Message) -> Message? 更新函数
    /// - Returns: 是否更新成功
    func update(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        for messageId in messageIds {
            // 先检查是否是回复消息
            if self.updateMessage(messageId, doUpdate: doUpdate) {
                hasChange = true
            } // 如果不是回复消息，再检查时候是否是根消息
            else if self.updateThreadMessage(messageId, doUpdate: doUpdate) {
                hasChange = true
            }
        }
        return hasChange
    }

    /// 指定doUpdate更新方法，更新messageID对应的根消息CellViewModel
    private func updateThreadMessage(_ messageId: String, doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        if let threadDetailRootVM = self.cellViewModels[threadMessageIndex].first as? ThreadReplyRootCellViewModel,
            threadMessage.id == messageId {
            if let newMessage = doUpdate(threadMessage.rootMessage) {
                threadDetailRootVM.update(metaModel: ThreadDetailMetaModel(message: newMessage, getChat: chat))
                hasChange = true
            }
        }
        return hasChange
    }

    /// 指定doUpdate更新方法，更新messageID对应的回复消息CellViewModel
    private func updateMessage(_ messageId: String, doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        if let index = self.indexReply(messageId: messageId),
            let messageVM = self.cellViewModels[replysIndex][index] as? ThreadReplyMessageCellViewModel {
            if let newMessage = doUpdate(messageVM.message) {
                messageVM.update(metaModel: ThreadDetailMetaModel(message: newMessage, getChat: chat))
                hasChange = true
            }
        }
        return hasChange
    }

    /// 数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    func update(original: (Message) -> Message?) -> Bool {
        var updateIndexs: [Int] = []

        // cellViewModels 二维数组 包括rootMessage和replyMessages
        let vms = self.cellViewModels.flatMap { $0 }

        for (index, cellVM) in vms.enumerated() {
            if let cellVM = cellVM as? ThreadReplyRootCellViewModel,
                let newMessage = original(threadMessage.rootMessage) {
                updateIndexs.append(index)
                cellVM.update(metaModel: ThreadDetailMetaModel(message: newMessage, getChat: chat))
            } else if let messageVM = cellVM as? ThreadReplyMessageCellViewModel,
                let newMessage = original(messageVM.message) {
                messageVM.update(metaModel: ThreadDetailMetaModel(message: newMessage, getChat: chat))
                updateIndexs.append(index)
            }
        }

        return updateIndexs.isEmpty ? false : true
    }

    // MARK: - Helper
    //通过position找到对应index, 如果不提供messageId，只匹配成功消息的position
    func indexForReply(position: Int32, messageId: String? = nil) -> Int? {
        return self.cellViewModels[replysIndex].firstIndex { (cellVM) -> Bool in
            if let message = (cellVM as? HasMessage)?.message {
                if let messageId = messageId {
                    return message.threadPosition == position && message.id == messageId
                }
                return message.threadPosition == position && message.localStatus == .success
            }
            return false
        }
    }

    //通过cid找到对应index
    func indexForReply(cid: String) -> Int? {
        return self.cellViewModels[replysIndex].lastIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.cid == cid
            }
            return false
        }
    }

    func indexForReadPositionReply() -> Int? {
        guard let readPositionBadgeCount = self.readPositionBadgeCount else {
            return nil
        }
        return self.cellViewModels[replysIndex].firstIndex(where: { (cellViewModel) -> Bool in
            if let message = (cellViewModel as? HasMessage)?.message {
                if message.isBadged,
                    readPositionBadgeCount + 1 == message.threadBadgeCount {
                    return true
                }
            }
            return false
        })
    }

    /// 根据messageId 获取 IndexPath 包括 更消息和回复消息
    func indexPath(by messageId: String) -> IndexPath? {
        for (section, viewModels) in self.cellViewModels.enumerated() {
            if let index = viewModels.firstIndex(where: { (cellViewModel) -> Bool in
                if let viewModel = cellViewModel as? HasMessage {
                    return viewModel.message.id == messageId
                }
                return false
            }) {
                return IndexPath(item: index, section: section)
            }
        }

        return nil
    }

    // MARK: - iPad适配
    func onResize() {
        for cellVMs in self.cellViewModels {
            cellVMs.forEach { (cellVM) in
                cellVM.onResize()
            }
        }
    }

    private func getCellDependency() -> ThreadDetailCellMetaModelDependency {
        return ThreadDetailCellMetaModelDependency(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] message in
                assert(self?.contentPreferMaxWidth != nil, "please set contentPreferMaxWidth before use")
                return self?.contentPreferMaxWidth?(message) ?? 0
            }
        )
    }
}

// MARK: - ReplyInThreadDataSource
private extension ReplyInThreadDataSource {
    func updateRoot(message: Message) -> Bool {
        if self.threadId == message.id,
            let rootCellViewModel = self.cellViewModels[threadMessageIndex].first as? ThreadReplyRootCellViewModel {
            rootCellViewModel.update(metaModel: ThreadDetailMetaModel(message: message, getChat: chat))
            self.threadMessage.rootMessage = message
            return true
        }
        return false
    }

    func append(newReply: Message) {
        if lastReplyMessage() == nil {
            //之前一条消息都没有，且没有初始数据(-1,-1)(排除之前的消息都被删除或都是不可见的)
            if self.minPosition == -1 && self.maxPosition == -1 {
                self.minPosition = newReply.threadPosition
                self.maxPosition = newReply.threadPosition
            }
        }
        let cellVM = vmFactory.create(with: ThreadDetailMetaModel(message: newReply, getChat: chat),
                                      metaModelDependency: self.getCellDependency())
        self.cellViewModels[replysIndex].append(cellVM)

        if newReply.threadPosition > self.maxPosition {
            self.maxPosition = newReply.threadPosition
        }
    }

    private func lastReplyMessage() -> Message? {
        return (self.cellViewModels[replysIndex].last as? HasMessage)?.message
    }

    //通过message找到对应index
    func indexReply(message: Message) -> Int? {
        return self.cellViewModels[replysIndex].firstIndex { (cellVM) -> Bool in
            if let model = (cellVM as? HasMessage)?.message {
                if model.localStatus != .success || (model.localStatus == .success && model.cid == model.id) {
                    return model.cid == message.cid
                }
                return model.id == message.id
            }
            return false
        }
    }

    func indexReply(messageId: String) -> Int? {
        return self.cellViewModels[replysIndex].firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.id == messageId
            }
            return false
        }
    }

    //通过cid找到对应index
    func indexReply(cid: String) -> Int? {
        return self.cellViewModels[replysIndex].lastIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.cid == cid
            }
            return false
        }
    }

    func replyCids() -> [String] {
        return self.cellViewModels[replysIndex].compactMap { (cellVM) -> String? in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.cid
            }
            return nil
        }
    }

    func concurrentProcess(messages: [Message],
                           concurrent: (Int, (Int) -> Void) -> Void) -> [ThreadDetailCellViewModel] {
        var newCellViewModels = [[ThreadDetailCellViewModel]](repeating: [], count: messages.count)
        newCellViewModels.withUnsafeMutableBufferPointer { (vms) -> Void in
            concurrent(messages.count) { i in
                let message = messages[i]
                let cellVM = vmFactory.create(with: ThreadDetailMetaModel(message: message, getChat: chat),
                                              metaModelDependency: self.getCellDependency())
                vms[i] = [cellVM]
            }
        }
        return newCellViewModels.flatMap { $0 }
    }

    func minPosition(messages: [Message], invisiblePositions: [Int32]) -> Int32? {
        let messageMinPosition = messages.first?.threadPosition ?? Int32.max
        let invisibleMinPosition = invisiblePositions.first ?? Int32.max
        let result = min(messageMinPosition, invisibleMinPosition)
        ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS get minPosition: \(self.threadId) \(result) \(self.minPosition) \(self.maxPosition)")
        return result == Int32.max ? nil : result
    }

    func maxPosition(messages: [Message], invisiblePositions: [Int32]) -> Int32? {
        let messageLastPosition = messages.last?.threadPosition ?? -1
        let invisibleLastPosition = invisiblePositions.last ?? -1
        let result = max(messageLastPosition, invisibleLastPosition)
        ReplyInThreadDataSource.logger.info("threadReplyTrace replyInThreadDS get maxPosition: \(self.threadId) \(result) \(self.minPosition) \(self.maxPosition)")
        return result == -1 ? nil : result
    }
}
