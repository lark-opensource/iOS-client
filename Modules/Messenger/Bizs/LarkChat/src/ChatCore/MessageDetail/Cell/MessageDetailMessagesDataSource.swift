//
//  MessageDetailMessagesDataSource.swift
//  Action
//
//  Created by 赵冬 on 2019/7/23.
//

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessageBase
import LarkCore
import RxSwift
import LarkFeatureGating
import LarkContainer

struct MessageDetailMetaModel: CellMetaModel {
    let message: Message
    var getChat: () -> Chat

    init(message: Message, getChat: @escaping () -> Chat) {
        self.message = message
        self.getChat = getChat
    }
}

final class MessageDetailMessagesDataSource {
    enum HandleMessageType {
        case none
        case deleteMessage
        case updateReply
        case updateRoot
        case newReply
    }

    var userResolver: UserResolver { vmFactory.context.userResolver }
    private let rootMessageIndex = 0
    private let replysIndex = 1
    private let chat: () -> Chat
    private let disposeBag = DisposeBag()
    /// 会话内是否存在不可见消息
    var existInVisibleMessage: Bool
    var vmFactory: MessageDetailMessageCellViewModelFactory

    var dataSourceIsEmpty: Bool {
        return self.cellViewModels.flatMap({ $0 }).isEmpty
    }

    /// 最终需要渲染的数据源，如果原始数据源为空需要在这里做一层数据源替换
    var renderCellViewModels: [[MessageDetailCellViewModel]] {
        if self.dataSourceIsEmpty {
            return placeholderTipCellViewModels
        }
        if self.existInVisibleMessage {
            return [[vmFactory.createMessageInVisibleTipCell(copyWriting: self.messageInvisibleTip)],
                    cellViewModels[replysIndex]]
        }
        return cellViewModels
    }

    /// 原始数据源为空时本地构造的数据源
    private lazy var placeholderTipCellViewModels: [[MessageDetailCellViewModel]] = {
        return [[vmFactory.createPlaceholderTipCell(copyWriting: self.placeholderTip)], []]
    }()

    private lazy var cellViewModels: [[MessageDetailCellViewModel]] = {
        var vms: [MessageDetailCellViewModel] = []
        if let message = rootMessage {
            vms = [vmFactory.create(with: MessageDetailMetaModel(message: message, getChat: chat),
                                    metaModelDependency: self.getCellDependency(config: MessageDetailCellConfig.rootMessage))]
        }
        return [vms, []]
    }()

    private var rootMessage: Message?

    private(set) var replyMessages: [LarkModel.Message] = []
    private let getPlaceholderTip: () -> String
    private lazy var placeholderTip: String = self.getPlaceholderTip()
    private let getMessageInvisibleTip: () -> String
    private lazy var messageInvisibleTip: String = self.getMessageInvisibleTip()
    private let isBurned: (Message) -> Bool
    var contentPreferMaxWidth: ((Message) -> CGFloat)?

    init(
        rootMessage: Message?,
        chat: @escaping () -> Chat,
        vmFactory: MessageDetailMessageCellViewModelFactory,
        getPlaceholderTip: @escaping () -> String,
        getMessageInvisibleTip: @escaping () -> String,
        isBurned: @escaping (Message) -> Bool,
        existInVisibleMessage: Bool
    ) {
        self.rootMessage = rootMessage
        self.chat = chat
        self.vmFactory = vmFactory
        self.getPlaceholderTip = getPlaceholderTip
        self.getMessageInvisibleTip = getMessageInvisibleTip
        self.isBurned = isBurned
        self.existInVisibleMessage = existInVisibleMessage
    }

    //整体替换
    func replaceReplies(messages: [Message]? = nil) {
        if var messages = messages {
            // 首先和原来的replies融合
            messages = self.merge(messages: messages)
            // 排序保证消息顺序不发生改变
            self.replyMessages = self.sortMessagesByPosition(messages: messages)
            let replyCellViewModel: [MessageDetailCellViewModel] = self.replyMessages.map { (message) -> LarkMessageBase.CellViewModel<MessageDetailContext> in
                let message = self.replaceUrlToTitle(message: message)
                let cellVM = vmFactory.create(with: MessageDetailMetaModel(message: message, getChat: chat),
                                              metaModelDependency: self.getCellDependency())
                return cellVM
            }
            self.cellViewModels[replysIndex] = replyCellViewModel
        }
    }

    func handle(message: Message) -> HandleMessageType {
        if !checkVisible(message) {
            return .none
        }
        if isNeedRemove(message: message) {
            remove(message: message)
            return .deleteMessage
        }
        if isNeedUpdate(newMessage: message) {
            update(message: message)
            if isRootMessageOf(message) {
                return .updateRoot
            }
            return .updateReply
        }
        if isNeedAdd(newMessage: message) {
            append(message)
            return .newReply
        }
        return .none
    }

    /// 检查消息是否可见
    func checkVisible(_ message: Message) -> Bool {
        return message.isVisible && message.position > chat().firstMessagePostion
    }

    @discardableResult
    func update(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        for messageId in messageIds {
            if let indexPath = self.indexOf(messageId),
                let messageVM = self.cellViewModels[indexPath.section][indexPath.row] as? MessageDetailMessageCellViewModel {
                let message = messageVM.message
                if let newMessage = doUpdate(message) {
                    if indexPath.section == replysIndex {
                        self.replyMessages[indexPath.row] = newMessage
                    } else if indexPath.section == rootMessageIndex {
                        self.rootMessage = newMessage
                    }
                    messageVM.update(metaModel: MessageDetailMetaModel(message: newMessage, getChat: chat))
                    hasChange = true
                }
            }
        }
        return hasChange
    }

    func isRootMessageOf(_ id: String) -> Bool {
        if id == self.rootMessage?.id || id == self.rootMessage?.cid {
            return true
        }
        return false
    }

    func isRootMessageOf(_ message: Message) -> Bool {
        if message.id == self.rootMessage?.id || message.cid == self.rootMessage?.cid {
            return true
        }
        return false
    }

    //数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    @discardableResult
    func update(original: (Message) -> Message?) -> Bool {
        var hasChange = false
        for cellRowVMs in self.cellViewModels {
            for cellVM in cellRowVMs {
                    if let messageVM = cellVM as? MessageDetailMessageCellViewModel,
                        let indexPath = self.indexOf(messageVM.message.id) {
                    if let newMessage = original(messageVM.message) {
                        if indexPath.section == replysIndex {
                            self.replyMessages[indexPath.row] = newMessage
                        } else if indexPath.section == rootMessageIndex {
                            self.rootMessage = newMessage
                        }
                        messageVM.update(metaModel: MessageDetailMetaModel(message: newMessage, getChat: chat))
                        hasChange = true
                    }
                }
            }
        }
        return hasChange
    }

    @discardableResult
    func update(message: Message) -> Bool {
        if self.isRootMessageOf(message) {
            self.rootMessage = message
            let cellVM = self.cellViewModels[rootMessageIndex][0] as? MessageDetailMessageCellViewModel
            cellVM?.update(metaModel: MessageDetailMetaModel(message: message, getChat: chat))
            return true
        } else if let indexPath = self.indexOf(message) {
            self.replyMessages[indexPath.row] = message
            let cellVM = self.cellViewModels[indexPath.section][indexPath.row] as? MessageDetailMessageCellViewModel
            cellVM?.update(metaModel: MessageDetailMetaModel(message: message, getChat: chat))
            return true
        }
        return false
    }

    // 回复消息添加新消息VM
    func append(_ newReply: Message) {
        self.replyMessages.append(newReply)
        let cellVM = vmFactory.create(with: MessageDetailMetaModel(message: newReply, getChat: chat),
                                      metaModelDependency: self.getCellDependency())
        self.cellViewModels[replysIndex].append(cellVM)
    }

    // 通id/cid删除reply
    @discardableResult
    func delete(_ id: String) -> Bool {
        if let indexPath = self.indexOf(id) {
            if indexPath.section == rootMessageIndex {
                self.rootMessage = nil
                self.cellViewModels[rootMessageIndex] = []
                return true
            } else if indexPath.section == replysIndex {
                self.replyMessages.remove(at: indexPath.row)
                self.cellViewModels[replysIndex].remove(at: indexPath.row)
                return true
            }
            return false
        }
        return false
    }

    func indexOf(_ message: Message) -> IndexPath? {
        if let indexPath = self.indexOf(message.id) {
            return indexPath
        } else if let indexPath = self.indexOf(message.cid) {
            return indexPath
        }
        return nil
    }

    // 通过id或者cid找到message的indexPath
    func indexOf(_ id: String) -> IndexPath? {
        if self.isRootMessageOf(id) {
            return IndexPath(row: 0, section: rootMessageIndex)
        }
        let index = self.cellViewModels[replysIndex].firstIndex { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                if messageCellVM.message.localStatus != .success || (messageCellVM.message.localStatus == .success && messageCellVM.message.cid == messageCellVM.message.id) {
                    return messageCellVM.message.cid == id
                }
                return messageCellVM.message.id == id
            }
            return false
        }
        guard let row = index else { return nil }
        return IndexPath(row: row, section: replysIndex)
    }

    func onResize() {
        for cellvm in self.cellViewModels.flatMap({ $0 }) {
            cellvm.onResize()
        }
    }

    func getCellDependency(config: MessageDetailCellConfig = .default) -> MessageDetailCellModelDependency {
        return MessageDetailCellModelDependency(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] message in
                assert(self?.contentPreferMaxWidth != nil, "please set contentPreferMaxWidth before use")
                return self?.contentPreferMaxWidth?(message) ?? 0
            },
            config: config
        )
    }
}

private extension MessageDetailMessagesDataSource {
    func merge(messages: [LarkModel.Message]) -> [LarkModel.Message] {
        var mergedReplies: [LarkModel.Message] = []
        for message in messages {
            if let index = self.replyMessages.firstIndex(where: { $0.cid == message.cid }) {
                //如果内存中已包含同样的消息
                if message.localStatus == .success && self.replyMessages[index].localStatus != .success {
                    // 优先选择真消息，可能是从服务端拉回来的
                    mergedReplies.append(message)
                } else {
                    // 用内存中已有的
                    mergedReplies.append(self.replyMessages[index])
                }
            } else {
                mergedReplies.append(message)
            }
        }
        if vmFactory.context.isNewRecallEnable {
            return  mergedReplies.filter({ !$0.isRecalled })
        }
        return mergedReplies
    }

    func sortMessagesByPosition(messages: [Message]) -> [Message] {
        return messages.sorted(by: {
            if $0.position == $1.position {
                return $0.updateTime < $1.updateTime
            }
            return $0.position < $1.position
        })
    }

    //处理一条消息

    // 将有url的message替换为icon + title
    func replaceUrlToTitle(message: LarkModel.Message) -> LarkModel.Message {
        if var content = message.content as? TextContent {
            let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap)
            content.richText = textDocsVM.richText
            message.content = content
        }
        return message
    }

    func remove(message: LarkModel.Message) {
        self.delete(message.id)
    }

    func isNeedAdd(newMessage: LarkModel.Message) -> Bool {
      if self.indexOf(newMessage) == nil {
          return true
      }
        return false
    }

    func isNeedRemove(message: LarkModel.Message) -> Bool {
        if self.isRootMessageOf(message) {
            if isBurned(message) {
                return true
            }
            return false
        }
        if message.isDeleted || isBurned(message) {
            return true
        }
        if vmFactory.context.isNewRecallEnable, message.isRecalled {
            return true
        }
        return false
    }

    func isNeedUpdate(newMessage: LarkModel.Message) -> Bool {
        if newMessage.isRecalled || indexOf(newMessage) != nil {
            return true
        }
        return false
    }
}
