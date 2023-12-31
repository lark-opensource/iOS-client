//
//  MyAIInteractViewModel.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/23.
//

import Foundation
import RxSwift
import RxCocoa
import LarkCore
import RustPB
import ServerPB
import LarkModel
import EENavigator
import LarkAIInfra
import LarkOpenChat
import LarkContainer
import LarkRustClient
import AsyncComponent
import LarkSendMessage
import LKCommonsTracker
import LarkMessengerInterface

final class MyAIInteractViewModel {
    private let rustClient: RustService?
    let userResolver: UserResolver
    let myAIPageService: MyAIPageService?
    /// 这里需要使用weak，ChatMessagesOpenService底层是ChatMessagesViewController，不weak会造成ChatMessagesViewController不释放循环引用
    weak var chatMessagesOpenService: ChatMessagesOpenService?
    /// 获取 MyAIQuickActionSendService，具体由 OpenKeyboard 实现，用于直接发送快捷指令，或者将快捷指令放进键盘内编辑
    private let quickActionSendService: MyAIQuickActionSendService?
    /// 场景需求
    let myAISceneService: MyAISceneService?
    /// 是否应该添加「场景对话」按钮：FG开 && 主会场
    lazy var shouldAddModeButton: Bool = {
        let myaiModeMvp = self.userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.mode.mvp")
        let chatMode = self.myAIPageService?.chatMode ?? false
        return myaiModeMvp && !chatMode
    }()

    /// 是否使用端上mock消息样式的新引导卡片
    var useNewOnboard: Bool {
        self.myAIPageService?.useNewOnboard ?? false
    }

    /// 订阅 Tools 的变化
    private let extensionService: MyAIExtensionService?
    weak var stopGeneratingIsShown: BehaviorRelay<Bool>?

    private let disposeBag = DisposeBag()
    let chat: Chat

    init(userResolver: UserResolver, chat: Chat) {
        self.userResolver = userResolver
        self.rustClient = try? userResolver.resolve(type: RustService.self)
        self.myAIPageService = try? userResolver.resolve(type: MyAIPageService.self)
        self.extensionService = try? userResolver.resolve(type: MyAIExtensionService.self)
        self.quickActionSendService = try? userResolver.resolve(type: MyAIQuickActionSendService.self)
        self.myAISceneService = try? userResolver.resolve(type: MyAISceneService.self)
        self.chatMessagesOpenService = try? userResolver.resolve(type: ChatMessagesOpenService.self)
        self.chat = chat
    }

    /// 新话题
    func handleClickingNewTopic(onSuccess: (() -> Void)?, onError: ((Error) -> Void)?) {
        MyAITopExtendSubModule.logger.info("my ai click new topic")
        guard let myAIPageService = self.myAIPageService else {
            MyAITopExtendSubModule.logger.info("my ai click new topic error, service is none")
            return
        }

        IMTracker.Chat.Main.Click.newTopic(
            self.chat,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )

        var request = ServerPB_Office_ai_AIChatNewTopicRequest()
        request.chatID = Int64(self.chat.id) ?? 0
        if myAIPageService.chatMode {
            request.aiChatModeID = myAIPageService.chatModeConfig.aiChatModeId
            request.chatContext = myAIPageService.chatModeConfig.getCurrentChatContext()
        }
        // 透传请求
        self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImNewTopic).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            MyAITopExtendSubModule.logger.info("my ai new topic success")
            onSuccess?()
        }, onError: { error in
            MyAITopExtendSubModule.logger.info("my ai new topic error: \(error)")
            onError?(error)
        }).disposed(by: self.disposeBag)
    }

    /// 新场景
    func handleClickingNewScene(sceneId: Int64, onSuccess: (() -> Void)?, onError: ((Error) -> Void)?) {
        MyAITopExtendSubModule.logger.info("my ai click new scene")
        guard let myAIPageService = self.myAIPageService else {
            MyAITopExtendSubModule.logger.info("my ai click new scene error, service is none")
            return
        }

        var request = ServerPB_Office_ai_AIChatNewTopicRequest()
        request.chatID = Int64(self.chat.id) ?? 0
        if myAIPageService.chatMode { request.aiChatModeID = myAIPageService.chatModeConfig.aiChatModeId }
        // 场景需要添加sceneID、chatContext
        request.sceneID = sceneId
        request.chatContext = myAIPageService.chatModeConfig.getCurrentChatContext()
        // 透传请求
        self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImNewTopic).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            MyAITopExtendSubModule.logger.info("my ai new scene success")
            onSuccess?()
        }, onError: { error in
            MyAITopExtendSubModule.logger.info("my ai new scene error: \(error)")
            onError?(error)
        }).disposed(by: self.disposeBag)
    }

    func handleSelectingQuickAction(_ quickAction: AIQuickAction) {
        // 点击事件埋点
        reportQuickActionClickEvent(quickAction)
        // 交给代理处理 QuickAction 的编辑、发送任务
        quickActionSendService?.handleAIQuickAction(quickAction, sendTracker: QuickActionSendTracker(sendCallback: { [weak self] isEdited, _ in
            self?.reportQuickActionSendEvent(quickAction, isEdited: isEdited)
        }))
    }
}

// MARK: - QuickAction 埋点

extension MyAIInteractViewModel {

    func reportQuickActionShownEvent(_ quickActions: [AIQuickActionModel]) {
        guard let pageService = myAIPageService as? MyAIPageServiceImpl else { return }
        pageService.quickActionTracker.reportQuickActionShownEvent(
            quickActions,
            roundId: String(pageService.aiRoundInfo.value.roundId),
            location: .overEditor,
            fromChat: chat,
            extraParams: ["session_id": pageService.aiRoundInfo.value.sessionID ?? ""]
        )
    }

    func reportQuickActionClickEvent(_ quickAction: AIQuickActionModel) {
        guard let pageService = myAIPageService as? MyAIPageServiceImpl else { return }
        pageService.quickActionTracker.reportQuickActionClickEvent(
            quickAction,
            roundId: String(pageService.aiRoundInfo.value.roundId),
            location: .overEditor,
            fromChat: chat,
            extraParams: ["session_id": pageService.aiRoundInfo.value.sessionID ?? ""]
        )
    }

    func reportQuickActionSendEvent(_ quickAction: AIQuickActionModel, isEdited: Bool) {
        guard let pageService = myAIPageService as? MyAIPageServiceImpl else { return }
        pageService.quickActionTracker.reportQuickActionSendEvent(
            quickAction,
            roundId: String(pageService.aiRoundInfo.value.roundId),
            location: .overEditor,
            isEdited: isEdited,
            fromChat: chat,
            extraParams: ["session_id": pageService.aiRoundInfo.value.sessionID ?? ""]
        )
    }
}
