//
//  MyAIMainChatMessagesDatasource.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/17.
//

import Foundation
import LKCommonsLogging
import LarkModel
import ThreadSafeDataStructure
import RxSwift
import LarkMessageBase
import LarkMessageCore

class MyAIMainChatMessagesDatasource: ChatMessagesDatasource, MyAIOnboardCardDatasourceProtocol {
    private let logger = Logger.log(MyAIMainChatMessagesDatasource.self, category: "Business.Chat")
    static let COUNT_PER_PAGE_OF_MY_AI_CHAT_MODE: Int32 = 20

    private let myAIMainChatProcessor: MyAIMainChatMessageDatasourceProcessor

    private var unfoldedMyAIChatModeThread: SafeDictionary<Int64, MyAIChatModeThreadInfo> {
        return myAIMainChatProcessor.unfoldedMyAIChatModeThread
    }

    func getUIData() -> [ChatCellViewModel] {
        return cellViewModels + onboardVMs
    }

    func getOnboardVMs() -> [ChatCellViewModel] {
        return onboardVMs
    }

    private var onboardVMs: [ChatCellViewModel] = []

    /// 展示onboard卡片
    func setOnboardCard(_ info: MyAIOnboardInfo, concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        self.onboardVMs = []
        let types: [CellVMType] = [.mockSystemMessage(.textWithLine(BundleI18n.AI.Lark_MyAI_IM_Server_StartNewTopic_Text)), .aiOnboardCard(info: info)]
        self.onboardVMs.append(contentsOf: concurrentProcess(types: types, concurrent: concurrent))
        return true
    }

    /// 移除onboard卡片
    func removeOnboardCard() -> Bool {
        self.onboardVMs = []
        return false
    }

    var onboardVM: AIChatOnboardCardCellViewModel? {
        onboardVMs.last as? AIChatOnboardCardCellViewModel
    }

    init(chat: @escaping () -> Chat,
         vmFactory: ChatCellViewModelFactory,
         minMessagePosition: Int32 = -1,
         maxMessagePosition: Int32 = -1,
         isMessageBurned: @escaping (Message) -> Bool,
         messageCellProcessor: MyAIMainChatMessageDatasourceProcessor) {
        self.myAIMainChatProcessor = messageCellProcessor
        super.init(chat: chat,
                   vmFactory: vmFactory,
                   minMessagePosition: minMessagePosition,
                   maxMessagePosition: maxMessagePosition,
                   isMessageBurned: isMessageBurned,
                   messageCellProcessor: messageCellProcessor)
    }

    override func handleNewMessageAhead(_ message: Message) -> HandleMessageScene? {
        if self.updateAIChatModeFoldMessageCellViewModelIfNeed(message) {
            return .updateMessage
        } else if message.aiChatModeID > 0,
           message.threadPosition >= 0 {
            //my ai 主会场收到了分会场回贴的push
            guard let info = self.unfoldedMyAIChatModeThread[message.aiChatModeID] else {
                self.logger.info("chatTrace ChatMsgDS handle aiChatMode folded msg: \(self.chatId) \(message.id) \(message.threadPosition) \(message.aiChatModeID)")
                return HandleMessageScene.none
            }
            guard info.unfoldedMaxPosition > message.threadPosition else {
                self.logger.info("chatTrace ChatMsgDS handle aiChatMode folded msg: \(self.chatId) \(message.id) \(message.threadPosition) \(message.aiChatModeID) unfoldedMaxPosition:\(info.unfoldedMaxPosition)")
                return HandleMessageScene.none
            }
            guard message.localStatus == .success else {
                //分会场的假消息不在主会场上屏
                self.logger.info("chatTrace ChatMsgDS handle aiChatMode process quasimsg: \(self.chatId) \(message.id) \(message.threadPosition) \(message.aiChatModeID)")
                return HandleMessageScene.none
            }
            if message.threadPosition == info.currentMaxThreadPosition + 1 {
                self.logger.info("chatTrace ChatMsgDS handle aiChatMode newMsg: \(self.chatId) \(message.id) \(message.threadPosition) \(message.aiChatModeID)")
                self.appendForUnfoldRegion(newMessage: message)
                return HandleMessageScene.newMessage
            } else if message.position > self.maxMessagePosition {
                // 有新消息，但新消息已经不连续了，后续消息都不会接收
                self.logger.info("chatTrace ChatMsgDS handle aiChatMode discontinuous newMsg: \(self.chatId) \(message.id) \(message.threadPosition) \(message.aiChatModeID)")
                return HandleMessageScene.none
            }
        }
        return nil
    }

    private func updateAIChatModeFoldMessageCellViewModelIfNeed(_ message: Message) -> Bool {
        if let cellVM = self.cellViewModels.last(where: {
            return ($0 as? AIChatModeFoldMessageCellViewModel)?.message.id == message.id
        }) as? AIChatModeFoldMessageCellViewModel {
            cellVM.message = message
            return true
        }
        return false
    }

    override func checkVisible(_ message: Message) -> Bool {
        if self.unfoldedMyAIChatModeThread[message.aiChatModeID]?.unfoldedMaxPosition ?? 0 > message.threadPosition && message.threadPosition >= 0 {
            return true
        }
        return super.checkVisible(message)
    }

    override func handle(message: Message, concurrent: (Int, (Int) -> Void) -> Void) -> HandleMessageScene {
        // 排查点击赞踩icon没有变化的日志：看日志请求、赞踩Push、界面刷新信号一切正常，怀疑是被带错误赞踩状态的MessagePush给冲掉了
        self.logger.info("my ai handle message: \(self.chatId) \(message.id) \(message.feedbackStatus)")
        return super.handle(message: message, concurrent: concurrent)
    }

    func unfoldMyAIChatMode(rootMessage: Message, localDataMaxPosition: Int32? = nil) {
        let info = MyAIChatModeThreadInfo()
        info.unfoldedMaxPosition = max(Self.COUNT_PER_PAGE_OF_MY_AI_CHAT_MODE, localDataMaxPosition ?? -1)
        info.rootMessagePosition = rootMessage.position
        unfoldedMyAIChatModeThread[rootMessage.aiChatModeID] = info
    }

    func foldMyAIChatMode(aiChatModeID: Int64) {
        unfoldedMyAIChatModeThread[aiChatModeID]?.unfoldedMaxPosition = 0
        guard let firstIndex = getFirstUnfoldMyAIChatModeCellVMIndex(aiChatModeId: aiChatModeID),
              let lastIndex = getLastUnfoldMyAIChatModeBottomLineVMIndex(aiChatModeId: aiChatModeID),
              let range = Range(.init(location: firstIndex + 1, length: lastIndex - firstIndex)) else { return }
        self.cellViewModels.removeSubrange(range)
    }

    func loadMoreMyAIChatMode(aiChatModeID: Int64) -> Int32 {
        guard let currentMaxPosition = unfoldedMyAIChatModeThread[aiChatModeID]?.currentMaxThreadPosition else { return 0 }
        unfoldedMyAIChatModeThread[aiChatModeID]?.unfoldedMaxPosition = currentMaxPosition + Self.COUNT_PER_PAGE_OF_MY_AI_CHAT_MODE + 1
        return currentMaxPosition
    }

    func updateUnfoldMyAIChatModeBottomLine(aiChatModeId: Int64, showViewMore: Bool) {
        if let vm = self.cellViewModels.last(where: { element in
            if let vm = element as? AIChatModeBottomLineCellViewModel,
               vm.aiChatModeId == aiChatModeId {
                return true
            }
            return false
        }) as? AIChatModeBottomLineCellViewModel {
            vm.successLoadMore(hasMore: showViewMore)
        }
    }

    func onFoldMyAIChatModeThreadSuccess(aiChatModeId: Int64) {
        if let vm = self.cellViewModels.first(where: { element in
            if let vm = element as? AIChatModeFoldMessageCellViewModel,
               vm.message.aiChatModeID == aiChatModeId {
                return true
            }
            return false
        }) as? AIChatModeFoldMessageCellViewModel {
            vm.foldSuccess()
        }
    }

    func onUnfoldMyAIChatModeThreadSuccess(aiChatModeId: Int64) {
        if let vm = self.cellViewModels.first(where: { element in
            if let vm = element as? AIChatModeFoldMessageCellViewModel,
               vm.message.aiChatModeID == aiChatModeId {
                return true
            }
            return false
        }) as? AIChatModeFoldMessageCellViewModel {
            vm.unfoldSuccess()
        }
    }

    //分会场消息在主会场展开
    func tailAppendThreadMessagesFor(myAIChatModeId: Int64, messages: [Message],
                                     threadPositionTotalRange: (minPostion: Int32, maxPostion: Int32)?,
                                     concurrent: (Int, (Int) -> Void) -> Void) -> HeadTailAppendResult {
        logger.info("chatTrace ChatMsgDS handleMessagesFor myAIChatModeId:\(myAIChatModeId) chatId:\(self.chatId)")
        guard let info = unfoldedMyAIChatModeThread[myAIChatModeId],
              let threadPositionTotalRange = threadPositionTotalRange,
              threadPositionTotalRange.minPostion <= info.currentMaxThreadPosition + 1,
              threadPositionTotalRange.maxPostion >= info.currentMaxThreadPosition else {
                logger.info("chatTrace ChatMsgDS handleMessagesFor myAIChatModeId:\(myAIChatModeId) chatId:\(self.chatId) no valid section")
                return .none
        }
        let showMessages = messages.filter { (msg) -> Bool in
            if !self.shouldShowMessage(msg) {
                return false
            }
            if msg.aiChatModeID != myAIChatModeId {
                return false
            }
            if msg.threadPosition > info.currentMaxThreadPosition {
                return true
            }
            return false
        }
        unfoldedMyAIChatModeThread[myAIChatModeId]?.currentMaxThreadPosition = threadPositionTotalRange.maxPostion
        if showMessages.isEmpty {
            logger.info("chatTrace ChatMsgDS tailAppend showMessages empty: \(self.chatId)")
            return .none
        }
        var types: [CellVMType] = []
        if let lastConfig = lastConfigTupleOf(aiChatModeId: myAIChatModeId) {
            let lastVM = lastConfig.1
            var prevMessage = lastVM.message
            for index in 0..<showMessages.count {
                let curMessage = showMessages[index]
                types += self.processMessagesCellVMType(prev: prevMessage, cur: curMessage)
                prevMessage = showMessages[index]
            }
            let config = lastVM.cellConfig
            let lastType: CellVMType = .message(lastVM.message, self.myAIMainChatProcessor.getCellDependency(isSingle: config.isSingle,
                                                                                                             changeTopCorner: config.changeTopCorner,
                                                                                                             changeBottomCorner: config.changeBottomCorner))
            types.insert(lastType, at: 0)
            types = self.processTypes(types)
            self.update(cellVM: lastVM, cellConfig: types.removeFirst().chatCellConfig)
            // 回复消息插入到对应折叠系统消息后面
            if let index = getLastUnfoldMyAIChatModeMessageCellVMIndex(aiChatModeId: myAIChatModeId) {
                self.cellViewModels.insert(contentsOf: concurrentProcess(types: types, concurrent: concurrent), at: index + 1)
            } else {
                assertionFailure("index not found")
            }
        } else {
            // 之前该分会话一个消息都没有
            replaceForUnfoldRegion(aiChatModeId: myAIChatModeId, messages: messages, concurrent: concurrent)
        }
        return .hasMoreMessages
    }

    private func appendForUnfoldRegion(newMessage: Message) {
        if let lastConfig = lastConfigTupleOf(aiChatModeId: newMessage.aiChatModeID) {
            // 最后一条消息需要判断是否与新消息相连，更新圆角
            let lastVM = lastConfig.1
            let lastMessage = lastVM.message
            let lastType: CellVMType = .message(
                lastMessage,
                ChatCellMetaModelDependency(
                    contentPadding: contentPadding,
                    contentPreferMaxWidth: { [weak self] message in
                        return self?.container?.getContentPreferMaxWidth(message) ?? 0
                    },
                    config: lastVM.cellConfig
                )
            )
            var types = self.processMessagesCellVMType(prev: lastMessage, cur: newMessage)
            types.insert(lastType, at: 0)
            types = self.processTypes(types)
            self.update(cellVM: lastVM, cellConfig: types.removeFirst().chatCellConfig)
            let vms = types.map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) }
            if let index = getLastUnfoldMyAIChatModeMessageCellVMIndex(aiChatModeId: newMessage.aiChatModeID) {
                self.cellViewModels.insert(contentsOf: vms, at: index + 1)
                if let info = self.unfoldedMyAIChatModeThread[newMessage.aiChatModeID],
                    newMessage.threadPosition > info.currentMaxThreadPosition {
                    info.currentMaxThreadPosition = newMessage.threadPosition
                }
            }
        } else {
            self.logger.error("lastConfigTuple not found, aiChatModeId: \(newMessage.aiChatModeID)")
            assertionFailure("lastConfigTuple not found")
        }
    }

    private func processFirstCellVMTypeForUnfoldRegion(message: Message) -> [CellVMType] {
        var types: [CellVMType] = []
        //主会话内的分会话消息展开后 首条消息上方不要时间线了
        types.append(.message(message, self.myAIMainChatProcessor.getCellDependency(isSingle: true, changeTopCorner: false, changeBottomCorner: false)))
        return types
    }

    private func replaceForUnfoldRegion(aiChatModeId: Int64, messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) {
        let showMessages = messages.filter({ self.shouldShowMessage($0) })
        logger.info("chatTrace ChatMsgDS replaceForUnfoldRegion showMessagesCount \(aiChatModeId) \(showMessages.count)")
        var types: [CellVMType] = []
        let cur = showMessages[0]
        types.append(contentsOf: processFirstCellVMTypeForUnfoldRegion(message: cur))
        for index in 1..<showMessages.count {
            let prevMessage = showMessages[index - 1]
            let curMessage = showMessages[index]
            types += self.processMessagesCellVMType(prev: prevMessage,
                                                    cur: curMessage)
        }

        // 替换数据源要考虑Types重新生成
        types = self.processTypes(types)
        if let rootMessage = showMessages.first {
            types.append(.aiChatModeBottomLine(rootMessage: rootMessage))
        }
        if let index = getFirstUnfoldMyAIChatModeCellVMIndex(aiChatModeId: aiChatModeId) {
            self.cellViewModels.insert(contentsOf: concurrentProcess(types: types, concurrent: concurrent), at: index + 1)
        } else {
            assertionFailure("index not found")
        }
    }

    private func lastConfigTupleOf(aiChatModeId: Int64) -> (Int, HasCellConfig)? {
        if let index = getLastUnfoldMyAIChatModeMessageCellVMIndex(aiChatModeId: aiChatModeId),
           let hasCellConfig = cellViewModels[index] as? HasCellConfig {
            return (index, hasCellConfig)
        }
        return nil
    }

    private func getFirstUnfoldMyAIChatModeCellVMIndex(aiChatModeId: Int64) -> Int? {
        return self.cellViewModels.firstIndex { element in
            if let vm = element as? AIChatModeFoldMessageCellViewModel {
                return vm.message.aiChatModeID == aiChatModeId
            }
            return false
        }
    }

    private func getLastUnfoldMyAIChatModeMessageCellVMIndex(aiChatModeId: Int64) -> Int? {
        return self.cellViewModels.lastIndex { element in
            if let vm = element as? ChatMessageCellViewModel,
               vm.message.aiChatModeID == aiChatModeId {
                return true
            }
            return false
        }
    }

    private func getLastUnfoldMyAIChatModeBottomLineVMIndex(aiChatModeId: Int64) -> Int? {
        return self.cellViewModels.lastIndex { element in
            if let vm = element as? AIChatModeBottomLineCellViewModel,
               vm.aiChatModeId == aiChatModeId {
                return true
            }
            return false
        }
    }

    func getMyAIChatModeThreadInfo(aiChatModeId: Int64) -> MyAIChatModeThreadInfo? {
        guard let info = self.unfoldedMyAIChatModeThread[aiChatModeId] else {
            return nil
        }
        return info
    }
}
