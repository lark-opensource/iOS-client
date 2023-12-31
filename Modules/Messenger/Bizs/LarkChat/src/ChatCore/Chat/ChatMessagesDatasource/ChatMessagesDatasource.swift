//
//  ChatMessagesDatasource.swift
//  LarkChat
//
//  Created by zc09v on 2018/3/26.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessageBase
import LarkMessageCore
import LarkFeatureGating
import LarkTracing
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface
import RustPB

public protocol HasCellConfig: AnyObject, HasMessage {
    var cellConfig: ChatCellConfig { get }
}

struct ChatMessageMetaModel: CellMetaModel {
    let message: Message
    var getChat: () -> Chat

    init(message: Message, getChat: @escaping () -> Chat) {
        self.message = message
        self.getChat = getChat
    }
}

enum CellVMType {
    case message(Message, ChatCellMetaModelDependency)
    case mockSystemMessage(MyAIMockSystemCellConfigType)
    case mockToolSystemMessage(toolIds: [String])
    case aiChatModeFoldMessage(rootMessage: Message)
    case aiChatModeBottomLine(rootMessage: Message)
    /// 消息创建时间
    case time(TimeInterval)
    /// 消息创建日期
    case date(TimeInterval)
    /// 新消息线
    case sign
    /// 新消息线 + 时间
    case signDate(TimeInterval)
    /// 新功能介绍
    case featureIntroduction(copyWriting: String, hasHeader: Bool)
    /// 消息最上面的提示信息
    case topMsgTip(tip: String)
    /// AI主会场onboard卡片
    case aiOnboardCard(info: MyAIOnboardInfo)

    func transformToVM(factory: ChatCellViewModelFactory, hightlightinfo: HighlightMessageInfo?, getChat: @escaping () -> Chat) -> ChatCellViewModel {
        switch self {
        case .message(let message, let dependency):
            let vm = factory.create(with: ChatMessageMetaModel(message: message, getChat: getChat),
                                    metaModelDependency: dependency)
            //判断是否高亮
            if let hightlightinfo = hightlightinfo {
                if let messageId = hightlightinfo.messageId {
                    (vm as? ChatMessageCellViewModel)?.isHightlight = (hightlightinfo.position == message.position && (messageId == message.id || messageId == message.cid))
                } else {
                    var isHightlightPosition = hightlightinfo.position == message.position
                    if message.isFoldRootMessage,
                       let detail = message.foldDetailInfo,
                       hightlightinfo.position >= detail.rootMessagePosition,
                       hightlightinfo.position <= detail.lastMessagePosition {
                        isHightlightPosition = true
                    }
                    (vm as? ChatMessageCellViewModel)?.isHightlight = (isHightlightPosition && message.localStatus == .success)
                }
            }
            return vm
        case .time(let time):
            return factory.create(time: time)
        case .date(let date):
            return factory.create(date: date)
        case .sign:
            return factory.createSign()
        case .signDate(let date):
            return factory.createSign(signDate: date)
        case .featureIntroduction(let copyWriting, let hasHeader):
            return factory.createFeatureIntroduction(copyWriting: copyWriting, hasHeader: hasHeader)
        case .topMsgTip(let tip):
            return factory.createTopMsgTip(tip: tip)
        case .mockSystemMessage(let config):
            let vm = MyAIMockSystemCellViewModel<ChatContext>(context: factory.context,
                                                              config: config)
            return vm
        case .mockToolSystemMessage(let toolIds):
            let vm = MyAIMockToolSystemCellViewModel<ChatContext>(metaModel: MyAIMockToolMetaModel(getChat: getChat),
                                                                  context: factory.context,
                                                                  toolIds: toolIds)
            return vm
        case .aiChatModeFoldMessage(let rootMessage):
            return AIChatModeFoldMessageCellViewModel(rootMessage: rootMessage, context: factory.context)
        case .aiChatModeBottomLine(let rootMessage):
            let vm = AIChatModeBottomLineCellViewModel(rootMessage: rootMessage, context: factory.context)
            return vm
        case .aiOnboardCard(let info):
            return AIChatOnboardCardCellViewModel(context: factory.context, info: info, chat: getChat())
        }
    }

    var chatCellConfig: ChatCellConfig? {
        switch self {
        case .message(_, let dependency):
            return dependency.config
        case .time, .date, .sign, .signDate, .featureIntroduction, .topMsgTip, .mockSystemMessage, .mockToolSystemMessage, .aiChatModeBottomLine, .aiChatModeFoldMessage, .aiOnboardCard:
            return nil
        }
    }
}

struct HighlightMessageInfo {
    //如果只提供了position，默认只匹配真消息(假消息会和真消息position相同)
    let position: Int32
    let messageId: String?
    init(position: Int32, messageId: String? = nil) {
        self.position = position
        self.messageId = messageId
    }
}

/// 基础能力，对外暴露：insert、（head tail）append、update、receivePush、replace（reset）、delete、merge([], [])
/// 扩展能力，通过模块化扩展。
class ChatMessagesDatasource: PageContextWrapper, BaseMessageDatasource {
    var pageContext: LarkMessageBase.PageContext { vmFactory.pageContext }

    private(set) var hightlightInfo: HighlightMessageInfo?
    private static let logger = Logger.log(ChatMessagesDatasource.self, category: "Business.Chat")

    private typealias MessageTuple = (Int, HasCellConfig)

    private var missedMessagePositions: [Int32] = []
    private var isMessageBurned: (Message) -> Bool

    var cellViewModels: [ChatCellViewModel] = []

    let chat: () -> Chat
    let chatId: String //仅用与日志和埋点
    let vmFactory: ChatCellViewModelFactory

    @PageContext.InjectedLazy private var translateService: NormalTranslateService?

    private var messageCellProcessor: any MessageDatasourceProcessor

    private(set) var minMessagePosition: Int32
    private(set) var maxMessagePosition: Int32

    /// 初始cell配置
    var cellConfig: ChatCellConfig
    var readPositionBadgeCount: Int32?
    let contentPadding = ChatCellUIStaticVariable.bubblePadding

    weak var container: BaseMessageContainer?

    init(
        chat: @escaping () -> Chat,
        vmFactory: ChatCellViewModelFactory,
        minMessagePosition: Int32 = -1,
        maxMessagePosition: Int32 = -1,
        isMessageBurned: @escaping (Message) -> Bool,
        messageCellProcessor: any MessageDatasourceProcessor
    ) {
        self.chat = chat
        self.vmFactory = vmFactory
        self.minMessagePosition = minMessagePosition
        self.maxMessagePosition = maxMessagePosition
        self.isMessageBurned = isMessageBurned
        self.messageCellProcessor = messageCellProcessor
        self.chatId = self.chat().id
        self.cellConfig = ChatCellConfig()
        self.cellConfig.hasHeader = self.chat().chatter == nil
    }

    deinit {
        print("NewChat: ChatMessagesDatasource deinit")
    }

    // chat.firstMessagePosition 会话消息上边界发生改变；比如：清空聊天记录
    func adjustMinMessagePosition(concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        guard let firstMessagePosition = self.container?.firstMessagePosition else {
            Self.logger.warn("chatTrace ChatMsgDS adjustMinMessagePosition container is nil \(self.chatId)")
            return false
        }
        Self.logger.info("chatTrace ChatMsgDS adjustMinMessagePosition: \(self.chatId) \(firstMessagePosition) \(self.minMessagePosition) \(self.maxMessagePosition)")
        if firstMessagePosition < self.minMessagePosition {
            /// eg. [firstMessagePosition + 1 == self.minMessagePositio]
            /// 当前数据源上边界正好等于会话上边界，需要更新首条消息之前的内容
            self.adjustFirstMessage(concurrent: concurrent)
            return true
        }
        /// 会话中的消息全清掉
        if firstMessagePosition >= self.maxMessagePosition {
            self.minMessagePosition = firstMessagePosition
            self.maxMessagePosition = firstMessagePosition
            self.cleanDataSource()
            return true
        }

        // 获取数据源中首条依然可见的消息：position > firstMessagePosition
        if
            let firstVisibleMessageCellIndex = self.cellViewModels.firstIndex(where: { (cellViewModel) -> Bool in
                guard let message = (cellViewModel as? HasMessage)?.message else { return false }
                return message.position > firstMessagePosition
            }),
            let firstVisibleMessageViewModel = (self.cellViewModels[firstVisibleMessageCellIndex] as? HasCellConfig) {
            // 更新上边界位置
            self.minMessagePosition = firstMessagePosition + 1
            var firstTypes = self.processFirstCellVMType(message: firstVisibleMessageViewModel.message)
            if let firstType = firstTypes.last {
                let endIndex = firstTypes.count - 1
                firstTypes[endIndex] = self.processType(type: firstType, keepTopLeft: false, keepBottomLeft: true)
            }
            // 更新消息，主要是更新四周圆角
            self.update(cellVM: firstVisibleMessageViewModel, cellConfig: firstTypes.removeLast().chatCellConfig)
            // 如果firstVisibleMessageCellIndex为0，则replaceSubrange(0..<0,with:xxx)相当于insert(xxx,at:0)
            self.cellViewModels.replaceSubrange((0..<firstVisibleMessageCellIndex),
                                                with: firstTypes.map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) })
            Self.logger.info("chatTrace ChatMsgDS reset minMessagePosition success: \(self.chatId) \(self.minMessagePosition) \(firstVisibleMessageViewModel.message.id)")
            return true
        }
        // 此时属于异常情况，不进行任何处理
        return false
    }

    /// 重制数据源所有信息，包括数据、上下边界
    func reset(messages: [Message],
               totalRange: (minPostion: Int32, maxPostion: Int32)?,
               concurrent: (Int, (Int) -> Void) -> Void) {
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS minMax \(self.chatId) \(self.minMessagePosition) \(self.maxMessagePosition)")
        if let totalRange = totalRange {
            self.minMessagePosition = totalRange.minPostion
            self.maxMessagePosition = totalRange.maxPostion
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS updateRange by totalRange chatId: \(self.chatId)")
        } else {
            // 没有给定区间
            if let firstMessagePosition = self.container?.firstMessagePosition, let lastMessagePosition = self.container?.lastMessagePosition {
                self.minMessagePosition = firstMessagePosition
                self.maxMessagePosition = lastMessagePosition
                ChatMessagesDatasource.logger.warn("chatTrace ChatMsgDS updateRange by empty totalRange chatId: \(self.chatId)")
            }
        }
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS minMax afterChange \(self.chatId) \(self.minMessagePosition) \(self.maxMessagePosition)")
        self.replace(messages: messages, concurrent: concurrent)
    }

    /// 头尾插入
    func merge(messages: [Message],
               totalRange: (minPostion: Int32, maxPostion: Int32)?,
               concurrent: (Int, (Int) -> Void) -> Void) {
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS merge messages: \(self.chatId)")
        if let totalRange = totalRange,
           totalRange.minPostion >= self.minMessagePosition,
           totalRange.maxPostion <= self.maxMessagePosition {
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS merge messages: \(self.chatId) 子集不做处理")
            return
        }
        let headInsertResult = self.headAppend(messages: messages, totalRange: totalRange, concurrent: concurrent)
        let tailAppendResult = self.tailAppend(messages: messages, totalRange: totalRange, concurrent: concurrent)
        if headInsertResult != .hasMoreMessages && tailAppendResult != .hasMoreMessages {
            // 完全没有交集
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS merge messages: \(self.chatId) 没有交集，整体替换")
            self.reset(messages: messages, totalRange: totalRange, concurrent: concurrent)
        }
    }

    /// 插入消息
    func insert(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) -> Bool {
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS insertMessages: \(self.chatId)")
        let missMessages = messages.filter { (msg) -> Bool in
            return msg.position >= self.minMessagePosition && msg.position <= self.maxMessagePosition
        }
        guard !missMessages.isEmpty else {
            return false
        }
        let currentMessages = self.cellViewModels.compactMap { (cellvm) -> Message? in
            return (cellvm as? HasMessage)?.message
        }
        let mergeMessages = missMessages.lf_mergeUnique(
            array: currentMessages,
            comparable: { (msg1, msg2) -> Int in
                // 考虑假消息，如果position相同(msg1.position - msg2.position == 0)，说明currentMessages中有假消息，假消息排在后面, 返回0符合预期
                return Int(msg1.position - msg2.position)
            },
            equitable: { (msg1, msg2) -> Message? in
                if msg1.id == msg2.id {
                    if msg1.isCryptoIntermediate == false {
                        return msg1
                    } else {
                        return msg2
                    }
                } else {
                    return nil
                }
            },
            sequence: .ascending)
        self.replace(messages: mergeMessages, concurrent: concurrent)
        return true
    }

    /// 处理某一个消息的更新
    func handle(message: Message, concurrent: (Int, (Int) -> Void) -> Void) -> HandleMessageScene {
        ChatMessagesDatasource.logger.info("""
                                           chatTrace ChatMsgDS handleMsg: \(self.chatId) \(message.cid)
                                           messageid: \(message.id) foldId: \(message.foldId)
                                           \(message.position) \(self.maxMessagePosition)
                                           """)
        /// 如果折叠消息子消息 都应该直接丢弃，
        /// 但是本地如果有已经存在的 需要删除下
        if message.isFoldSubMessage {
            if let index = self.index(message: message) {
                ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS deleFoldSubMessage \(message.id) chatId:\(self.chatId)")
                self.delete(messageCellIndex: index)
                return .updateMessage
            }
            return .none
        }
        guard message.isVisible else {
            // 只有连续的不可见消息才可以更新maxMessagePosition
            if message.position == self.maxMessagePosition + 1 {
                self.maxMessagePosition = message.position
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
        if let resultScene = self.handerFoldMessage(message, concurrent: concurrent) {
            return resultScene
        }

        if message.isDeleted || isMessageBurned(message) {
            // 删除 || 密聊焚毁
            var sonChangeIndexs: [Int] = []
            sonChangeIndexs += walkerFor(parentMessage: message) { (currentParentMsg) -> Bool in
                // 没有父消息 不处理
                guard let currentParentMsg = currentParentMsg else {
                    return false
                }
                // 父消息已经是不是删除态 && 不是销毁态，处理，否则不处理(不能使用isMessageBurned判断，会有实时计算的兜底逻辑，导致currentParentMsg会命中焚毁，也就不会被更新了，此处使用isBurned做判断)
                return !currentParentMsg.isDeleted && !currentParentMsg.isBurned
            }
            if self.delete(message: message) {
                return .updateMessage
            } else {
                // 有可能被删除的消息不在数据源中，但他的子消息在，也要刷新
                return sonChangeIndexs.isEmpty ? .none : .updateMessage
            }
        } else {
            // 更新以此消息为根或父的相关消息
            walkerFor(parentMessage: message)
        }
        // 消息更新
        if let cellIndex = self.index(message: message) {
            if let messageViewModel = self.cellViewModels[cellIndex] as? ChatMessageCellViewModel {
                /// 撤回消息要变成系统消息，单独处理。Thread模式不受此影响
                if pageContext.isNewRecallEnable, message.isRecalled, !message.showInThreadModeStyle {
                    recalled(message: message, cellVMIndex: cellIndex)
                    return .updateMessage
                }
                let currentMessage = messageViewModel.message
                //从发送态更新到成功态
                if (currentMessage.localStatus == .process || currentMessage.localStatus == .fakeSuccess || currentMessage.cid == currentMessage.id), message.localStatus == .success {
                    LarkTracingUtil.sendMessageStartChildSpanByPName(spanName: LarkTracingUtil.handSendSuccessMessage, parentName: LarkTracingUtil.sendMessage, cid: message.cid)
                    // 发送状态变成功状态
                    messageViewModel.update(metaModel: ChatMessageMetaModel(message: message,
                                                                          getChat: chat))
                    // 位置不变，但lastMsgPos还是要更新的
                    if message.position > self.maxMessagePosition {
                        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS missedMessages: \(self.chatId) \(message.id) \(message.position) \(self.maxMessagePosition)")
                        /*有些情况下(网不好)，当消息被发送后，服务器返回的实际pos与之前的quasimsgPos之间可能会有n个其他消息，
                         因自己发送的消息必须上屏，不做连续性检测(maxMessagePosition会被更新),这样会导致中间会丢消息，且这些消息后面push过来后因不符合连续性检测，
                         无法上屏,把这些消息记录下*/
                        for pos in self.maxMessagePosition + 1 ..< message.position {
                            self.missedMessagePositions.append(pos)
                        }
                        self.maxMessagePosition = message.position
                    }

                    LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.handSendSuccessMessage, cid: message.cid)
                    if currentMessage.localStatus == .success {
                        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS updateAlreadySuccess: \(self.chatId) \(message.id) \(message.cid) \(message.position)")
                        return .updateMessage
                    } else {
                        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS sendSuccessByPush: \(self.chatId) \(message.id) \(message.cid) \(message.position)")
                        return .messageSendSuccess
                    }
                } else {
                    ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS update: \(self.chatId) \(message.id) \(message.cid) \(message.position)")
                    // 用于解决以下badcase：
                    // 当消息A展示在界面上时，会把A丢给SDK进行自动检测逻辑，假如SDK告诉我们A需要loading，则消息A在界面上将展示出loading态，
                    // 此时如果A被reaction等，则有pushMessage过来一个A'（A'.id = A.id），因为translateState是一个本地状态，所以A'并不会维持loading态，所以此时消息A在界面上将停止loading，
                    // 如果翻译请求耗时很久比如2s，那么会在2s后收到翻译push，此时消息A会展示出译文。
                    // 基于以上的分析，用户将会看到一个明显的bug：loading态停止2s后译文才展示出来。
                    //
                    // 解决方法：如果旧消息在loading那么我们在pushMessage更新消息时维持loading态，此loading态的停止由翻译push完全控制，
                    // 翻译push最后肯定会调用到update(messageIds...)去停止loading，所以此方法可行。
                    message.translateState = (currentMessage.translateState == .translating) ? .translating : message.translateState
                    if !message.isCryptoIntermediate {
                        messageViewModel.update(metaModel: ChatMessageMetaModel(message: message, getChat: chat))
                        if message.localStatus == .fail {
                            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS msg sendFail: \(self.chatId) \(message.cid) \(message.id) \(message.position) \(self.maxMessagePosition)")
                            return .messageSendFail
                        } else {
                            /// 部分情况下需要重新rebuildCellVM 比如: 消息->创建话题 消息->折叠卡片 不需要再跟其他消息合并
                            let isCreateThread = currentMessage.threadMessageType == .unknownThreadMessage &&
                            message.threadMessageType != .unknownThreadMessage
                            && message.aiChatModeID == 0
                            let isCreateFoldCard = !currentMessage.isFoldRootMessage && message.isFoldRootMessage
                            if isCreateThread || isCreateFoldCard {
                                self.rebuildCellVM(message: message, cellIndex: cellIndex, concurrent: concurrent)
                            }
                        }
                    } else {
                        ChatMessagesDatasource.logger.info(
                            """
                            chatTrace ChatMsgDS is crypto intermediate:
                            \(self.chatId)
                            \(message.id)
                            \(message.position)
                            \(message.burnLife)
                            \(message.burnTime)
                            \(message.isCryptoIntermediate)
                            """
                        )
                        return .none
                    }
                    return .updateMessage
                }
            } else if let systemViewModel = self.cellViewModels[cellIndex] as? ChatSystemCellViewModel {
                ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS update system: \(self.chatId) \(message.id) \(message.cid) \(message.position)")
                systemViewModel.update(metaModel: ChatMessageMetaModel(message: message, getChat: chat))
                return .updateMessage
            } else if let redPacketSystemViewModel = self.cellViewModels[cellIndex] as? ChatRedPacketSystemCellViewModel {
                ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS update redPacket Syste: \(self.chatId) \(message.id) \(message.cid) \(message.position)")
                redPacketSystemViewModel.update(metaModel: ChatMessageMetaModel(message: message, getChat: chat))
                return .updateMessage
            } else if let myAIToolSystemViewModel = self.cellViewModels[cellIndex] as? ChatAIToolSystemCellViewModel {
                ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS update myAITool Syste: \(self.chatId) \(message.id) \(message.cid) \(message.position)")
                myAIToolSystemViewModel.update(metaModel: ChatMessageMetaModel(message: message, getChat: chat))
                return .updateMessage
            }
        }

        // 新消息
        if let handledResult = handleNewMessageAhead(message) {
            return handledResult
        } else if message.position == self.maxMessagePosition + 1 {
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS handle newMsg: \(self.chatId) \(message.id) \(message.position)")
            self.append(newMessage: message)
            return .newMessage
        } else if let missedIndex = missedMessagePositions.firstIndex(of: message.position) {
            missedMessagePositions.remove(at: missedIndex)
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS handle missedMessage: \(self.chatId) \(message.id) \(message.position)")
            self.append(newMessage: message)
            return .newMessage
        } else if message.localStatus != .success && self.index(cid: message.cid) == nil {
            LarkTracingUtil.sendMessageStartChildSpanByPName(spanName: LarkTracingUtil.handOnScreenMessage, parentName: LarkTracingUtil.messageOnScreen, cid: message.cid)
            // 新的发送态消息(因为时序和引用问题，发的新消息可能直接跳过发送态，直接进入失败态)
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS handle process quasimsg: \(self.chatId) \(message.cid)  \(message.position)")
            self.append(newMessage: message)
            LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.handOnScreenMessage, cid: message.cid)
            return .messageSending
        } else if message.position > self.maxMessagePosition {
            // 有新消息，但新消息已经不连续了，后续消息都不会接收
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS handle discontinuous newMsg: \(self.chatId) \(message.id) \(message.position)")
            return .none
        } else if message.position == self.maxMessagePosition && message.isEphemeral {
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS handle newMsg: \(self.chatId) \(message.id) \(message.position)")
            self.append(newMessage: message)
            return .newMessage
        } else {
            ChatMessagesDatasource.logger.info("""
                chatTrace ChatMsgDS have nothing to do with \(self.chatId) \
                \(message.id) \(message.position) \(self.maxMessagePosition) \
                \(message.isEphemeral)
                """)
        }
        return .none
    }

    // TODO: 后续用责任链来处理，先临时这么写 @贾潇 @冯梓耕
    func handleNewMessageAhead(_ message: Message) -> HandleMessageScene? {
        return nil
    }

    /// 前插一段数据
    func headAppend(messages: [Message],
                    totalRange: (minPostion: Int32, maxPostion: Int32)?,
                    concurrent: (Int, (Int) -> Void) -> Void) -> HeadTailAppendResult {
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS headInsertMessages: \(self.chatId)")
        guard let totalRange = totalRange,
              totalRange.minPostion <= self.minMessagePosition,
              totalRange.maxPostion >= self.minMessagePosition - 1 else {
                ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS headInsert: \(self.chatId) 未得到有效交集")
            return .none
        }
        var hasDataNeedUpdate: Bool = false
        // 去重，只留小于的
        let showMessages = messages.filter { (msg) -> Bool in
            if !shouldShowMessage(msg) {
                return false
            }
            //此处用<=:通用方法，merge函数也有调用，有可能minMessagePosition是miss消息，要处理
            //为什么要去重:可能存在时许问题，接口返回很慢，此时数据源中minMessagePosition已经变化了（走push等路径），返回的数据中就会存在重复
            //用cid去重:要考虑假消息重复的情况，也是时许问题，可能数据源中消息已经变成真消息了（id变化了），接口拉到了之前的假消息(id==cid)，就无法用id去重了。
            //且cid真/假消息都有，而且端上和服务端产生的消息，cid也都是不同的
            if msg.position <= self.minMessagePosition {
                if self.checkMessageDuplicateAndUpdateLocalStatusIfNeeded(msg) {
                    hasDataNeedUpdate = true
                    return false
                }
                return true
            }
            return false
        }
        var minMessagePositionHasChange: Bool = false
        if self.minMessagePosition != totalRange.minPostion {
            self.minMessagePosition = totalRange.minPostion
            minMessagePositionHasChange = true
        }
        if showMessages.isEmpty {
            ChatMessagesDatasource.logger.info("""
                chatTrace ChatMsgDS headInsert showMessages empty: \(self.chatId)
                hasDataNeedUpdate: \(hasDataNeedUpdate)
                minMessagePositionHasChange: \(minMessagePositionHasChange)
                minMessagePosition: \(self.minMessagePosition)
            """)
            if minMessagePositionHasChange {
                self.adjustFirstMessage(concurrent: concurrent)
            }
            return (hasDataNeedUpdate || minMessagePositionHasChange) ? .needRefresh : .none
        }
        // 新插入的消息，转换为的CellVMType
        var types: [CellVMType] = []
        let cur = showMessages[0]
        types.append(contentsOf: processFirstCellVMType(message: cur))
        for index in 1..<showMessages.count {
            let prevMessage = showMessages[index - 1]
            let curMessage = showMessages[index]
            types += self.processMessagesCellVMType(prev: prevMessage, cur: curMessage)
        }
        if
            let firstMessageCellIndex = self.cellViewModels.firstIndex(where: { $0 is HasMessage }),
            let firstMessageViewModel = self.cellViewModels[firstMessageCellIndex] as? HasMessage,
            let lastShowMessage = showMessages.last {
            // 新插入的最后消息，和现有数据源最前消息，连接处处理
            types += self.processMessagesCellVMType(prev: lastShowMessage,
                                                    cur: firstMessageViewModel.message)
            if let firstMessageViewModel = firstMessageViewModel as? HasCellConfig,
                let lastType = types.last {
                let endIndex = types.count - 1
                types[endIndex] = self.processType(type: lastType,
                                                   keepBottomLeft: firstMessageViewModel.cellConfig.changeBottomCorner)
                types = self.processTypes(types)
                // 更新现有数据源最前消息，主要是更新四周圆角
                self.update(cellVM: firstMessageViewModel, cellConfig: types.removeLast().chatCellConfig)
            } else {
                types = self.processTypes(types)
            }
            // 把新插入的CellVMType，插入到现有数据源前面
            if firstMessageCellIndex >= 1 {
                self.cellViewModels.replaceSubrange((0...firstMessageCellIndex - 1), with: concurrentProcess(types: types, concurrent: concurrent))
            } else {
                self.cellViewModels.insert(contentsOf: concurrentProcess(types: types, concurrent: concurrent), at: 0)
            }
        } else {
            // 如果现有数据源中没有任何消息，则不处理
            // 这里应该有问题：会添加多次getStickToTopCellVMType的CellVMType？但是这种情况应该不存在，因为调用headAppend说明有历史消息，所以当前数据源中应该也会有消息
            types = self.processTypes(types)
            self.cellViewModels.insert(contentsOf: concurrentProcess(types: types, concurrent: concurrent), at: 0)
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS headInsert in no messages: \(self.chatId)")
            assertionFailure("call zhaochen.09")
        }
        return .hasMoreMessages
    }

    /// 后插一段数据
    func tailAppend(messages: [Message], totalRange: (minPostion: Int32, maxPostion: Int32)?, concurrent: (Int, (Int) -> Void) -> Void) -> HeadTailAppendResult {
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS tailAppendMessages: \(self.chatId)")
        guard let totalRange = totalRange,
              totalRange.minPostion <= self.maxMessagePosition + 1,
              totalRange.maxPostion >= self.maxMessagePosition else {
                ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS tailAppend: \(self.chatId) 未得到有效交集")
                return .none
        }
        var hasDataNeedUpdate: Bool = false
        let showMessages = messages.filter { (msg) -> Bool in
            if !self.shouldShowMessage(msg) {
                return false
            }
            if msg.position >= self.maxMessagePosition {
                if self.checkMessageDuplicateAndUpdateLocalStatusIfNeeded(msg) {
                    hasDataNeedUpdate = true
                    return false
                }
                return true
            }
            return false
        }
        self.maxMessagePosition = totalRange.maxPostion
        if showMessages.isEmpty {
            ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS tailAppend showMessages empty: \(self.chatId) \(hasDataNeedUpdate)")
            return hasDataNeedUpdate ? .needRefresh : .none
        }
        var types: [CellVMType] = []
        // 现有数据源中，找到最后一条消息
        if let lastConfig = lastConfigTuple() {
            let lastVM = lastConfig.1
            var prevMessage = lastVM.message
            // 新插入的消息，转换为CellVMType
            for index in 0..<showMessages.count {
                let curMessage = showMessages[index]
                types += self.processMessagesCellVMType(prev: prevMessage, cur: curMessage)
                prevMessage = showMessages[index]
            }
            // 把现有数据源中最后一条消息也加入types中，方便处理圆角
            let config = lastVM.cellConfig
            let lastType: CellVMType = .message(lastVM.message, self.messageCellProcessor.getCellDependency(isSingle: config.isSingle,
                                                                                                            changeTopCorner: config.changeTopCorner,
                                                                                                            changeBottomCorner: config.changeBottomCorner))
            types.insert(lastType, at: 0)
            types = self.processTypes(types)
            // 更新现有数据源中最后一条消息，主要是更新圆角
            self.update(cellVM: lastVM, cellConfig: types.removeFirst().chatCellConfig)
            // 把新插入的CellVMType，追加到现有数据源后面
            self.cellViewModels.append(contentsOf: concurrentProcess(types: types, concurrent: concurrent))
        }
        // 如果是撤回消息，则不会遵循HasCellConfig，但会遵循HasMessage
        else if vmFactory.context.isNewRecallEnable,
                  let lastMessage = (self.cellViewModels.last as? HasMessage)?.message,
                  lastMessage.isRecalled {
            // 新插入的消息，转换为CellVMType
            var prevMessage = lastMessage
            for index in 0..<showMessages.count {
                let curMessage = showMessages[index]
                types += self.processMessagesCellVMType(prev: prevMessage, cur: curMessage)
                prevMessage = showMessages[index]
            }
            // 这里相比上面的if少了「把现有数据源中最后一条消息也加入types中」过程，因为撤回消息新样式不会影响之前最后一条消息的圆角
            types = self.processTypes(types)
            // 把新插入的CellVMType，追加到现有数据源后面
            self.cellViewModels.append(contentsOf: concurrentProcess(types: types, concurrent: concurrent))
        } else {
            // 之前一个消息都没有，直接替换数据源
            replace(messages: messages, concurrent: concurrent)
        }
        return .hasMoreMessages
    }

    /// 外部更新某个message的属性(有些信号不是rustpush来的，不能保证这个消息的正确性，只能明确做个别属性的替换)
    /// doUpdate: (Message) -> Message? 外部可能不决定更新
    /// NOTE: 目前系统消息不会调用该函数，暂时不做处理
    func update(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool {
        var hasChange = false
        var messageIdsForLog: String = ""
        for messageId in messageIds {
            if let index = self.index(messageId: messageId),
                let messageVM = self.cellViewModels[index] as? ChatMessageCellViewModel {
                let message = messageVM.message
                if let newMessage = doUpdate(message) {
                    walkerFor(parentMessage: newMessage)
                    messageVM.update(metaModel: ChatMessageMetaModel(message: newMessage, getChat: chat))
                    hasChange = true
                    messageIdsForLog += " \(messageId)"
                }
            }
        }
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS update messageIds \(self.chatId) \(messageIdsForLog)")
        return hasChange
    }

    /// 数据源会依次将当前所有数据依次反馈给上层，上层可根据需要更新message
    func update(original: (Message) -> Message?) -> Bool {
        var hasChange = false
        var messageIdsForLog: String = ""
        for cellVM in self.cellViewModels {
            if let messageVM = cellVM as? ChatMessageCellViewModel {
                if let newData = original(messageVM.message) {
                    messageVM.update(metaModel: ChatMessageMetaModel(message: newData, getChat: chat))
                    hasChange = true
                    messageIdsForLog += " \(newData.id)"
                }
            }
        }
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS update original \(self.chatId) \(messageIdsForLog)")
        return hasChange
    }

    /// 通过messageId找到对应index
    func index(messageId: String, positive: Bool) -> Int? {
        if positive {
            return self.cellViewModels.firstIndex { (cellVM) -> Bool in
                if let messageVM = cellVM as? HasMessage {
                    return messageVM.message.id == messageId
                }
                return false
            }
        } else {
            return self.cellViewModels.lastIndex { (cellVM) -> Bool in
                if let messageVM = cellVM as? HasMessage {
                    return messageVM.message.id == messageId
                }
                return false
            }
        }
    }
    func index(messageId: String) -> Int? {
        return index(messageId: messageId, positive: true)
    }

    func index(viewModelId: String, positive: Bool) -> Int? {
        if positive {
            return self.cellViewModels.firstIndex { (cellVM) -> Bool in
                return cellVM.id == viewModelId
            }
        } else {
            return self.cellViewModels.lastIndex { (cellVM) -> Bool in
                return cellVM.id == viewModelId
            }
        }
    }

    func index(viewModelId: String) -> Int? {
        return index(viewModelId: viewModelId, positive: true)
    }

    /// 通过cid找到对应index
    func index(cid: String) -> Int? {
        return self.cellViewModels.lastIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                return messageVM.message.cid == cid
            }
            return false
        }
    }

    /// 如果不提供messageId，只匹配成功消息的position; 否则以messageId为准进行匹配
    func index(messagePosition: Int32, messageId: String?) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                /// 当MessageId存在的时候，可能在fold区间，也需要对比一下postion
                if let messageId = messageId {
                    var isTarget = messageVM.message.id == messageId || messageVM.message.cid == messageId
                    if !isTarget,
                       self.isFoldMessageRangePostion(messagePosition,
                                                      message: messageVM.message) {
                        isTarget = true
                    }
                    return isTarget
                }
                if messageVM.message.position == messagePosition && messageVM.message.localStatus == .success {
                    return true
                }

                if self.isFoldMessageRangePostion(messagePosition, message: messageVM.message) {
                    return true
                }
            }
            return false
        }
    }
    func index(messagePosition: Int32) -> Int? {
        return self.index(messagePosition: messagePosition, messageId: nil)
    }

    /// 可以直接缓存记录状态
    func indexForNewMessageSignCell() -> Int? {
        return self.cellViewModels.firstIndex(where: { (cellViewModel) -> Bool in
            return cellViewModel is ChatSignCellViewModel || cellViewModel is ChatSignDateCellViewModel
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

    func delete(messageId: String) -> Bool {
        if let index = self.index(messageId: messageId) {
            self.delete(messageCellIndex: index)
            return true
        }
        return false
    }

    func remove(afterPosition: Int32, redundantCount: Int) {
        let index = self.cellViewModels.lastIndex { (cellVM) -> Bool in
            return (cellVM as? HasMessage)?.message.position == afterPosition
        }
        if var index = index {
            var count = 0
            let totalCount = self.cellViewModels.count
            while count < redundantCount && index < totalCount - 1 {
                index += 1
                if self.cellViewModels[index] is HasMessage {
                    count += 1
                }
            }
            if count == redundantCount, index < totalCount - 1, let message = (self.cellViewModels[index] as? HasMessage)?.message {
                //砍掉后面的cellvm
                self.cellViewModels.removeSubrange((index + 1..<self.cellViewModels.count))
                //把自己先删了
                self.delete(messageCellIndex: index)
                //再加回来，重新生成样式
                self.append(newMessage: message)
                self.maxMessagePosition = message.position
            }
            ChatMessagesDatasource.logger.info("chatTrace remove after \(self.chatId) \(self.maxMessagePosition)")
        }
    }

    //1.避免外部直接设置nil,设置nil需要调用removeHighlightInfo
    //2.该方法内里面有容错逻辑
    func setHighlightInfo(_ info: HighlightMessageInfo) {
        //个别场景再次跳转前，没有触发之前高亮背景移除(没有调用removeHighlightInfo)
        //比如直接在会话中打开一张图，点击跳转至会话(没滚动、点击列表、vc没消失)
        self.removeHighlightInfo()
        self.hightlightInfo = info
        //有些情况不会触发数据源重建，cellvm且已经在数据源中，此处需要直接进行标记
        if let index = self.index(messagePosition: info.position, messageId: info.messageId),
            let cellVM = self.cellViewModels[index] as? ChatMessageCellViewModel {
                cellVM.isHightlight = true
            if var info = self.hightlightInfo,
               cellVM.message.isFoldRootMessage,
                info.position != cellVM.message.position {
                self.hightlightInfo = HighlightMessageInfo(position: cellVM.message.position, messageId: info.messageId)
            }
        }
    }

    @discardableResult
    func removeHighlightInfo() -> Int? {
        guard let hightlightInfo = self.hightlightInfo else { return nil }
        self.hightlightInfo = nil
        guard let index = self.index(messagePosition: hightlightInfo.position, messageId: hightlightInfo.messageId) else {
            return nil
        }
        if let messageViewModel = self.cellViewModels[index] as? ChatMessageCellViewModel {
            messageViewModel.isHightlight = false
            return index
        }
        return nil
    }

    /// 检查消息是否可见
    func checkVisible(_ message: Message) -> Bool {
        //本地发的假消息不做校验
        if message.localStatus != .success {
            return true
        }
        guard message.isVisible else {
            return false
        }
        if let firstMessagePosition = self.container?.firstMessagePosition, message.position > firstMessagePosition {
            return true
        }
        /// 这里可能的情况 用户清空记录了 把前几条清空了，会导致聚合消息无法展示
        if let firstMessagePosition = self.container?.firstMessagePosition, message.isFoldRootMessage, let foldDetail = message.foldDetailInfo {
            return foldDetail.lastMessagePosition > firstMessagePosition
        }
        return false
    }

    /// 删除 / 焚毁 / 不可见消息不展示
    func shouldShowMessage(_ message: Message) -> Bool {
        if message.isDeleted || message.isFoldSubMessage { return false }
        if self.isMessageBurned(message) { return false }
        if !self.checkVisible(message) { return false }
        return true
    }
}

extension ChatMessagesDatasource {
    private func handerFoldMessage(_ message: Message, concurrent: (Int, (Int) -> Void) -> Void) -> HandleMessageScene? {
        guard message.foldId > 0, let newfoldInfo = message.foldDetailInfo else {
            return nil
        }
        /// message.foldId > 0 情况 表示是折叠跟消息，即使没有foldDetail的信息，也可以先上屏展示骨架，后续在更新UI
        let updateBlock: ((Message.FoldDetail?, Message) -> Void) = { [weak self] (foldInfo, message) in
            self?.walkerFor(parentMessage: message) { (currentParentMsg) -> Bool in
                // 没有父消息 不处理
                guard let currentParentMsg = currentParentMsg else {
                    return false
                }
                return currentParentMsg.foldId == 0
            }
            if let foldInfo = foldInfo {
                self?.deleteMessagesByPostionRange(range: (Int32(foldInfo.rootMessagePosition + 1),
                                                           Int32(foldInfo.lastMessagePosition)))
            }
        }
        if let index = self.index(message: message),
           let messageViewModel = self.cellViewModels[index] as? ChatMessageCellViewModel {
            var needUpdate = false
            if let oldInfo = messageViewModel.message.foldDetailInfo {
                if oldInfo.updateTimeMs >= newfoldInfo.updateTimeMs {
                    ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS invalid updateTimeMs chatId: \(self.chatId), foldId: \(oldInfo.foldID)")
                    return HandleMessageScene.none
                } else {
                    /// 这里如果原来foldDetail已经有了 就不需要在重新移除fold区间的消息了
                    /// 因为第一次有fold的时候 已经移除了 再来的消息有foldId所以没有问题
                    needUpdate = newfoldInfo.lastMessagePosition > oldInfo.lastMessagePosition
                }
            } else {
                needUpdate = true
            }
            updateBlock(needUpdate ? newfoldInfo : nil, message)
            /// 这里需要需要更新 maxMessagePosition
            self.maxMessagePosition = max(Int32(newfoldInfo.lastMessagePosition), self.maxMessagePosition)
            /// 如果时间 updateTimeMs 比之前的还早，说明这个foldDetail不是最新的，直接丢弃
            return nil
        }

        /// 这里如果没有的话 就需要插入fold消息, 先校验一下是否可以插入
        if newfoldInfo.lastMessagePosition >= self.minMessagePosition,
           newfoldInfo.rootMessagePosition < self.minMessagePosition {
            self.minMessagePosition = newfoldInfo.rootMessagePosition
            ChatMessagesDatasource.logger.info("chatTrace fold: \(newfoldInfo.foldID), chatId: \(self.chatId),  lastMessagePosition :\(newfoldInfo.lastMessagePosition) update minMessagePosition")
        }
        /// 这里插入fold跟消息, 是为了处理清楚记录或者折叠的跟消息被删除，需要重新插入一下
        if self.insert(messages: [message], concurrent: concurrent) {
            updateBlock(newfoldInfo, message)
            ChatMessagesDatasource.logger.info("chatTrace insert foldId: \(newfoldInfo.foldID), chatId: \(self.chatId),  lastMessagePosition :\(newfoldInfo.lastMessagePosition)")
            return .updateMessage
        }

        ChatMessagesDatasource.logger.info("""
                                           chatTrace insert foldId fail \(newfoldInfo.foldID), chatId: \(self.chatId)
                                           lastMessagePosition:\(newfoldInfo.lastMessagePosition) rootMessagePosition: \(newfoldInfo.rootMessagePosition)
                                           minMessagePosition: \(self.minMessagePosition) - maxMessagePosition: \(self.maxMessagePosition)
                                           """)
        return nil
    }

    /// 通过message找到对应index
    private func index(message: Message) -> Int? {
        return self.cellViewModels.firstIndex { (cellVM) -> Bool in
            if let content = cellVM as? HasMessage {
                if content.message.localStatus != .success || (content.message.localStatus == .success && content.message.cid == content.message.id) {
                    return content.message.cid == message.cid
                }
                return content.message.id == message.id
            }
            return false
        }
    }

    private func isFoldMessageRangePostion(_ messagePosition: Int32, message: Message) -> Bool {
        /// 如果跳转的fold区间的话 需要更新
        if message.isFoldRootMessage,
           let foldDetailInfo = message.foldDetailInfo,
           messagePosition <= foldDetailInfo.lastMessagePosition,
           messagePosition >= foldDetailInfo.rootMessagePosition {
            return true
        }
        return false
    }

    /// 替换数据源中数据
    private func replace(messages: [Message], concurrent: (Int, (Int) -> Void) -> Void) {
        let showMessages = messages.filter({ self.shouldShowMessage($0) })
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS showMessagesCount \(self.chatId) \(showMessages.count)")
        if showMessages.isEmpty {
            self.cleanDataSource()
            return
        }
        var types: [CellVMType] = []
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

    /// 修改了 cellViewModels
    private func append(newMessage: Message) {
        if let lastConfig = lastConfigTuple() {
            // 最后一条消息需要判断是否与新消息相连，更新圆角
            let lastVM = lastConfig.1
            let lastMessage = lastVM.message
            let lastType: CellVMType = .message(
                lastMessage,
                ChatCellMetaModelDependency(
                    contentPadding: contentPadding,
                    contentPreferMaxWidth: { [weak self] message in
                        assert(self?.container != nil, "please set container before use")
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
            self.cellViewModels.append(contentsOf: vms)
            if newMessage.position > self.maxMessagePosition {
                self.maxMessagePosition = newMessage.position
            }
        } else if vmFactory.context.isNewRecallEnable,
                  let lastMessage = (self.cellViewModels.last as? HasMessage)?.message,
                  lastMessage.isRecalled {
            /// 如果是撤回消息，则不会遵循HasCellConfig，但会遵循HasMessage
            Self.logger.info("chatTrace ChatMsgDS append new message when last is recalled \(self.chatId) \(newMessage.id) \(newMessage.position)")
            var types = self.processMessagesCellVMType(prev: lastMessage, cur: newMessage)
            types = self.processTypes(types)
            let vms = types.map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) }
            self.cellViewModels.append(contentsOf: vms)
        } else {
            self.cellViewModels = processFirst(message: newMessage)
            Self.logger.info("chatTrace ChatMsgDS append new message when dataSoure is empty \(self.chatId) \(newMessage.id) \(newMessage.position)")
            self.minMessagePosition = min(newMessage.position, self.minMessagePosition)
            self.maxMessagePosition = max(newMessage.position, self.maxMessagePosition)
        }
    }

    /// 返回值： false说明消息已经被删除过了，此次不用处理
    @discardableResult
    private func delete(message: Message) -> Bool {
        // 找到被删除消息的位置
        if let cellIndex = self.index(message: message) {
            self.delete(messageCellIndex: cellIndex)
            return true
        }
        return false
    }

    private func deleteMessagesByPostionRange(range: (min: Int32, max: Int32)) {
        guard range.max > range.min else {
            assertionFailure("error range")
            return
        }
        let messages = self.cellViewModels.compactMap { vm in
            if let vm = vm as? HasMessage,
               vm.message.position >= range.min && vm.message.position <= range.max,
               vm.message.localStatus == .success {
                return vm.message
            }
            return nil
        }
        Self.logger.info("chatTrace ChatMsgDS deleteMessagesByPostionRange deleMessage count -\(messages.count) --chatId: \(self.chatId)")
        messages.forEach { message in
            if self.delete(message: message) {
                Self.logger.info("chatTrace ChatMsgDS delete Message by messageid \(message.id) --chatId: \(self.chatId)")
            }
        }
    }

    private func recalled(message: Message, cellVMIndex: Int?) {
        guard let cellVMIndex = cellVMIndex ?? self.index(message: message) else {
            return
        }
        if cellVMIndex < 0 || cellVMIndex >= self.cellViewModels.count {
            return
        }
        /// 当前消息变成系统消息
        self.cellViewModels[cellVMIndex] = vmFactory.createSystemCellViewModel(
            with: ChatMessageMetaModel(message: message, getChat: chat),
            metaModelDependency: ChatCellMetaModelDependency(contentPadding: 0, contentPreferMaxWidth: { _ in 0 })
        )
        /// 如果上一个消息是气泡消息，需要更新气泡边框
        let prevIndex = cellVMIndex - 1
        if prevIndex >= 0, let prevVM = self.cellViewModels[prevIndex] as? HasCellConfig {
            var prevType: CellVMType = .message(
                prevVM.message,
                self.messageCellProcessor.getCellDependency(isSingle: prevVM.cellConfig.isSingle,
                                                            changeTopCorner: prevVM.cellConfig.changeTopCorner,
                                                            changeBottomCorner: prevVM.cellConfig.changeBottomCorner)
            )
            prevType = self.processType(type: prevType, keepTopLeft: prevVM.cellConfig.changeTopCorner)
            var prevTypes = [prevType] + self.processMessagesCellVMType(prev: prevVM.message, cur: message)
            prevTypes = self.processTypes(prevTypes)
            self.update(cellVM: prevVM, cellConfig: prevTypes.first?.chatCellConfig)
        }
        /// 如果下一个气泡是消息，则要单独处理，如果不是不需要做任何处理
        let nextIndex = cellVMIndex + 1
        if nextIndex < self.cellViewModels.count, let nextVM = self.cellViewModels[nextIndex] as? HasCellConfig {
            var nextTypes = self.processMessagesCellVMType(prev: message, cur: nextVM.message)

            /// 下面这一行仅仅是替换一下cellConfig的默认值吗？不理解
            /// TODO: @zhaochen
            if let lastType = nextTypes.last {
                let endindex = nextTypes.count - 1
                nextTypes[endindex] = self.processType(type: lastType, keepBottomLeft: nextVM.cellConfig.changeBottomCorner)
            }
            nextTypes = self.processTypes(nextTypes)
            self.update(cellVM: nextVM, cellConfig: nextTypes.removeLast().chatCellConfig)
        }
    }

    private func delete(messageCellIndex: Int) {
        var preTuple: (Int, HasMessage)?
        var nextTuple: (Int, HasMessage)?

        // 找到上一个最近的message消息
        for index in (0..<messageCellIndex).reversed() {
            let cellVM = self.cellViewModels[index]
            if let messageVM = cellVM as? HasMessage {
                preTuple = (index, messageVM)
                break
            }
        }
        // 找到下一个最近的message消息
        for index in (messageCellIndex + 1..<self.cellViewModels.count) {
            let nextMessageCell = self.cellViewModels[index]
            if let messageVM = nextMessageCell as? HasMessage {
                nextTuple = (index, messageVM)
                break
            }
        }

        if let nextTuple = nextTuple, let preTuple = preTuple {
            let preIndex = preTuple.0
            let preVM = preTuple.1

            let nextIndex = nextTuple.0
            let nextVM = nextTuple.1

            // 前后都有
            var nextTypes = self.processMessagesCellVMType(prev: preVM.message, cur: nextVM.message)
            if let preVM = preVM as? HasCellConfig {
                let preType: CellVMType = .message(preVM.message, self.messageCellProcessor.getCellDependency(isSingle: preVM.cellConfig.isSingle,
                                                                                                              changeTopCorner: preVM.cellConfig.changeTopCorner,
                                                                                                              changeBottomCorner: preVM.cellConfig.changeBottomCorner))
                nextTypes.insert(preType, at: 0)
            }
            if let lastType = nextTypes.last, let nextVM = nextVM as? HasCellConfig {
                let endindex = nextTypes.count - 1
                nextTypes[endindex] = self.processType(type: lastType, keepBottomLeft: nextVM.cellConfig.changeBottomCorner)
            }
            nextTypes = self.processTypes(nextTypes)
            /// 如果前后都是气泡类型的消息则更新
            if let preVM = preVM as? HasCellConfig {
                self.update(cellVM: preVM, cellConfig: nextTypes.removeFirst().chatCellConfig)
            }
            if let nextVM = nextVM as? HasCellConfig {
                self.update(cellVM: nextVM, cellConfig: nextTypes.removeLast().chatCellConfig)
            }

            let vms = nextTypes.map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) }
            self.cellViewModels.replaceSubrange((preIndex + 1..<nextIndex), with: vms)
        } else if let preTuple = preTuple, nextTuple == nil {
            let preIndex = preTuple.0
            let preVM = preTuple.1
            var deleteRange: Range<Int> = .init(messageCellIndex...messageCellIndex)
            // 前有后没有(messagecell)
            if let preVM = preVM as? HasCellConfig {
                /// 如果是有气泡的消息，中间一些生成的消息要都替换掉
                let config = preVM.cellConfig
                let type: CellVMType = .message(preVM.message, self.messageCellProcessor.getCellDependency(isSingle: config.isSingle,
                                                                                                           changeTopCorner: config.changeTopCorner,
                                                                                                           changeBottomCorner: false))
                self.update(cellVM: preVM, cellConfig: type.chatCellConfig)
                deleteRange = .init((preIndex + 1)...messageCellIndex)
            }
            self.cellViewModels.replaceSubrange(deleteRange, with: [])
        } else if let nextTuple = nextTuple, preTuple == nil {
            let nextIndex = nextTuple.0
            let nextVM = nextTuple.1
            // 后有前没有(messagecell)
            var firstTypes = self.processFirstCellVMType(message: nextVM.message)
            if let firstType = firstTypes.last {
                let endIndex = firstTypes.count - 1
                firstTypes[endIndex] = self.processType(type: firstType, keepTopLeft: false, keepBottomLeft: true)
            }
            self.update(cellVM: nextVM as? HasCellConfig, cellConfig: firstTypes.removeLast().chatCellConfig)
            self.cellViewModels.replaceSubrange((0..<nextIndex), with: firstTypes.map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) })
        } else {
            self.cleanDataSource()
        }
    }

    /// 虽然找到了相关的子消息，但可能也不必更新，由外部通过canUpdate的bool返回值决定,返回的message为当前子消息挂在的根/父消息
    @discardableResult
    private func walkerFor(parentMessage: Message, canUpdate: ((Message?) -> Bool)? = nil) -> [Int] {
        var changeIndexs: [Int] = []
        for (index, cellViewModel) in self.cellViewModels.enumerated() {
            if let messageVM = cellViewModel as? ChatMessageCellViewModel {
                var hasChange = false
                let message = messageVM.message
                if message.parentId == parentMessage.id, canUpdate?(message.parentMessage) ?? true {
                    message.parentMessage = parentMessage
                    hasChange = true
                }
                if message.rootId == parentMessage.id, canUpdate?(message.rootMessage) ?? true {
                    message.rootMessage = parentMessage
                    hasChange = true
                }
                if message.syncToChatThreadRootID == parentMessage.id, canUpdate?(message.syncToChatThreadRootMessage) ?? true {
                    message.syncToChatThreadRootMessage = parentMessage
                    hasChange = true
                }
                if hasChange {
                    changeIndexs.append(index)
                    messageVM.update(metaModel: ChatMessageMetaModel(message: message,
                                                                     getChat: chat))
                }
            }
        }
        return changeIndexs
    }

    private func processFirstCellVMType(message: Message) -> [CellVMType] {
        return messageCellProcessor.processBeforFirst(message: message)
    }

    private func processFirst(message: Message) -> [ChatCellViewModel] {
        let types = self.processFirstCellVMType(message: message)
        return types.map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) }
    }

    func processMessagesCellVMType(prev: Message, cur: Message) -> [CellVMType] {
        return messageCellProcessor.process(prev: prev, cur: cur)
    }

    // TODO: @赵晨 @贾潇 也应该放进Processor里
    /// 用于再次处理cellVMTypes，主要针对气泡圆角问题
    func processTypes(_ cellVMTypes: [CellVMType]) -> [CellVMType] {

        var types: [CellVMType] = []
        var nextConfig: ChatCellConfig?

        let reversedCellVMTypes = Array(cellVMTypes.reversed())
        for index in 0 ..< reversedCellVMTypes.count {
            let type = reversedCellVMTypes[index]
            switch type {
            case .message(let message, let dependency):
                var nextDependency = dependency
                if let nextConfig = nextConfig {
                    nextDependency.config.changeBottomCorner = nextConfig.changeTopCorner
                    types.append(.message(message, nextDependency))
                } else {
                    types.append(type)
                }
                nextConfig = nextDependency.config
            default:
                types.append(type)
            }
        }
        types = types.reversed()

        return types
    }

    private func processType(type: CellVMType, keepTopLeft: Bool? = nil, keepBottomLeft: Bool? = nil) -> CellVMType {
        switch type {
        case .message(let message, let dependency):
            return .message(message, self.messageCellProcessor.getCellDependency(isSingle: dependency.config.isSingle,
                                                                                 changeTopCorner: keepTopLeft ?? dependency.config.changeTopCorner,
                                                                                 changeBottomCorner: keepBottomLeft ?? dependency.config.changeBottomCorner))
        default:
            return type
        }
    }

    private func lastConfigTuple() -> (Int, HasCellConfig)? {
        if let hasCellConfig = self.cellViewModels.last as? HasCellConfig {
            return (self.cellViewModels.count - 1, hasCellConfig)
        }
        return nil
    }

    private func cleanDataSource() {
        self.cellViewModels = self.messageCellProcessor.getCleanState().map { $0.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat) }
    }

    //校验数据源中是否已存在重复数据，并尝试做发送状态更新
    private func checkMessageDuplicateAndUpdateLocalStatusIfNeeded(_ newMessage: Message) -> Bool {
        if let index = self.index(cid: newMessage.cid) {
            //如果数据源中已经有了，且状态是非成功，但接口拉回来的是成功，做下更新，rust说这个场景下可能会丢push，端上要做下更新操作
            if let messageCellVM = self.cellViewModels[index] as? ChatMessageCellViewModel,
               messageCellVM.message.localStatus != .success,
               newMessage.localStatus == .success {
                messageCellVM.update(metaModel: ChatMessageMetaModel(message: newMessage,
                                                                     getChat: chat))
                Self.logger.info("chatTrace ChatMsgDS update message in updateLocalStatusIfNeeded \(self.chatId) \(newMessage.id)")
            }
            return true
        }
        return false
    }

    func concurrentProcess(types: [CellVMType],
                           concurrent: (Int, (Int) -> Void) -> Void) -> [ChatCellViewModel] {
        let count = types.count
        var cellViewModels = [[ChatCellViewModel]](repeating: [], count: count)
        cellViewModels.withUnsafeMutableBufferPointer { (vms) -> Void in
            concurrent(count) { i in
                let type = types[i]
                vms[i] = [type.transformToVM(factory: self.vmFactory, hightlightinfo: self.hightlightInfo, getChat: chat)]
            }
        }
        return cellViewModels.flatMap { $0 }
    }

    func update(cellVM: HasCellConfig?, cellConfig: ChatCellConfig?) {
        guard let cellVM = cellVM, let cellConfig = cellConfig else {
            return
        }
        (cellVM as? ChatMessageCellViewModel)?.update(config: cellConfig)
    }

    /// 处理首条消息之前的内容
    private func adjustFirstMessage(concurrent: (Int, (Int) -> Void) -> Void) {
        ChatMessagesDatasource.logger.info("chatTrace ChatMsgDS adjust first message: \(self.chatId)")
        if let firstMessageCellIndex = self.cellViewModels.firstIndex(where: { (cellViewModel) -> Bool in
            return cellViewModel is HasMessage
        }) {
            guard let firstMessageViewModel = (self.cellViewModels[firstMessageCellIndex] as? HasCellConfig) else { return }
            var types: [CellVMType] = self.processFirstCellVMType(message: firstMessageViewModel.message)
            types.removeLast()
            if firstMessageCellIndex >= 1 {
                self.cellViewModels.replaceSubrange((0...firstMessageCellIndex - 1), with: concurrentProcess(types: types, concurrent: concurrent))
            } else {
                self.cellViewModels.insert(contentsOf: concurrentProcess(types: types, concurrent: concurrent), at: 0)
            }
            return
        }
        self.cleanDataSource()
    }

    //重新触发对应message的cellvm构建；主要是重新处理吸附等逻辑，updateMetaModel并不会处理这些
    private func rebuildCellVM(message: Message, cellIndex: Int, concurrent: (Int, (Int) -> Void) -> Void) {
        self.delete(messageCellIndex: cellIndex)
        _ = self.insert(messages: [message], concurrent: concurrent)
    }
}

extension ChatMessagesDatasource: ChatMessageDatasourceProcessorDependency {}

extension Message {
    var fromIdForUI: String {
        if let content = self.content as? SystemContent,
            let fromId = content.triggerUser?.id {
            return fromId
        }
        return self.fromId
    }
}
