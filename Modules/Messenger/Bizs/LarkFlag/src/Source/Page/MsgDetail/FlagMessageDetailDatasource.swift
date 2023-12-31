//
//  FlagMessageDetailDatasource.swift
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

struct FlagMessageDetailMetaModel: CellMetaModel {
    let message: Message
    var getChat: () -> Chat

    init(message: Message, getChat: @escaping () -> Chat) {
        self.message = message
        self.getChat = getChat
    }
}

public struct FlagMessageDetailChatCellConfig {
    // 默认
    public static let `default` = FlagMessageDetailChatCellConfig()

    /// 非吸附消息
    public var isSingle: Bool
    /// 是否有名字和状态(isSingle的优先级更高)
    public var hasHeader: Bool
    /// 是否显示消息状态
    public var hasStatus: Bool
    /// 是否改变气泡上半部分的圆角
    public var changeTopCorner: Bool
    /// 是否改变气泡下半部分的圆角
    public var changeBottomCorner: Bool

    init(isSingle: Bool = true,
         hasHeader: Bool = true,
         hasStatus: Bool = true,
         changeTopCorner: Bool = false,
         changeBottomCorner: Bool = false) {
        self.isSingle = isSingle
        self.hasHeader = hasHeader
        self.hasStatus = hasStatus
        self.changeTopCorner = changeTopCorner
        self.changeBottomCorner = changeBottomCorner
    }
}

struct FlagMessageDetailCellMetaModelDependency: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    var config: FlagMessageDetailChatCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: FlagMessageDetailChatCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

enum FlagMessageDetailCellVMType {
    case message(Message, FlagMessageDetailCellMetaModelDependency)

    func transformToVM(factory: FlagMessageDetailCellViewModelFactory, getChat: @escaping () -> Chat) -> FlagMessageDetailCellViewModel {
        switch self {
        case .message(let message, let dependency):
            let vm = factory.create(with: FlagMessageDetailMetaModel(message: message, getChat: getChat),
                                    metaModelDependency: dependency)
            return vm
        }
    }
}

final class FlagMessageDetailDatasource {
    public fileprivate(set) var cellViewModels: [FlagMessageDetailCellViewModel] = []
    fileprivate let needHourTimeLimit: TimeInterval = 1800
    fileprivate let messageInSameGroupTimeLimit: TimeInterval = 300
    fileprivate let chat: () -> Chat
    private let vmFactory: FlagMessageDetailCellViewModelFactory

    /// 需要处理吸附逻辑的系统消息类型
    private lazy var normalCellStyleSystemTypes: [SystemContent.SystemType] = {
        return SystemContent.SystemType.voipCallTypes
            + SystemContent.SystemType.byteViewTypes
            + SystemContent.SystemType.calendarTypes
    }()

    // 初始cell配置
    public var cellConfig: FlagMessageDetailChatCellConfig
    public var readPositionBadgeCount: Int32?
    var contentPreferMaxWidth: ((Message) -> CGFloat)?

    public init(
        chat: @escaping () -> Chat,
        vmFactory: FlagMessageDetailCellViewModelFactory,
        cellConfig: FlagMessageDetailChatCellConfig
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
        var types: [FlagMessageDetailCellVMType] = []
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

    func processFirstCellVMType(message: Message) -> [FlagMessageDetailCellVMType] {
        var types: [FlagMessageDetailCellVMType] = []
        types.append(.message(message, self.getCellDependency(isSingle: true, changeTopCorner: false)))
        return types
    }

    func processMessagesCellVMType(prev: Message, cur: Message) -> [FlagMessageDetailCellVMType] {
        var types: [FlagMessageDetailCellVMType] = []
        var mustBeSingle = false
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
    func processTypes(_ cellVMTypes: [FlagMessageDetailCellVMType]) -> [FlagMessageDetailCellVMType] {

        var types: [FlagMessageDetailCellVMType] = []
        var nextConfig: FlagMessageDetailChatCellConfig?

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

    func cleanDataSource() {
        self.cellViewModels = []
    }

    //两个气泡是否吸附
    func isMessagesInSameGroup(prev: Message, cur: Message) -> Bool {
        if let prevContent = prev.content as? SystemContent,
            !normalCellStyleSystemTypes.contains(prevContent.systemType) {
            //如果前一个消息是系统消息样式，肯定不吸附
            return false
        }
        if prev.isEphemeral != cur.isEphemeral {
            return false
        }

        if vmFactory.context.isNewRecallEnable, prev.isRecalled {
            return false
        }

        return cur.createTime - prev.createTime <= messageInSameGroupTimeLimit
    }

    func concurrentProcess(types: [FlagMessageDetailCellVMType],
                           concurrent: (Int, (Int) -> Void) -> Void) -> [FlagMessageDetailCellViewModel] {
        let count = types.count
        var cellViewModels = [[FlagMessageDetailCellViewModel]](repeating: [], count: count)
        cellViewModels.withUnsafeMutableBufferPointer { (vms) -> Void in
            concurrent(count) { i in
                let type = types[i]
                vms[i] = [type.transformToVM(factory: self.vmFactory, getChat: chat)]
            }
        }
        return cellViewModels.flatMap { $0 }
    }

    func getCellDependency(isSingle: Bool, changeTopCorner: Bool = false, changeBottomCorner: Bool = false) -> FlagMessageDetailCellMetaModelDependency {
        var config = self.cellConfig
        config.isSingle = isSingle
        config.changeTopCorner = changeTopCorner
        config.changeBottomCorner = changeBottomCorner
        return FlagMessageDetailCellMetaModelDependency(
            contentPadding: 12,
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
}
