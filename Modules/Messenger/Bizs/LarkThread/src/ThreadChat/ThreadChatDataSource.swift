//
//  ThreadChatDataSource.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/13.
//

import Foundation
import LKCommonsLogging
import LarkModel
import LarkExtensions
import LarkMessageCore
import LarkMessageBase
import RustPB
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer

struct ThreadMessageMetaModel: CellMetaModel {
    var threadMessage: ThreadMessage
    var message: Message {
        return threadMessage.message
    }
    var getChat: () -> Chat
    var getTopicGroup: () -> TopicGroup?

    init(threadMessage: ThreadMessage, getChat: @escaping () -> Chat, getTopicGroup: @escaping () -> TopicGroup?) {
        self.threadMessage = threadMessage
        self.getChat = getChat
        self.getTopicGroup = getTopicGroup
    }
}

final class ThreadChatDataSource: UserResolverWrapper {
    let userResolver: UserResolver
    var minPosition: Int32
    var maxPosition: Int32
    private(set) var cellViewModels: [ThreadCellViewModel] = []

    private static let logger = Logger.log(ThreadChatDataSource.self, category: "Business.ThreadChat")
    private let vmFactory: ThreadCellViewModelFactory
    private let chat: () -> Chat
    private let getTopicGroup: () -> TopicGroup?
    private var chatId: String {
        return self.chat().id
    }
    private var missedMessagePositions: [Int32] = []
    private let currentChatterID: String
    var contentPreferMaxWidth: ((Message) -> CGFloat)?

    @ScopedInjectedLazy private var translateService: NormalTranslateService?

    init(userResolver: UserResolver,
        chat: @escaping () -> Chat,
        getTopicGroup: @escaping () -> TopicGroup?,
        currentChatterID: String,
        vmFactory: ThreadCellViewModelFactory,
        minPosition: Int32 = -1,
        maxPosition: Int32 = -1
    ) {
        self.userResolver = userResolver
        self.chat = chat
        self.getTopicGroup = getTopicGroup
        self.currentChatterID = currentChatterID
        self.vmFactory = vmFactory
        self.minPosition = minPosition
        self.maxPosition = maxPosition
    }

    func reset(
        messages: [ThreadMessage],
        invisiblePositions: [Int32],
        missedPositions: [Int32] = [],
        readPositionBadgeCount: Int32? = nil,
        concurrent: (Int, (Int) -> Void) -> Void) {
        ThreadChatDataSource.logger.info("chatTrace chatMsgDS minMax beforeChange \(self.chatId) \(self.minPosition) \(self.maxPosition) \(messages.count)")
        self.minPosition = getMessageMinPositon(by: messages) ?? minPosition
        self.maxPosition = getMessageMaxPositon(by: messages) ?? maxPosition
        ThreadChatDataSource.logger.info("chatTrace chatMsgDS minMax afterChange \(self.chatId) \(self.minPosition) \(self.maxPosition)")
        if !invisiblePositions.isEmpty {
            self.minPosition = min(getMinPositon(by: invisiblePositions) ?? 0, self.minPosition)
            self.maxPosition = max(getMaxPositon(by: invisiblePositions) ?? 0, self.maxPosition)
            ThreadChatDataSource.logger.info("chatTrace chatMsgDS minMax change by invisiblePositions \(self.chatId) \(invisiblePositions.first ?? 0) \(invisiblePositions.last ?? 0)")
        }
        if !missedPositions.isEmpty {
            self.minPosition = min(getMinPositon(by: missedPositions) ?? 0, self.minPosition)
            self.maxPosition = max(getMaxPositon(by: missedPositions) ?? 0, self.maxPosition)
            ThreadChatDataSource.logger.info("chatTrace ChatMsgDS minMax change by missedPositions \(self.chatId) \(missedPositions.first ?? 0) \(missedPositions.last ?? 0)")
        }

        let messageIDs = messages.map { (threadMessage) -> String in
            return threadMessage.thread.id
        }
        ThreadChatDataSource.logger.info("chatTrace chatMsgDS messagesCount \(self.chatId) \(messages.count) \(messageIDs)")

        replace(
            messages: messages,
            readPositionBadgeCount: readPositionBadgeCount,
            concurrent: concurrent
        )
    }

    //整体替换
    private func replace(messages: [ThreadMessage], readPositionBadgeCount: Int32?, concurrent: (Int, (Int) -> Void) -> Void) {
        let showMessages = messages.filter({ self.shouldShowMessage($0) })
        if showMessages.isEmpty {
            self.cleanDataSource()
            return
        }
        self.cellViewModels = self.getStickToTopCellVM() + self.concurrentProcess(messages: showMessages,
                                                                                  readPositionBadgeCount: readPositionBadgeCount,
                                                                                  concurrent: concurrent)
    }

    //处理一条消息
    enum HandleMessageScene {
        case newMessage
        case messageSendSuccess
        case updateMessage
        case none
    }

    func delete(by messageID: String) -> Bool {
        //找到被删除消息的位置
        if let cellIndex = self.index(messageId: messageID) {
            self.cellViewModels.remove(at: cellIndex)

            return true
        } else {
            return false
        }
    }

    func handle(threadMessage: ThreadMessage) -> HandleMessageScene {
        guard threadMessage.isVisible else {
            //只有连续的不可见消息才可以更新maxMessagePosition
            if threadMessage.position == self.maxPosition + 1 {
                self.maxPosition = threadMessage.position
            }
            return .none
        }
        /// 二次编辑翻译
        translateService?.translateMessage(translateParam: MessageTranslateParameter(message: threadMessage.rootMessage,
                                                                                    source: .common(id: threadMessage.rootMessage.id),
                                                                                    chat: chat()),
                                          isFromMessageUpdate: true)
        //消息更新
        if let cellIndex = self.index(message: threadMessage) {
            if let messageCellVM = self.cellViewModels[cellIndex] as? ThreadMessageCellViewModel {
                let contentMessage = messageCellVM.content.message
                if (messageCellVM.message.localStatus == .process || messageCellVM.message.localStatus == .fakeSuccess), threadMessage.localStatus == .success {
                    //发送状态变成功状态
                    messageCellVM.update(metaModel: ThreadMessageMetaModel(
                        threadMessage: threadMessage,
                        getChat: chat,
                        getTopicGroup: self.getTopicGroup)
                    )
                    ThreadChatDataSource.logger.info(
                        "chatTrace chatMsgDS msg sendSuccess: \(self.chatId) \(threadMessage.cid) \(threadMessage.id) \(threadMessage.position) \(self.maxPosition)"
                    )
                    //位置不变，但lastMsgPos还是要更新的
                    if threadMessage.position > self.maxPosition {
                        ThreadChatDataSource.logger.info("chatTrace chatMsgDS missedMessages: \(self.chatId) \(threadMessage.id) \(threadMessage.position) \(self.maxPosition)")
                        /*有些情况下(网不好)，当消息被发送后，服务器返回的实际pos与之前的quasimsgPos之间可能会有n个其他消息，
                         因自己发送的消息必须上屏，不做连续性检测(maxMessagePosition会被更新),这样会导致中间会丢消息，且这些消息后面push过来后因不符合连续性检测，
                         无法上屏,把这些消息记录下*/
                        for pos in self.maxPosition + 1 ..< threadMessage.position {
                            self.missedMessagePositions.append(pos)
                        }
                        self.maxPosition = threadMessage.position
                    }
                    return .messageSendSuccess
                } else {
                    ThreadChatDataSource.logger.info("chatTrace chatMsgDS update: \(self.chatId) \(threadMessage.id) \(threadMessage.cid) \(threadMessage.position)")
                    messageCellVM.update(
                        metaModel: ThreadMessageMetaModel(
                            threadMessage: threadMessage,
                            getChat: chat,
                            getTopicGroup: getTopicGroup
                        )
                    )
                    //NOTE: 此处不做一组indexs更新，而是选择whole，因为ui层单独刷新一组cell时，效果反而不好
                    return .updateMessage
                }
            }
        }
        if threadMessage.position == self.maxPosition + 1 {//新消息
            ThreadChatDataSource.logger.info("chatTrace chatMsgDS handle newMsg: \(self.chatId) \(threadMessage.id) \(threadMessage.position)")
            self.addNewMessage(threadMessage)

            return .newMessage
        } else if let missedIndex = missedMessagePositions.firstIndex(of: threadMessage.position) {
            missedMessagePositions.remove(at: missedIndex)
            ThreadChatDataSource.logger.info("chatTrace chatMsgDS handle missedMessage: \(self.chatId) \(threadMessage.id) \(threadMessage.position)")
            self.addNewMessage(threadMessage)
            return .newMessage
        } else if threadMessage.localStatus != .success && self.index(cid: threadMessage.cid) == nil {//新的发送态消息(因为时序和引用问题，发的新消息可能直接跳过发送态，直接进入失败态)
            ThreadChatDataSource.logger.info("chatTrace chatMsgDS handle process quasimsg: \(self.chatId) \(threadMessage.cid)  \(threadMessage.position)")
            self.addNewMessage(threadMessage)
            return .newMessage
        } else if threadMessage.position > self.maxPosition { //有新消息，但新消息已经不连续了，后续消息都不会接收
            ThreadChatDataSource.logger.info("chatTrace chatMsgDS handle discontinuous newMsg: \(self.chatId) \(threadMessage.id) \(threadMessage.position)")
            return .newMessage
        }
        return .none
    }

    //插入缺失的消息
    func insertMiss(
        threads: [ThreadMessage],
        readPositionBadgeCount: Int32? = nil,
        concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        let missMessages = threads.filter { (msg) -> Bool in
            return msg.position >= self.minPosition && msg.position <= self.maxPosition
        }

        guard !missMessages.isEmpty else {
            return false
        }
        let currentMessages = self.cellViewModels.compactMap { (cellvm) -> ThreadMessage? in
            return (cellvm as? HasThreadMessage)?.getThreadMessage()
        }

        let sequence: SequenceType = .ascending
        let mergeThreadMessages = missMessages.lf_mergeUnique(
            array: currentMessages,
            comparable: { (msg1, msg2) -> Int in
                // 考虑假消息，如果position相同(msg1.position - msg2.position == 0)，说明currentMessages中有假消息，假消息排在后面, 返回0符合预期
                if Int(msg1.position - msg2.position) == 0 {
                     return 0
                }
                return Int(msg1.position - msg2.position)
            },
            equitable: { (msg1, msg2) -> ThreadMessage? in
                return (msg1.id == msg2.id) ? msg1 : nil
            },
            sequence: sequence)

        replace(
            messages: mergeThreadMessages,
            readPositionBadgeCount: readPositionBadgeCount,
            concurrent: concurrent
        )
        return true
    }

    func update(thread: RustPB.Basic_V1_Thread) -> Bool {
        if let cellIndex = self.index(messageId: thread.id),
            let messageCellVM = self.cellViewModels[cellIndex] as? ThreadMessageCellViewModel {
            messageCellVM.update(thread: thread)
            return true
        }
        return false
    }

    func update(rootMessage: Message) -> Bool {
        /// 二次编辑翻译
        translateService?.translateMessage(translateParam: MessageTranslateParameter(message: rootMessage,
                                                                                    source: .common(id: rootMessage.id),
                                                                                    chat: chat()),
                                          isFromMessageUpdate: true)
        //消息更新
        if let cellIndex = self.index(messageId: rootMessage.id) {
            ThreadChatDataSource.logger.info("chatTrace chatMsgDS update: \(self.chatId) \(rootMessage.id) \(rootMessage.cid) \(rootMessage.threadPosition) \(rootMessage.threadId)")
            if let messageCellVM = self.cellViewModels[cellIndex] as? ThreadMessageCellViewModel {
                // 只有自己无痕撤回（删除）话题 立即生效，其他人删除的不会立即生效。自己删的recaller是nil，所以再判断rootMessage.fromId == currentChatterID 。
                if rootMessage.isNoTraceDeleted
                    && (rootMessage.recallerId == currentChatterID || rootMessage.fromId == currentChatterID) {
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

    //前插一段数据
    func headInsert(messages: [ThreadMessage], invisiblePositions: [Int32], readPositionBadgeCount: Int32? = nil, concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        guard getIsInteraction(
            isHeaderInsert: true,
            messages: messages,
            invisiblePositions: invisiblePositions
            ) else {
                ThreadChatDataSource.logger.info("chatTrace chatMsgDS headInsert: \(self.chatId) 未得到有效交集")
                return false
        }
        let messageCids = self.messageCids()
        //去重，只留大于的
        let showMessages = messages.filter { (msg) -> Bool in
            if !shouldShowMessage(msg) {
                return false
            }
            if isRemoveIntersect(isHeaderInsert: true, position: msg.position), !messageCids.contains(msg.cid) {
                return true
            }
            return false
        }
        let minPositionHasChange = updatePosition(isHeaderInsert: true, messages: messages, invisiblePositions: invisiblePositions)
        if showMessages.isEmpty {
            Self.logger.info("chatTrace ChatMsgDS headInsert showMessages empty: \(self.chatId) minPositionHasChange: \(minPositionHasChange) minPosition: \(self.minPosition)")
            if minPositionHasChange {
                self.adjustFirstMessage(readPositionBadgeCount: readPositionBadgeCount)
                return true
            } else {
                return false
            }
        }

        var cellVMs = self.getStickToTopCellVM() + self.concurrentProcess(messages: showMessages,
                                                                          readPositionBadgeCount: readPositionBadgeCount,
                                                                          concurrent: concurrent)
        if let firstMessageCellIndex = self.cellViewModels.firstIndex(where: { cellViewModel -> Bool in
            return cellViewModel is HasThreadMessage
        }), firstMessageCellIndex != 0 {
            if let firstMessageViewModel = (self.cellViewModels[firstMessageCellIndex] as? HasThreadMessage) {
                cellVMs += self.processMessages(cur: firstMessageViewModel.getThreadMessage(), readPositionBadgeCount: readPositionBadgeCount)
                cellVMs.popLast()
            }
            self.cellViewModels.replaceSubrange((0...firstMessageCellIndex - 1),
                                                with: cellVMs)
        } else {
            self.cellViewModels.insert(contentsOf: cellVMs, at: 0)
        }
        return true
    }

    //后插一段数据
    func tailAppend(messages: [ThreadMessage], invisiblePositions: [Int32], readPositionBadgeCount: Int32? = nil, concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        guard getIsInteraction(
            isHeaderInsert: false,
            messages: messages,
            invisiblePositions: invisiblePositions
            ) else {
                ThreadChatDataSource.logger.info("chatTrace chatMsgDS headInsert: \(self.chatId) 未得到有效交集")
                return false
            }
        let messageCids = self.messageCids()
        //去重，只留小于的
        let showMessages = messages.filter { (msg) -> Bool in
            if !self.shouldShowMessage(msg) {
                return false
            }
            if isRemoveIntersect(isHeaderInsert: false, position: msg.position), !messageCids.contains(msg.cid) {
                return true
            }
            return false
        }
        updatePosition(isHeaderInsert: false, messages: messages, invisiblePositions: invisiblePositions)
        if showMessages.isEmpty {
            return false
        }
        self.cellViewModels.append(contentsOf: self.concurrentProcess(messages: showMessages,
                                                                      readPositionBadgeCount: readPositionBadgeCount,
                                                                      concurrent: concurrent))
        return true
    }

    //数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    func update(original: (ThreadMessage) -> ThreadMessage?) -> Bool {
        var updateIndexs: [Int] = []
        for (index, cellVM) in self.cellViewModels.enumerated() {
            if let messageCellVM = cellVM as? ThreadMessageCellViewModel {
                if let newData = original(messageCellVM.threadMessage) {
                    messageCellVM.update(
                        metaModel: ThreadMessageMetaModel(
                            threadMessage: newData,
                            getChat: chat,
                            getTopicGroup: getTopicGroup
                        )
                    )
                    updateIndexs.append(index)
                }
            }
        }
        return updateIndexs.isEmpty ? false : true
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
                            messageCellVM.update(
                                metaModel: ThreadMessageMetaModel(
                                    threadMessage: threadMessage,
                                    getChat: chat,
                                    getTopicGroup: getTopicGroup
                                )
                            )
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    //通过message找到对应index
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

    //通过messageId找到对应index
    func index(messageId: String) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                return messageCellVM.getRootMessage().id == messageId
            }
            return false
        }
    }

    //通过cid找到对应index
    func index(cid: String) -> Int? {
        return self.cellViewModels.lastIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                return messageCellVM.getRootMessage().cid == cid
            }
            return false
        }
    }

    //通过msgposition找到对应index, 如果不提供messageId，只匹配成功消息的position
    func index(messagePosition: Int32, messageId: String? = nil) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                let message = messageCellVM.getRootMessage()
                if let messageId = messageId {
                    return message.position == messagePosition && message.id == messageId
                }
                return message.position == messagePosition && message.localStatus == .success
            }
            return false
        }
    }

    //通过threadPosition找到对应index
    func index(threadPosition: Int32) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                return messageCellVM.getThreadMessage().position == threadPosition
            }
            return false
        }
    }

    func indexForNewMessageSignCell() -> Int? {
        return self.cellViewModels.firstIndex(where: { (cellViewModel) -> Bool in
            return cellViewModel is ThreadSignCellViewModel
        })
    }

    func refreshRenders() {
        for cellvm in self.cellViewModels {
            cellvm.calculateRenderer()
        }
    }

    func onResize() {
        for cellvm in self.cellViewModels {
            cellvm.onResize()
        }
    }

    func remove(afterPosition: Int32, redundantCount: Int) {
        var index: Int?
        index = self.cellViewModels.lastIndex(where: { (cellVM) -> Bool in
            return (cellVM as? HasThreadMessage)?.getThreadMessage().position == afterPosition
        })
        if var index = index {
            var count = 0
            let totalCount = self.cellViewModels.count
            while count < redundantCount && index < totalCount - 1 {
                index += 1
                if self.cellViewModels[index] is HasThreadMessage {
                    count += 1
                }
            }
            if count == redundantCount, index < totalCount - 1, let position = (self.cellViewModels[index] as? HasThreadMessage)?.getThreadMessage().position {
                self.cellViewModels.removeSubrange((index + 1..<self.cellViewModels.count))
                self.maxPosition = position
                ThreadChatDataSource.logger.info("chatTrace remove after \(self.chatId) \(self.maxPosition)")
            }
        }
    }

    // MARK: support reverse FG
    private func getMaxPositon(by positons: [Int32]) -> Int32? {
        return positons.last
    }

    private func getMinPositon(by positons: [Int32]) -> Int32? {
        return positons.first
    }

    private func getMessageMaxPositon(by messages: [ThreadMessage]) -> Int32? {
        return messages.last?.position
    }

    private func getMessageMinPositon(by messages: [ThreadMessage]) -> Int32? {
        return messages.first?.position
    }

    private func addNewMessage(_ threadMessage: ThreadMessage) {
        append(newMessage: threadMessage)
    }

    private func getResultBy(isHeaderInsert: Bool, resultForMax: Bool, resultForMin: Bool) -> Bool {
        return isHeaderInsert ? resultForMin : resultForMax
    }

    private func getIsInteraction(isHeaderInsert: Bool, messages: [ThreadMessage], invisiblePositions: [Int32]) -> Bool {
        guard let dataMinPosition = self.minPosition(messages: messages, invisiblePositions: invisiblePositions) else { return false }

        guard let dataMaxPosition = self.maxPosition(messages: messages, invisiblePositions: invisiblePositions) else { return false }

        let forMaxPostion = (dataMinPosition <= self.maxPosition) && (dataMaxPosition >= self.maxPosition)
        let forMinPostion = (dataMinPosition <= self.minPosition) && (dataMaxPosition >= self.minPosition)

        return getResultBy(
            isHeaderInsert: isHeaderInsert,
            resultForMax: forMaxPostion,
            resultForMin: forMinPostion
        )
    }

    private func isRemoveIntersect(isHeaderInsert: Bool, position: Int32) -> Bool {
        let forMaxPostion = position >= self.maxPosition
        let forMinPostion = position <= self.minPosition

       return getResultBy(
            isHeaderInsert: isHeaderInsert,
            resultForMax: forMaxPostion,
            resultForMin: forMinPostion
        )
    }

    @discardableResult
    private func updatePosition(isHeaderInsert: Bool, messages: [ThreadMessage], invisiblePositions: [Int32]) -> Bool {
        if !isHeaderInsert,
           let dataMaxPosition = self.maxPosition(messages: messages, invisiblePositions: invisiblePositions) {
            if self.maxPosition != dataMaxPosition {
                self.maxPosition = dataMaxPosition
                return true
            }
        } else if let dataMinPosition = self.minPosition(messages: messages, invisiblePositions: invisiblePositions) {
            if self.minPosition != dataMinPosition {
                self.minPosition = dataMinPosition
                return true
            }
        }
        return false
    }

    private func getReadPositionBadgeCountForNewMenssageSign(_ readPositionBadgeCount: Int32) -> Int32 {
        return readPositionBadgeCount + 1
    }

    private func getCellDependency() -> ThreadCellMetaModelDependency {
        return ThreadCellMetaModelDependency(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] message in
                assert(self?.contentPreferMaxWidth != nil, "please set contentPreferMaxWidth before use")
                return self?.contentPreferMaxWidth?(message) ?? 0
            },
            config: ThreadCellConfig.default
        )
    }
    // chat.firstMessagePosition 比如：安全的需求
    func adjustMinMessagePosition(readPositionBadgeCount: Int32? = nil) -> Bool {
        let firstMessagePosition = self.chat().firstMessagePostion
        let chatThreadPosition = self.chat().bannerSetting?.chatThreadPosition
        Self.logger.info("chatTrace chatMsgDS adjustMinMessagePosition: \(self.chatId) \(firstMessagePosition) \(self.minPosition) \(self.maxPosition) \(String(describing: chatThreadPosition))")
        if firstMessagePosition < self.minPosition {
            /// eg. [firstMessagePosition + 1 == self.minPosition]
            /// 当前数据源上边界正好等于会话上边界，需要更新首条消息之前的内容
            self.adjustFirstMessage(readPositionBadgeCount: readPositionBadgeCount)
            return true
        }
        /// 会话中的消息全清掉
        if firstMessagePosition >= self.maxPosition {
            self.minPosition = firstMessagePosition
            self.maxPosition = firstMessagePosition
            self.cleanDataSource()
            return true
        }
        if let firstMessageCellIndex = self.cellViewModels.firstIndex(where: { cellViewModel -> Bool in
            guard let message = (cellViewModel as? HasThreadMessage)?.getThreadMessage() else { return false }
            return message.position > firstMessagePosition
        }), let firstMessageViewModel = (self.cellViewModels[firstMessageCellIndex] as? HasThreadMessage) {
            var cellVMs: [ThreadCellViewModel] = self.getStickToTopCellVM() + self.processMessages(cur: firstMessageViewModel.getThreadMessage(), readPositionBadgeCount: readPositionBadgeCount)
            cellVMs.popLast()
            self.minPosition = firstMessagePosition + 1
            if firstMessageCellIndex == 0 {
                self.cellViewModels.insert(contentsOf: cellVMs, at: 0)
            } else {
                self.cellViewModels.replaceSubrange((0...firstMessageCellIndex - 1),
                                                    with: cellVMs)
            }
            return true
        }
        return false
    }
}

private extension ThreadChatDataSource {
    func processMessages(cur: ThreadMessage, readPositionBadgeCount: Int32? = nil) -> [ThreadCellViewModel] {
        var viewModels: [ThreadCellViewModel] = []
        // 不是观察者模式，是否显示以下是新消息
        if !(getTopicGroup()?.isParticipant ?? false),
            let newMessageSignViewModel = createShowNewMessageSignViewModelIfNeeded(cur: cur, readPositionBadgeCount: readPositionBadgeCount) {
            viewModels.append(newMessageSignViewModel)
        }

        let messageCellViewModel = vmFactory.create(
            with: ThreadMessageMetaModel(
                threadMessage: cur,
                getChat: chat,
                getTopicGroup: getTopicGroup
            ),
            metaModelDependency: self.getCellDependency()
        )
        viewModels.append(messageCellViewModel)
        return viewModels
    }

    func append(newMessage: ThreadMessage) {
        defer {
            self.adjustFirstMessage()
        }
        if lastMessage() == nil {
            //之前一条消息都没有，且没有初始数据(-1,-1)(排除之前的消息都被删除或都是不可见的)
            if self.minPosition == -1 && self.maxPosition == -1 {
                self.minPosition = newMessage.position
                self.maxPosition = newMessage.position
            }
        }

        let newCellVMs = self.processMessages(cur: newMessage)
        self.cellViewModels += newCellVMs

        if newMessage.position > self.maxPosition {
            self.maxPosition = newMessage.position
        }
    }

    private func lastMessage() -> Message? {
        return (self.cellViewModels.last as? HasMessage)?.message
    }

    //是否需要显示以下是新消息气泡
    func createShowNewMessageSignViewModelIfNeeded(cur: ThreadMessage, readPositionBadgeCount: Int32? = nil) -> ThreadCellViewModel? {
        if cur.isBadged,
            let readPositionBadgeCount = readPositionBadgeCount,
            getReadPositionBadgeCountForNewMenssageSign(readPositionBadgeCount) == cur.badgeCount {
            ThreadChatDataSource.logger.info(
                """
                create sign cell vm:
                messageID: \(cur.id)
                threadPosition: \(cur.position)
                isBadged: \(cur.isBadged)
                readPositionBadgeCount: \(getReadPositionBadgeCountForNewMenssageSign(readPositionBadgeCount))
                badgeCount: \(cur.badgeCount)
                """
            )
            return vmFactory.createSign()
        }
        return nil
    }

    func cleanDataSource() {
        self.cellViewModels = self.getStickToTopCellVM(cleanData: true)
    }

    func messageCids() -> [String] {
        return self.cellViewModels.compactMap { (cellVM) -> String? in
            if let messageCellVM = cellVM as? HasThreadMessage {
                return messageCellVM.getRootMessage().cid
            }
            return nil
        }
    }

    func concurrentProcess(messages: [ThreadMessage],
                           readPositionBadgeCount: Int32? = nil,
                           concurrent: (Int, (Int) -> Void) -> Void) -> [ThreadCellViewModel] {
        var newCellViewModels = [[ThreadCellViewModel]](repeating: [], count: messages.count)
        newCellViewModels.withUnsafeMutableBufferPointer { (vms) -> Void in
            concurrent(messages.count) { i in
                let message = messages[i]
                let cellVMs = self.processMessages(
                    cur: message,
                    readPositionBadgeCount: readPositionBadgeCount
                )
                vms[i] = cellVMs
            }
        }
        return newCellViewModels.flatMap { $0 }
    }

    func minPosition(messages: [ThreadMessage], invisiblePositions: [Int32]) -> Int32? {
        let messageMinPosition = getMessageMinPositon(by: messages) ?? Int32.max
        let invisibleMinPosition = getMinPositon(by: invisiblePositions) ?? Int32.max
        let result = min(messageMinPosition, invisibleMinPosition)
        ThreadChatDataSource.logger.info("chatTrace chatMsgDS get minPosition: \(self.chatId) \(result) \(self.minPosition) \(self.maxPosition)")
        return result == Int32.max ? nil : result
    }

    func maxPosition(messages: [ThreadMessage], invisiblePositions: [Int32]) -> Int32? {
        let messageMaxPosition = getMessageMaxPositon(by: messages) ?? -1
        let invisibleMaxPosition = getMaxPositon(by: invisiblePositions) ?? -1
        let result = max(messageMaxPosition, invisibleMaxPosition)
        ThreadChatDataSource.logger.info("chatTrace chatMsgDS get maxPosition: \(self.chatId) \(result) \(self.minPosition) \(self.maxPosition)")
        return result == -1 ? nil : result
    }

    func shouldShowMessage(_ message: ThreadMessage) -> Bool {
        return message.isVisible && message.position > self.chat().firstMessagePostion
    }

    func getStickToTopCellVM(cleanData: Bool = false) -> [ThreadCellViewModel] {
        var stickToTop: [ThreadCellViewModel] = []
        let context = vmFactory.context as? ThreadContext
        if context?.showPreviewLimitTip == true && !cleanData {
            stickToTop.append(vmFactory.createPreviewTip(copyWriting: BundleI18n.LarkThread.Lark_IM_MoreMessagesViewInChat_Text))
        }
        let chat = self.chat()
        if chat.needShowTopBanner,
           self.minPosition <= chat.firstMessagePostion + 1,
           let topBannerTip = chat.topBannerTip {
            stickToTop.append(vmFactory.createTopMsgTip(tip: topBannerTip))
        }
        return stickToTop
    }

    func adjustFirstMessage(readPositionBadgeCount: Int32? = nil) {
        if let firstMessageCellIndex = self.cellViewModels.firstIndex(where: { cellViewModel -> Bool in
            return cellViewModel is HasThreadMessage
        }), let firstMessageViewModel = (self.cellViewModels[firstMessageCellIndex] as? HasThreadMessage) {
            var cellVMs: [ThreadCellViewModel] = self.getStickToTopCellVM() + self.processMessages(cur: firstMessageViewModel.getThreadMessage(), readPositionBadgeCount: readPositionBadgeCount)
            cellVMs.popLast()
            if firstMessageCellIndex == 0 {
                self.cellViewModels.insert(contentsOf: cellVMs, at: 0)
            } else {
                self.cellViewModels.replaceSubrange((0...firstMessageCellIndex - 1),
                                                    with: cellVMs)
            }
            return
        }
        self.cleanDataSource()
    }
}
