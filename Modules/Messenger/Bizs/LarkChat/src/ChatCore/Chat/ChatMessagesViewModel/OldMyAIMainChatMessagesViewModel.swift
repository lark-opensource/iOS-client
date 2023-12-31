//
//  OldMyAIMainChatMessagesViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2023/12/6.
//

import Foundation
import ThreadSafeDataStructure
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxCocoa

//@贾潇：MyAI新主会话（历史话题继续聊需求）预计跟版7.10。不包含「历史话题继续聊」需求功能的即OldMyAIMainChatMessagesViewModel。
//由于「历史话题继续聊」需求是个BreakChange，所以分成立新旧两套ViewModel。
//虽然这个需求还没有上，但先把基类抽出来，避免后续开发过程中冲突太多。
class OldMyAIMainChatMessagesViewModel: MyAIMainChatBaseMessagesViewModel {
    /// 更新分会场的根消息
    var myAIChatModeThreadRootMessagesCache: SafeDictionary<Int64, Message> = [:] + .readWriteLock
    func updateMyAIChatModeThreadRootMessagesCacheIfNeed(_ message: Message) {
        if message.threadPosition == -1,
           message.aiChatModeID > 0 {
            myAIChatModeThreadRootMessagesCache[message.aiChatModeID] = message
        }
    }
    func updateMyAIChatModeThreadRootMessagesCacheIfNeed(_ messages: [Message]) {
        for message in messages {
            updateMyAIChatModeThreadRootMessagesCacheIfNeed(message)
        }
    }

    /// 收到新消息push/pull时端上的处理
    override func didReceiveMessages(_ messages: [Message]) {
        super.didReceiveMessages(messages)
        updateMyAIChatModeThreadRootMessagesCacheIfNeed(messages)
    }

    /// key：aiChatModeID, value：本地所有的回复消息
    var myAIChatModeThreadReplyMessagesCache: SafeDictionary<Int64, SafeArray<Message>> = [:] + .readWriteLock
    func updateMyAIChatModeThreadReplyMessagesCacheIfNeed(_ messages: [Message], chatModeId: Int64) {
        if let array = myAIChatModeThreadReplyMessagesCache[chatModeId] {
            for message in messages {
                if let index = array.firstIndex(where: { element in
                    element.id == message.id
                }) {
                    array[index] = message
                } else {
                    array.append(message)
                }
            }
        } else {
            let array: SafeArray<Message> = messages + .readWriteLock
            myAIChatModeThreadReplyMessagesCache[chatModeId] = array
        }
        myAIChatModeThreadReplyMessagesCache[chatModeId]?.sort(by: { $0.threadPosition < $1.threadPosition })
    }

    override func handlePushMessages(messages: [Message]) {
        let newMessages = messages.map({
            if $0.aiChatModeID > 0 {
                self.preprocessChatModeMessageInMyAIMainChat(message: $0)
            }
            return $0
        })
        super.handlePushMessages(messages: newMessages)
    }

    override func publishReceiveMessageSending(message: Message) {
        if let datasource = self.myAIOnboardCardDatasource,
           message.localStatus != .success && message.position >= anchorMessageInfo?.1 ?? -1,
           let pageService = try? context.userResolver.resolve(type: MyAIPageService.self) {
            self.dependency.chatKeyPointTracker.beforePublishOnScreenSignal(cid: message.cid, messageId: message.id)
            if message.localStatus == .fail {
                // 消息可能直接进入失败态
                self.dependency.chatKeyPointTracker.sendMessageFinish(cid: message.cid, messageId: message.id,
                                                                      success: false, page: ChatMessagesViewController.pageName,
                                                                      isCheckExitChat: false)
            }
            pageService.myAIMainChatConfig.onBoardInfoSubject.accept(.notShow(newMessage: message))
        }
        super.publishReceiveMessageSending(message: message)
    }
    // nolint: duplicated_code
    override func publishReceiveNewMessage(message: Message) {
        guard let pageService = try? context.userResolver.resolve(type: MyAIPageService.self) else {
            return
        }
        var onlyReload: Bool = false
        switch pageService.myAIMainChatConfig.onBoardInfoSubject.value {
        case .success, .willDismiss:
            onlyReload = true
        default: break
        }
        /// 接收到新消息push时，消息为新话题开始，且消息position比上一个清屏置顶的message position大，则将onboard卡片隐藏
        if message.isAiSessionFirstMsg,
           let datasource = self.myAIOnboardCardDatasource,
           (message.id == anchorMessageInfo?.0 ?? "" && message.position == anchorMessageInfo?.1) ||
            (message.localStatus != .success && message.position >= anchorMessageInfo?.1 ?? -1) {
            pageService.myAIMainChatConfig.onBoardInfoSubject.accept(.notShow(newMessage: message))
            Self.logger.info("MYAI ChatTrace change onboardStatus to notshow \(self.chatId), newAnchorPosition: \(message.position), newAnchorMsgId \(message.id), ")
            return
        }
        /// 如果onboard卡片展示中，接收到新的消息push不触发新消息上屏的滚滚底，只将列表刷新避免闪烁
        if onlyReload {
            Self.logger.info("MYAI ChatTrace refreshTable instead of publishing NewMessage")
            self.publish(.refreshTable)
            return
        }
        super.publishReceiveNewMessage(message: message)
    }
    // enable-lint: duplicated_code

    override func publish(_ type: ChatTableRefreshType, outOfQueue: Bool = false) {
        guard let messageDatasource = myAIMainChatMessageDatasource else { return }
        var dataUpdate: Bool = true
        switch type {
        case .updateFooterView,
             .updateHeaderView,
             .scrollTo:
            dataUpdate = false
        default:
            break
        }
        Self.logger.info("ChatTrace tableRefreshPublish onNext \(self.chatId) \(type.describ) \(outOfQueue)")
        self.tableRefreshPublish.onNext((type, newDatas: dataUpdate ? messageDatasource.getUIData() : nil, outOfQueue: outOfQueue))
    }
}

extension OldMyAIMainChatMessagesViewModel: MyAIChatModeMessagesManager {
    private var myAIMainChatMessageDatasource: MyAIMainChatMessagesDatasource? {
        return messageDatasource as? MyAIMainChatMessagesDatasource
    }
    public func unfoldMyAIChatModeThread(chatModeId: Int64, threadId: String) {
        guard let rootMessage = self.myAIChatModeThreadRootMessagesCache[chatModeId] else { return }
        // 如果之前已经展开过x条，则再次展开时先只展示之前收起的x条消息
        if let array = self.myAIChatModeThreadReplyMessagesCache[chatModeId],
           !array.isEmpty {
            var messages = array.getImmutableCopy()
            let minPostion: Int32 = -1
            let maxPosition: Int32 = messages.last?.threadPosition ?? -1
            myAIMainChatMessageDatasource?.unfoldMyAIChatMode(rootMessage: rootMessage, localDataMaxPosition: maxPosition)
            // 插入根消息
            if let rootMessage = self.myAIChatModeThreadRootMessagesCache[chatModeId] {
                messages.insert(rootMessage, at: 0)
            }
            self.queueManager.addDataProcess { [weak self] in
                guard let `self` = self else { return }
                self.handleMyAIChatModeMessages(chatModeId: chatModeId, messages: messages, threadPositionTotalRange: (minPostion, maxPosition))
            }
        } else {
            myAIMainChatMessageDatasource?.unfoldMyAIChatMode(rootMessage: rootMessage, localDataMaxPosition: nil)
            fetchMyAIChatModeMessages(chatModeId: chatModeId, theadId: threadId)
        }
    }

    public func foldMyAIChatModeThread(chatModeId: Int64) {
        myAIMainChatMessageDatasource?.foldMyAIChatMode(aiChatModeID: chatModeId)
        myAIMainChatMessageDatasource?.onFoldMyAIChatModeThreadSuccess(aiChatModeId: chatModeId)
        self.publish(.loadMoreNewMessages(hasFooter: self.hasMoreNewMessages()))
    }

    public func loadMoreMyAIChatModeThread(chatModeId: Int64, threadId: String) {
        guard let currentMaxPosition = myAIMainChatMessageDatasource?.loadMoreMyAIChatMode(aiChatModeID: chatModeId) else { return }
        fetchMyAIChatModeMessages(chatModeId: chatModeId, theadId: threadId, afterPosition: currentMaxPosition)
    }

    func fetchMyAIChatModeMessages(chatModeId: Int64, theadId: String, afterPosition: Int32 = -1) {
        self.dependency.threadAPI?.fetchThreadMessages(
            threadId: theadId,
            scene: .after(after: afterPosition),
            redundancyCount: 0,
            count: MyAIMainChatMessagesDatasource.COUNT_PER_PAGE_OF_MY_AI_CHAT_MODE
        ).compactMap({ [weak self] (result) -> (messages: [Message], totalRange: (Int32, Int32)) in
            var newMessages = result.successMessages
            self?.updateMyAIChatModeThreadReplyMessagesCacheIfNeed(newMessages, chatModeId: chatModeId)
            var newTotalRange = result.successMessagesTotalRange ?? (-1, -1)
            if afterPosition == -1,
               let rootMessage = self?.myAIChatModeThreadRootMessagesCache[chatModeId] {
                newMessages.insert(rootMessage, at: 0)
                newTotalRange.0 = -1
            }
            return (newMessages, newTotalRange)
        }).observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, totalRange) in
                guard let `self` = self else {
                    return
                }
                self.handleMyAIChatModeMessages(chatModeId: chatModeId, messages: messages, threadPositionTotalRange: totalRange)
            }, onError: { [weak self] _ in
                self?.myAIMainChatMessageDatasource?.updateUnfoldMyAIChatModeBottomLine(aiChatModeId: chatModeId,
                                                                           showViewMore: true)
            }).disposed(by: self.disposeBag)
    }

    func handleMyAIChatModeMessages(chatModeId: Int64, messages: [Message], threadPositionTotalRange: (Int32, Int32)) {
        myAIMainChatMessageDatasource?.onUnfoldMyAIChatModeThreadSuccess(aiChatModeId: chatModeId)
        for message in messages {
            self.preprocessChatModeMessageInMyAIMainChat(message: message)
        }
        // 判断是否存在更多的回复消息
        var hasMore = false
        if let rootMessage = self.myAIChatModeThreadRootMessagesCache[chatModeId],
           let lastMessage = messages.last,
           rootMessage.replyInThreadLastVisibleMessagePosition > lastMessage.threadPosition {
            hasMore = true
        }
        // 数据源尾部插入回复消息
        let result = self.myAIMainChatMessageDatasource?.tailAppendThreadMessagesFor(myAIChatModeId: chatModeId,
                                                                                     messages: messages,
                                                                                     threadPositionTotalRange: threadPositionTotalRange,
                                                                                     concurrent: self.concurrentHandler)
        if result != .none {
            self.publish(.loadMoreNewMessages(hasFooter: self.hasMoreNewMessages()))
        } else {
            ChatMessagesViewModel.logger.error("chatTrace \(self.chat.id) no valid new message")
        }
        self.myAIMainChatMessageDatasource?.updateUnfoldMyAIChatModeBottomLine(aiChatModeId: chatModeId,
                                                                               showViewMore: hasMore)
    }

    // 预处理ai主会场中的分会话消息
    func preprocessChatModeMessageInMyAIMainChat(message: Message) {
        message.rootMessage = nil
        message.rootId = ""
        message.parentMessage = nil
        message.parentId = ""
        message.threadMessageType = .unknownThreadMessage
    }
}
