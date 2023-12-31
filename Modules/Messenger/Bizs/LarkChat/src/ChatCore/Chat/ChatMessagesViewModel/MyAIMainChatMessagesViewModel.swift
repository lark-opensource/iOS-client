//
//  MyAIMainChatMessagesViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/17.
//

import Foundation
import ThreadSafeDataStructure
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkMessageBase

protocol CanSetClearAnchorVM: AnyObject {
    /// 列表伪清屏逻辑的目标置顶cell对应的id
    var anchorCellId: String? { get }
    var anchorMessageInfo: (String, Int32)? { get set }
    func updataAnchorMessageIfNeeded(message: Message)
}

extension CanSetClearAnchorVM {
    func updataAnchorMessageIfNeeded(message: Message) {
        if message.position > ( anchorMessageInfo?.1 ?? -1) || (message.position == anchorMessageInfo?.1 && message.localStatus != .success) {
            self.anchorMessageInfo = (message.id, message.position)
        }
    }
}

//MyAI新旧主会话共用的逻辑。主要是onboard卡片的展示逻辑
//@贾潇：MyAI新主会话（历史话题继续聊需求）预计跟版7.10。但由于和onboarding需求耦合较大，先提前为新/旧主会话抽出一个积累，避免未来代码冲突太多。
class MyAIMainChatBaseMessagesViewModel: ChatMessagesViewModel, CanSetClearAnchorVM {
    var myAIOnboardCardDatasource: MyAIOnboardCardDatasourceProtocol? {
        return self.messageDatasource as? MyAIOnboardCardDatasourceProtocol
    }

    // anchorMessage的id和position
    var anchorMessageInfo: (String, Int32)?

    var anchorCellId: String? {
        // 优先使用onboard卡片作为清屏锚点，若不存在onboard卡片，则使用position最大的anchorMessage作为清屏锚点
        return myAIOnboardCardDatasource?.onboardVM?.id ?? anchorMessageInfo?.0
    }

    /// 添加Onboard卡片状态的监听
    func addOnboardInfoObserver() {
        guard let pageService = try? context.userResolver.resolve(type: MyAIPageService.self) else {
            return
        }

        // 若拉取的首屏anchor信息与当前状态不一致，则更新 anchorMessageInfo
        pageService.myAIMainChatConfig.firstScreenAnchorRelay.subscribe(onNext: { [weak self] fistScreenAnchorinfo in
            guard let self = self else { return }
            if fistScreenAnchorinfo.1 > anchorMessageInfo?.1 ?? -1 {
                anchorMessageInfo = fistScreenAnchorinfo
                self.publish(.refreshTable)
            }
        }).disposed(by: self.disposeBag)

        // 监听Onboard卡片的状态，来更新datasource
        pageService.myAIMainChatConfig.onBoardInfoSubject
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] status in
                guard let self = self, let datasource = self.myAIOnboardCardDatasource else { return }
                switch status {
                case .loading:
                    if datasource.removeOnboardCard() {
                        self.jumpToChatLastMessage(tableScrollPosition: .bottom, finish: nil)
                    }
                case .notShow(newMessage: let message):
                    _ = datasource.removeOnboardCard()
                    /// 假消息上屏有发消息的数据统计，清空Onboard卡片后的最终数据链路不同
                    if let message = message {
                        if message.localStatus == .success {
                            self.publish(.hasNewMessage(message: message, hasFooter: false, withAnimation: false))
                        } else {
                            self.publish(.messageSending(message: message))
                        }
                    }
                case .success(let info, let byUser):
                    if datasource.setOnboardCard(info, concurrent: self.concurrentHandler) {
                        self.setClearAnchor(toBottom: byUser)
                    }
                case .willDismiss:
                    if self.changeOnboardCardToLoading() {
                        self.setClearAnchor(toBottom: true)
                    }
                }
            }).disposed(by: self.disposeBag)
    }

    /// onboard卡片将要移除，消息气泡展示loading的样式
    func changeOnboardCardToLoading() -> Bool {
        guard let datasource = messageDatasource as? MyAIOnboardCardDatasourceProtocol else {
            return false
        }
        if datasource.onboardVM?.isWaitingNewTopic == true {
            return false
        }
        datasource.onboardVM?.isWaitingNewTopic = true
        return true
    }

    /// 需要在队列中执行
    func setClearAnchor(toBottom: Bool) {
        let directToBottom = self.chatDataContext.lastVisibleMessagePosition <= self.messageDatasource.maxMessagePosition ? true : false
        if !directToBottom, toBottom {
            self.publish(.refreshTable)
            self.jumpToChatLastMessage(tableScrollPosition: .bottom, finish: nil)
        } else if toBottom {
            var scrollInfo: ScrollInfo?
            if !self.messageDatasource.cellViewModels.isEmpty, let datasource = self.myAIOnboardCardDatasource, !datasource.getOnboardVMs().isEmpty {
                scrollInfo = ScrollInfo(index: self.messageDatasource.cellViewModels.count + datasource.getOnboardVMs().count - 1, tableScrollPosition: .bottom)
                scrollInfo?.needDuration = true
                scrollInfo?.customDurationTime = AIMainChatTableView.setClearAnchorScrollAnimationDuration
            }
            self.publish(.refreshMessages(hasHeader: self.hasMoreOldMessages(), hasFooter: self.hasMoreNewMessages(), scrollInfo: scrollInfo))
        } else {
            self.publish(.refreshMessages(hasHeader: false, hasFooter: false, scrollInfo: nil))
        }
    }

    override func onInitializeMessages() {
        /// 监听Onboard状态变化
        addOnboardInfoObserver()
    }

    //TODO: 贾潇 「历史话题继续聊」时关注一下这个属性
    override var cellViewModelsCount: Int {
        if let onboardVMcount = (messageDatasource as? MyAIOnboardCardDatasourceProtocol)?.getOnboardVMs().count {
            return messageDatasource.cellViewModels.count + onboardVMcount
        }
        return messageDatasource.cellViewModels.count
    }

    /// 收敛方法，收到新消息push/pull时端上的处理
    func didReceiveMessages(_ messages: [Message]) {
        /// 更新anchorInfo
        messages.filter { $0.isAiSessionFirstMsg }.forEach { message in
            updataAnchorMessageIfNeeded(message: message)
        }
    }

    override func handleFirstScreen(result: GetChatMessagesResult, initType: MessageInitType) {
        self.didReceiveMessages(result.messages)
        super.handleFirstScreen(result: result, initType: initType)
    }

    override func handleMiss(result: Result<[Message], Error>, anchorMessageId: String?) {
        if case .success(let messages) = result {
            self.didReceiveMessages(messages)
        }
        super.handleMiss(result: result, anchorMessageId: anchorMessageId)
    }

    override func handleLoadMoreMessagesResult(_ result: GetChatMessagesResult) {
        self.didReceiveMessages(result.messages)
        super.handleLoadMoreMessagesResult(result)
    }

    override func handlePushMessages(messages: [Message]) {
        self.didReceiveMessages(messages)
        super.handlePushMessages(messages: messages)
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
        /// 如果onboard卡片展示中，接收到新的消息push不触发新消息上屏的滚滚底，只将列表刷新避免闪烁
        /// 接收到新消息push时，消息为新话题开始，且消息position比上一个清屏置顶的message position大，则将onboard卡片隐藏
        if message.isAiSessionFirstMsg,
           let datasource = self.myAIOnboardCardDatasource,
           (message.id == anchorMessageInfo?.0 ?? "" && message.position == anchorMessageInfo?.1) ||
            (message.localStatus != .success && message.position >= anchorMessageInfo?.1 ?? -1) {
            pageService.myAIMainChatConfig.onBoardInfoSubject.accept(.notShow(newMessage: message))
            Self.logger.info("MYAI ChatTrace change onboardStatus to notshow \(self.chatId), newAnchorPosition: \(message.position), newAnchorMsgId \(message.id), ")
            return
        }
        if onlyReload {
            Self.logger.info("MYAI ChatTrace refreshTable instead of publishing NewMessage")
            self.publish(.refreshTable)
            return
        }
        super.publishReceiveNewMessage(message: message)
    }
    // enable-lint: duplicated_code
}

protocol BottomFixedVMsDatasourceProtocol: AnyObject {
    func getOnboardVMs() -> [ChatCellViewModel]
}

protocol MyAIOnboardCardDatasourceProtocol: BottomFixedVMsDatasourceProtocol {
    var onboardVM: AIChatOnboardCardCellViewModel? { get }
    /// 展示onboard卡片
    func setOnboardCard(_ info: MyAIOnboardInfo, concurrent: (Int, (Int) -> Void) -> Void) -> Bool
    /// 移除onboard卡片
    func removeOnboardCard() -> Bool
}
