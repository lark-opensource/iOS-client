//
//  MergeForwardMessagesDatasource.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessageBase
import LarkMessageCore
import LarkFeatureGating

struct MergeForwardMessageMetaModel: CellMetaModel {
    let message: Message
    //let mergeForward: Message
    var getChat: () -> Chat

    init(message: Message, getChat: @escaping () -> Chat) {
        self.message = message
        //self.mergeForward = mergeForward
        self.getChat = getChat
    }
}

struct MergeForwardCellMetaModelDependency: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    var config: ChatCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: ChatCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

enum MergeForwardCellVMType {
    case message(Message, MergeForwardCellMetaModelDependency)
    case time(TimeInterval)
    case date(TimeInterval)
    case sign
    case signDate(TimeInterval)
    case previewSign
    func transformToVM(factory: MergeForwardCellViewModelFactory, getChat: @escaping () -> Chat) -> MergeForwardCellViewModel {
        switch self {
        case .message(let message, let dependency):
            let vm = factory.create(with: MergeForwardMessageMetaModel(message: message, getChat: getChat),
                                    metaModelDependency: dependency)
            return vm
        case .time(let time):
            return factory.create(time: time)
        case .date(let date):
            return factory.create(date: date)
        case .sign:
            return factory.createSign()
        case .signDate(let date):
            return factory.createSign(signDate: date)
        case .previewSign:
            return factory.createPreviewSign()
        }
    }

    var chatCellConfig: ChatCellConfig? {
        switch self {
        case .message(_, let dependency):
            return dependency.config
        case .time, .date, .sign, .signDate, .previewSign:
            return nil
        }
    }
}

final class MergeForwardMessagesDatasource {
    private static let logger = Logger.log(MergeForwardMessagesDatasource.self, category: "Business.Chat")

    public fileprivate(set) var cellViewModels: [MergeForwardCellViewModel] = []
    fileprivate let needHourTimeLimit: TimeInterval = 1800
    fileprivate let messageInSameGroupTimeLimit: TimeInterval = 300
    fileprivate let chat: () -> Chat
    private let vmFactory: MergeForwardCellViewModelFactory

    /// 需要处理吸附逻辑的系统消息类型
    private lazy var normalCellStyleSystemTypes: [SystemContent.SystemType] = {
        return SystemContent.SystemType.voipCallTypes
            + SystemContent.SystemType.byteViewTypes
            + SystemContent.SystemType.calendarTypes
    }()

    // 初始cell配置
    public var cellConfig: ChatCellConfig
    public var readPositionBadgeCount: Int32?
    let contentPadding: CGFloat = ChatCellUIStaticVariable.bubblePadding
    var contentPreferMaxWidth: ((Message) -> CGFloat)?

    public init(
        chat: @escaping () -> Chat,
        vmFactory: MergeForwardCellViewModelFactory,
        cellConfig: ChatCellConfig
    ) {
        self.chat = chat
        self.vmFactory = vmFactory
        self.cellConfig = cellConfig
    }

    //重制数据源所有信息，包括数据、上下边界
    func reset(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) {
        return self.replace(messages: messages, concurrent: concurrent)
    }

    //替换数据源中数据
    func replace(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) {
        let showMessages = messages.filter({ !$0.isDeleted })
        if showMessages.isEmpty {
            self.cleanDataSource()
            return
        }
        var types: [MergeForwardCellVMType] = []
        let cur = showMessages[0]
        types.append(contentsOf: processFirstCellVMType(message: cur))
        for index in 1..<showMessages.count {
            let prevMessage = showMessages[index - 1]
            let curMessage = showMessages[index]
            types += self.processMessagesCellVMType(prev: prevMessage,
                                                    cur: curMessage)
        }

        // 替换数据源要考虑Types重新生成
        types = self.processTypes(types)
        self.cellViewModels = concurrentProcess(types: types, concurrent: concurrent)
    }

    /// 前插一段数据
    /// Return: 是否插入成功
    func headAppend(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        let showMessages = messages.filter({ shouldShowMessage($0) })
        if showMessages.isEmpty {
            Self.logger.info("chatTrace mergeForwardDS headAppend showMessages empty: \(messages.map({ $0.id }))")
            return false
        }
        var types: [MergeForwardCellVMType] = []
        let cur = showMessages[0]
        types.append(contentsOf: processFirstCellVMType(message: cur))
        for index in 1..<showMessages.count {
            let prevMessage = showMessages[index - 1]
            let curMessage = showMessages[index]
            types += self.processMessagesCellVMType(prev: prevMessage, cur: curMessage)
        }
        if let firstMessageCellIndex = self.cellViewModels.firstIndex(where: { (cellViewModel) -> Bool in
            return cellViewModel is HasMessage
        }),
           let firstMessageViewModel = self.cellViewModels[firstMessageCellIndex] as? HasCellConfig,
           let preMessage = showMessages.last {
            types += self.processMessagesCellVMType(prev: preMessage,
                                                    cur: firstMessageViewModel.message)
            if let lastType = types.last {
                let endIndex = types.count - 1
                types[endIndex] = self.processType(type: lastType,
                                                   keepBottomLeft: firstMessageViewModel.cellConfig.changeBottomCorner)
            }
            types = self.processTypes(types)
            self.update(cellVM: firstMessageViewModel, cellConfig: types.removeLast().chatCellConfig)
            self.cellViewModels.replaceSubrange((0...firstMessageCellIndex - 1), with: concurrentProcess(types: types, concurrent: concurrent))
        } else {
            types = self.processTypes(types)
            self.cellViewModels = concurrentProcess(types: types, concurrent: concurrent)
        }
        return true
    }

    /// 后插一段数据
    /// Return: 是否插入成功
    func tailAppend(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        let showMessages = messages.filter({ shouldShowMessage($0) })
        if showMessages.isEmpty {
            Self.logger.info("chatTrace mergeForwardDS tailAppend showMessages empty: \(messages.map({ $0.id }))")
            return false
        }
        var types: [MergeForwardCellVMType] = []
        if let lastConfig = lastConfigTuple() {
            let lastVM = lastConfig.1
            var prevMessage = lastVM.message
            for index in 0..<showMessages.count {
                let curMessage = showMessages[index]
                types += self.processMessagesCellVMType(prev: prevMessage, cur: curMessage)
                prevMessage = showMessages[index]
            }
            let config = lastVM.cellConfig
            let lastType: MergeForwardCellVMType = .message(lastVM.message, self.getCellDependency(isSingle: config.isSingle,
                                                                                                   changeTopCorner: config.changeTopCorner,
                                                                                                   changeBottomCorner: config.changeBottomCorner))
            types.insert(lastType, at: 0)
            types = self.processTypes(types)
            self.update(cellVM: lastVM, cellConfig: types.removeFirst().chatCellConfig)
            self.cellViewModels.append(contentsOf: concurrentProcess(types: types, concurrent: concurrent))
        } else {
            // 之前一个消息都没有
            replace(messages: messages, concurrent: concurrent)
        }
        return true
    }

    func shouldShowMessage(_ message: Message) -> Bool {
        if message.isDeleted || message.isFoldSubMessage || !message.isVisible {
            return false
        }
        return true
    }

    func lastConfigTuple() -> (Int, HasCellConfig)? {
        if let hasCellConfig = self.cellViewModels.last as? HasCellConfig {
            return (self.cellViewModels.count - 1, hasCellConfig)
        }
        return nil
    }

    func update(cellVM: HasCellConfig?, cellConfig: ChatCellConfig?) {
        guard let cellVM = cellVM, let cellConfig = cellConfig else {
            return
        }
        (cellVM as? ChatMessageCellViewModel)?.update(config: cellConfig)
    }

    func processFirstCellVMType(message: Message) -> [MergeForwardCellVMType] {
        var types: [MergeForwardCellVMType] = []
        let context = vmFactory.context as? MergeForwardContext
        if context?.showPreviewLimitTip == true { types.append(.previewSign) }
        if message.isBadged,
            let readPositionBadgeCount = readPositionBadgeCount,
            message.badgeCount == readPositionBadgeCount + 1 {
            //以下是新消息气泡
            types.append(.signDate(message.createTime))
        } else {
            //日期气泡
            types.append(.date(message.createTime))
        }
        types.append(.time(message.createTime))

        types.append(.message(message, self.getCellDependency(isSingle: true, changeTopCorner: false)))
        return types
    }

    func processMessagesCellVMType(prev: Message, cur: Message) -> [MergeForwardCellVMType] {
        var types: [MergeForwardCellVMType] = []
        var mustBeSingle = false
        var isNewDay = false
        //不在同一天
        if let dateType = createDateViewModelIfNeeded(prev: prev, cur: cur) {
            types.append(dateType)
            mustBeSingle = true
            isNewDay = true
        }
        //是否显示以下是新消息
        if let newMessageSignType = createShowNewMessageSignViewModelIfNeeded(cur: cur, isNewDay: isNewDay) {
            if isNewDay {
                //newmsgsign中已经显示了天，将上一个datecell移走
                types.removeLast()
            }
            types.append(newMessageSignType)
            mustBeSingle = true
        }
        //发送间隔超出一定时长
        if let timeType = createTimeViewModelIfNeeded(prev: prev, cur: cur) {
            types.append(timeType)
            mustBeSingle = true
        }
        //是否吸附
        if mustBeSingle || !isMessagesInSameGroup(prev: prev, cur: cur) {
            //不吸附
            types.append(.message(cur, self.getCellDependency(isSingle: true, changeTopCorner: false)))
        } else {
            types.append(.message(cur, self.getCellDependency(isSingle: false, changeTopCorner: true)))
        }
        return types
    }

    /// 用于再次处理cellVMTypes，主要针对气泡圆角问题
    ///
    /// - Parameters:
    ///   - cellVMTypes:
    /// - Returns:
    func processTypes(_ cellVMTypes: [MergeForwardCellVMType]) -> [MergeForwardCellVMType] {

        var types: [MergeForwardCellVMType] = []
        var nextConfig: ChatCellConfig?

        let reversedCellVMTypes = Array(cellVMTypes.reversed())
        for index in 0 ..< reversedCellVMTypes.count {
            let type = reversedCellVMTypes[index]
            switch type {
            case .message(let message, let dependency):
                var nextDep = dependency
                if let nextConfig = nextConfig {
                    nextDep.config.changeBottomCorner = nextConfig.changeTopCorner
                    types.append(.message(message, nextDep))
                } else {
                    types.append(type)
                }
                nextConfig = nextDep.config
            default:
                types.append(type)
            }
        }
        types = types.reversed()

        return types
    }

    func processType(type: MergeForwardCellVMType, keepTopLeft: Bool? = nil, keepBottomLeft: Bool? = nil) -> MergeForwardCellVMType {
        switch type {
        case .message(let message, let dependency):
            return .message(message, self.getCellDependency(isSingle: dependency.config.isSingle,
                                                            changeTopCorner: keepTopLeft ?? dependency.config.changeTopCorner,
                                                            changeBottomCorner: keepBottomLeft ?? dependency.config.changeBottomCorner))
        default:
            return type
        }
    }

    func cleanDataSource() {
        self.cellViewModels = []
    }

    //两个气泡是否吸附
    func isMessagesInSameGroup(prev: Message, cur: Message) -> Bool {
        if vmFactory.context.isNewRecallEnable, prev.isRecalled {
            return false
        }
        if let prevContent = prev.content as? SystemContent,
            !normalCellStyleSystemTypes.contains(prevContent.systemType) {
            //如果前一个消息是系统消息样式，肯定不吸附
            return false
        }
        // 有话题回复的消息上下均不吸附
        if prev.threadMessageType == .threadRootMessage || cur.threadMessageType == .threadRootMessage {
            return false
        }
        if prev.fromIdForUI != cur.fromIdForUI {
            return false
        }
        if prev.isEphemeral != cur.isEphemeral {
            return false
        }

        return cur.createTime - prev.createTime <= messageInSameGroupTimeLimit
    }

    //是否需要显示date气泡
    func createDateViewModelIfNeeded(prev: Message, cur: Message) -> MergeForwardCellVMType? {
        if Calendar.current.isDate(Date(timeIntervalSince1970: prev.createTime),
                                   inSameDayAs: Date(timeIntervalSince1970: cur.createTime)) {
            return nil
        }
        return .date(cur.createTime)
    }

    //是否需要显示时间气泡
    func createTimeViewModelIfNeeded(prev: Message, cur: Message) -> MergeForwardCellVMType? {
        if cur.createTime - prev.createTime <= needHourTimeLimit {
            return nil
        }
        return .time(cur.createTime)
    }

    //是否需要显示以下是新消息气泡
    func createShowNewMessageSignViewModelIfNeeded(cur: Message, isNewDay: Bool) -> MergeForwardCellVMType? {
        if cur.isBadged,
            let readPositionBadgeCount = readPositionBadgeCount,
            readPositionBadgeCount + 1 == cur.badgeCount {
            return isNewDay ? .signDate(cur.createTime) : .sign
        }
        return nil
    }

    func findMessageIndexBy(id: String) -> Int? {
        guard !id.isEmpty else {
            return nil
        }
        let index = self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                return messageVM.message.id == id || messageVM.message.cid == id
            }
            return false
        }
        guard let row = index else { return nil }
        return row
    }

    func concurrentProcess(types: [MergeForwardCellVMType],
                           concurrent: (Int, (Int) -> Void) -> Void) -> [MergeForwardCellViewModel] {
        let count = types.count
        var cellViewModels = [[MergeForwardCellViewModel]](repeating: [], count: count)
        cellViewModels.withUnsafeMutableBufferPointer { (vms) -> Void in
            concurrent(count) { i in
                let type = types[i]
                vms[i] = [type.transformToVM(factory: self.vmFactory, getChat: chat)]
            }
        }
        return cellViewModels.flatMap { $0 }
    }

    func getCellDependency(isSingle: Bool, changeTopCorner: Bool = false, changeBottomCorner: Bool = false) -> MergeForwardCellMetaModelDependency {
        var config = self.cellConfig
        config.isSingle = isSingle
        config.changeTopCorner = changeTopCorner
        config.changeBottomCorner = changeBottomCorner
        return MergeForwardCellMetaModelDependency(
            contentPadding: contentPadding,
            contentPreferMaxWidth: { [weak self] message in
                assert(self?.contentPreferMaxWidth != nil, "please set contentPreferMaxWidth before use")
                return self?.contentPreferMaxWidth?(message) ?? 0
            },
            config: config
        )
    }

    func onResize() {
        for cellvm in self.cellViewModels {
            cellvm.onResize()
        }
    }

    @discardableResult
    func update(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        for messageId in messageIds {
            if let indexRow = self.findMessageIndexBy(id: messageId),
                let messageVM = self.cellViewModels[indexRow] as? MergeForwardMessageCellViewModel {
                let message = messageVM.message
                if let newMessage = doUpdate(message) {
                    messageVM.update(metaModel: MergeForwardMessageMetaModel(message: newMessage, getChat: chat))
                    hasChange = true
                }
            }
        }
        return hasChange
    }
    //数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    @discardableResult
    func update(original: (Message) -> Message?) -> Bool {
        var hasChange = false
        for cellVM in self.cellViewModels {
            if let messageVM = cellVM as? MergeForwardMessageCellViewModel, let indexRow = self.findMessageIndexBy(id: messageVM.message.id) {
                if let newMessage = original(messageVM.message) {
                    messageVM.update(metaModel: MergeForwardMessageMetaModel(message: newMessage, getChat: chat))
                    hasChange = true
                }
            }
        }
        return hasChange
    }

}
