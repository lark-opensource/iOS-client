//
//  NormalChatViewController.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/15.
//

import Foundation
import LarkUIKit
import LarkMessengerInterface
import LarkModel
import LarkContainer
import LarkMessageCore
import LarkSDKInterface
import RxSwift
import RustPB
import UniverseDesignToast
import LarkChatKeyboardInterface
import LarkMessageBase

class NormalChatViewController: ChatMessagesViewController {
    @ScopedInjectedLazy private var myAiAPI: MyAIAPI?

    private lazy var normalChatBottomLayout: NormalChatBottomLayout = {
        return NormalChatBottomLayout(userResolver: self.userResolver,
                                      context: self.moduleContext,
                                      chatWrapper: self.chatViewModel.chatWrapper,
                                      messagesObservable: self.chatMessageViewModel.chatDataProvider.messagesObservable,
                                      componentGenerator: componentGenerator,
                                      containerViewController: self,
                                      chatFromWhere: self.chatFromWhere,
                                      chatKeyPointTracker: self.chatKeyPointTracker,
                                      pushCenter: self.pushCenter,
                                      tableView: self.tableView,
                                      delegate: self,
                                      guideManager: self.guideManager,
                                      keyboardStartState: self.keyboardStartState,
                                      getMessageSender: { [weak self] in return self?.messageSender })
    }()

    private lazy var myAIInlineService: IMMyAIInlineService? = {
        return try? self.chatContext.userResolver.resolve(type: IMMyAIInlineService.self)
    }()

    // 处理分会话业务
    lazy var myAIChatModeOpenService: IMMyAIChatModeOpenService? = {
        return try? self.chatContext.userResolver.resolve(type: IMMyAIChatModeOpenService.self)
    }()

    deinit {
        self.myAIChatModeOpenService?.myAIModeConfigPageService?.closeMyAIChatMode()
    }

    override func afterMessagesRender() {
        super.afterMessagesRender()
        self.observeSwitchTeamChatMode()
    }

    override func uiBusinessAfterMessageRender() {
        super.uiBusinessAfterMessageRender()
        tableView.draggingDriver
            .skip(1)
            .distinctUntilChanged({ status1, status2 -> Bool in
                return status1.0 == status2.0
            })
            .drive(onNext: { [weak self] (dragging, _) in
                guard let `self` = self else { return }
                // 多选和使用iPad的时候不隐藏bar
                if self.multiSelecting || Display.pad { return }
                if dragging {
                    self.chatOpenService?.setTopContainerShowDelay(false)
                } else {
                    self.chatOpenService?.setTopContainerShowDelay(true)
                }
            }).disposed(by: disposeBag)
    }

    override func onUnReadMessagesTipViewMyAIItemTapped(tipView: BaseUnReadMessagesTipView) {
        let chatModeEnable = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_chat_mode")
        let floatWindowEnable = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_inline")

        guard (chatModeEnable || floatWindowEnable),
              let myAIInlineService = self.myAIInlineService,
              let myAIChatModeOpenService = self.myAIChatModeOpenService else { return }
        var params: [String: String] = [:]
        var imChatHistoryInfo: String = ""
        if tipView is DownUnReadMessagesTipView {
            //下电梯的情况下，希望多总结一屏的消息。但这个“一屏消息”的数量并不需要很精确，所以用Int32(self.tableView.visibleCellData.count)来估算。
            var startPosition = self.chatMessageViewModel.chatDataContext.readPosition - Int32(self.tableView.visibleCellData.count)
            if startPosition <= 0 {
                startPosition = 0
            }
            if let (key, value) = myAIInlineService.generateParamsForMessagesInfo(startPosition: startPosition, direction: .down) {
                params[key] = value
            }
           imChatHistoryInfo = myAIChatModeOpenService.imChatHistoryMessageClientInfo(startPosition: startPosition, direction: .down)
        } else if tipView is TopUnreadMessagesTipView {
            let startPosition = self.chatMessageViewModel.chatDataContext.readPosition
            if let (key, value) = myAIInlineService.generateParamsForMessagesInfo(startPosition: startPosition, direction: .up) {
                params[key] = value
            }
           imChatHistoryInfo = myAIChatModeOpenService.imChatHistoryMessageClientInfo(startPosition: startPosition, direction: .up)
        } else {
            Self.logger.error("onUnReadMessagesTipViewMyAIItemTapped, but unknown tipView")
        }
        self.myAiAPI?.getSummarizeQuickAction()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak tipView] quickAction in
                guard let self = self, let myAIChatModeOpenService = self.myAIChatModeOpenService else { return }
                if chatModeEnable {
                    var action = quickAction
                    action.extraMap = myAIChatModeOpenService.getMyAIChatContext(imChatHistoryMessageClient: imChatHistoryInfo,
                                                                                 sceneCardClose: true)
                    // 分会话模式处理电梯未读总结
                    myAIChatModeOpenService.handleMyAIChatModeAndQuickAction(quickAction: action,
                                                                             sceneCardClose: true,
                                                                             fromVC: self,
                                                                             trackParams: ["location": "scroll_to_unread"])
                    myAIChatModeOpenService.alreadySummarizedMessageByMyAI = true
                } else {
                    // 浮窗模式处理电梯未读总结
                    self.myAIInlineService?.openMyAIInlineModeWith(quickAction: quickAction, params: params, source: .scroll_to_unread)
                    self.myAIInlineService?.alreadySummarizedMessageByMyAI = true
                }
                tipView?.refresh()
                Self.logger.info("openMyAIInlineMode by SummarizeQuickAction")
            }, onError: { error in
                Self.logger.info("openMyAIInlineMode by SummarizeQuickAction error", error: error)
            }).disposed(by: disposeBag)
    }

    override func shouldShowUnReadMessagesMyAIView(tipView: BaseUnReadMessagesTipView) -> Bool {
        let shouldShowAITipViewFG = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_chat_mode")
        || self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_inline")
        // 校验FG、群属性、MyAI可用性，是否可以出「总结」
        guard shouldShowAITipViewFG,
              self.chat.value.supportMyAIInlineMode,
              self.myAIService?.enable.value == true,
              self.myAIService?.needOnboarding.value == false else { return false }
        // 如果用户已经点击过「总结」，则不再展示「总结」
        if self.myAIInlineService?.alreadySummarizedMessageByMyAI == true { return false }
        if self.myAIChatModeOpenService?.alreadySummarizedMessageByMyAI == true { return false }
        // 如果进群时，群badge数小于10，则不展示「总结」
        if self.chatViewModel.chatInitiallyBadge < 10 { return false }
        // 埋点上报，返回true，需要「总结」
        if self.myAIInlineService?.alreadyTrackSummarizedMessageByMyAIView != true {
            self.myAIInlineService?.trackInlineAIEntranceView(.scroll_to_unread)
            self.myAIInlineService?.alreadyTrackSummarizedMessageByMyAIView = true
        }
        return true
    }

    override func insertAt(by chatter: Chatter?) {
        self.normalChatBottomLayout.insertAt(by: chatter)
    }

    override func generateBottomLayout() -> BottomLayout {
        return normalChatBottomLayout
    }

    override func reply(message: LarkModel.Message, partialReplyInfo: LarkModel.PartialReplyInfo?) {
        self.normalChatBottomLayout.reply(message: message, partialReplyInfo: partialReplyInfo)
    }

    override func reedit(_ message: Message) {
        self.normalChatBottomLayout.reedit(message)
    }

    override func multiEdit(_ message: Message) {
        self.normalChatBottomLayout.multiEdit(message: message)
    }

    override func quasiMsgCreateByNative() -> Bool {
        let chat = self.chat.value
        return chat.anonymousId.isEmpty && !chat.isCrypto
    }
}

extension NormalChatViewController: IMMyAIChatModeOpenServiceDelegate {
    func handleAIAddNewMemberSytemMessage(actionID: String, chatID: String, fromVC: UIViewController) {
        self.myAIChatModeOpenService?.handleAIAddNewMemberSytemMessage(actionID: actionID, chatID: chatID, fromVC: fromVC)
    }
}

extension NormalChatViewController: IMMyAIInlineServiceDelegate {
    func getChat() -> LarkModel.Chat {
        return chat.value
    }

    func getDisplayVC() -> UIViewController {
        return self
    }

    func getUnreadMessagesInfo() -> (startPosition: Int32, direction: MyAIInlineServiceParamMessageDirection) {
        return (chatMessageViewModel.chatDataContext.readPosition, .up)
    }

    func onInsertInMyAIInline(content: RustPB.Basic_V1_RichText) {
        guard self.chat.value.isAllowPost else {
            UDToast.showFailure(with: BundleI18n.AI.MyAI_IM_UnableToInsert_Toast, on: self.view)
            return
        }
        self.normalChatBottomLayout.insertRichText(richText: content)
    }
}

// MARK: - 处理团队公开群 用户身份转换逻辑
extension NormalChatViewController {
    private func observeSwitchTeamChatMode() {
        chatViewModel.teamChatModeSwitchDriver.drive(onNext: { [weak self] (change) in
            guard let self = self else { return }
            switch change {
            case .none: break
            case .visitorToMember: self.refreshGroup()
            case .memberToVisitor: self.showSwitchTeamChatModeAlert()
            }
        }).disposed(by: disposeBag)
    }

    private func showSwitchTeamChatModeAlert() {
        self.chatMessageBaseDelegate?.showChatModeThreadClosedAlert()
     }

    // 关闭掉chat，然后重新进入chat
    private func refreshGroup() {
        let chat = chatViewModel.chat
        var completion: (() -> Void)?
        if let vc = self.navigationController {
            completion = { [weak vc, userResolver] in
                guard let vc = vc else { return }
                Self.logger.info("chatTrace/teamlog/refreshGroup/enter id: \(chat.id)")
                let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                         fromWhere: .teamOpenChat,
                                                         isCrypto: chat.isCrypto,
                                                         isMyAI: chat.isP2PAi,
                                                         chatMode: chat.chatMode)
                userResolver.navigator.showDetailOrPush(body: body,
                                                  wrap: LkNavigationController.self,
                                                  from: vc,
                                                  animated: false)
            }
        }
        Self.logger.info("chatTrace/teamlog/refreshGroup/exist id: \(chat.id)")
        popSelf(animated: false, dismissPresented: true, completion: completion)
    }
}

extension NormalChatViewController: NormalChatBottomLayoutDelegate {
    func updateCellViewModel(ids: [String], doUpdate: @escaping (String, ChatCellViewModel) -> Bool) {
        self.chatMessageViewModel.updateCellViewModel(ids: ids, doUpdate: doUpdate)
    }

    func keyboardContentHeightWillChange(_ isFold: Bool) {
        self.chatMessageBaseDelegate?.keyboardContentHeightWillChange(isFold)
    }

    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType) {
        DispatchQueue.main.async {
            if self.chatMessageViewModel.firstScreenLoaded {
                let tracker = self.chatMessageViewModel.dependency.chatKeyPointTracker
                let indentify = tracker.generateIndentify()
                tracker.inChatStartJump(indentify: indentify)
                if let replyMessage = self.normalChatBottomLayout.replymessage {
                    self.chatMessageViewModel.jumpTo(position: replyMessage.position, tableScrollPosition: .bottom, finish: { trackInfo in
                        tracker.inChatFinishJump(indentify: indentify, scene: .keyboardShow, trackInfo: trackInfo)
                    })
                } else if let editingMessage = self.normalChatBottomLayout.editingMessage {
                    self.chatMessageViewModel.jumpTo(position: editingMessage.position, tableScrollPosition: .bottom, finish: { trackInfo in
                        tracker.inChatFinishJump(indentify: indentify, scene: .keyboardShow, trackInfo: trackInfo)
                    })
                } else {
                    self.chatMessageViewModel.jumpToChatLastMessage(tableScrollPosition: .bottom) { trackInfo in
                        tracker.inChatFinishJump(indentify: indentify, scene: .keyboardShow, trackInfo: trackInfo)
                    }
                }
            }
        }
    }
}
