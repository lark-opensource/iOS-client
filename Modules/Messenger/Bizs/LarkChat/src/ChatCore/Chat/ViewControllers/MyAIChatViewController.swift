//
//  MyAIChatViewController.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/15.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import RxCocoa
import LarkFoundation
import LKCommonsLogging
import SnapKit
import LarkUIKit
import LarkContainer
import LarkCore
import LarkKeyboardView
import EENavigator
import LarkMessageCore
import UniverseDesignToast
import LarkMessageBase
import LarkAlertController
import UniverseDesignDialog
import LarkMessengerInterface
import LarkChatKeyboardInterface

protocol HasMyAIQuickActionSendService {
    var myAIQuickActionSendService: MyAIQuickActionSendService? { get }
}

protocol HasMyAIPageService {
    var myAIPageService: MyAIPageService? { get }
    var chat: BehaviorRelay<Chat> { get }
}

/// MyAI主、分会场基类
class MyAIChatViewController: ChatMessagesViewController, HasMyAIPageService, HasMyAIQuickActionSendService {
    private lazy var aiChatBottomLayout: AIChatBottomLayout = {
        return AIChatBottomLayout(userResolver: self.userResolver,
                                  context: self.moduleContext,
                                  chatWrapper: self.chatViewModel.chatWrapper,
                                  componentGenerator: componentGenerator,
                                  containerViewController: self,
                                  chatFromWhere: self.chatFromWhere,
                                  chatKeyPointTracker: self.chatKeyPointTracker,
                                  pushCenter: self.pushCenter,
                                  tableView: self.tableView,
                                  delegate: self,
                                  guideManager: self.guideManager,
                                  keyboardStartState: self.keyboardStartState,
                                  isMyAIChatMode: self.isMyAIChatMode,
                                  getMessageSender: { [weak self] in return self?.messageSender })
    }()

    private lazy var islandAiChatBottomLayout: IslandAIChatBottomLayout = {
        return IslandAIChatBottomLayout(userResolver: self.userResolver,
                                        context: self.moduleContext,
                                        chatWrapper: self.chatViewModel.chatWrapper,
                                        componentGenerator: componentGenerator,
                                        containerViewController: self,
                                        pushCenter: self.pushCenter,
                                        tableView: self.tableView,
                                        isMyAIChatMode: self.isMyAIChatMode,
                                        getMessageSender: { [weak self] in return self?.messageSender })
    }()

    private var lastNewTopicSystemMsgPosition: Int64 = Int64.max
    private var originLastMessagePosition: Int64?

    private var toolIds: [String] = []
    var myAIQuickActionSendService: MyAIQuickActionSendService? {
        return try? self.chatContext.userResolver.resolve(type: MyAIQuickActionSendService.self)
    }
    lazy var myAIPageService: MyAIPageService? = {
        return try? self.chatContext.userResolver.resolve(type: MyAIPageService.self)
    }()
    private lazy var isMyAIChatMode: Bool = {
        return myAIPageService?.chatMode ?? false
    }()

    private var aiChatTable: AIChatTableView? {
        return self.tableView as? AIChatTableView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.aiChatTable?.containerViewControllerDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.aiChatTable?.containerViewControllerDidDisappear()
    }

    override func uiBusinessAfterMessageRender() {
        super.uiBusinessAfterMessageRender()
    }

    override func generateBottomLayout() -> BottomLayout {
        return aiChatBottomLayout
    }

    override func quasiMsgCreateByNative() -> Bool {
        return false
    }
}

extension MyAIChatViewController: AIChatBottomLayoutDelegate {
    func keyboardContentHeightWillChange(_ isFold: Bool) {
        self.chatMessageBaseDelegate?.keyboardContentHeightWillChange(isFold)
    }

    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType) {
        DispatchQueue.main.async {
            if self.chatMessageViewModel.firstScreenLoaded {
                let tracker = self.chatMessageViewModel.dependency.chatKeyPointTracker
                let indentify = tracker.generateIndentify()
                tracker.inChatStartJump(indentify: indentify)
                self.chatMessageViewModel.jumpToChatLastMessage(tableScrollPosition: .bottom) { trackInfo in
                    tracker.inChatFinishJump(indentify: indentify, scene: .keyboardShow, trackInfo: trackInfo)
                }
            }
        }
    }
}
