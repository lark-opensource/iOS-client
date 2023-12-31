//
//  ThreadChatPreviewByIDHandler.swift
//  LarkThread
//
//  Created by Bytedance on 2022/9/7.
//

import UIKit
import Foundation
import SnapKit
import RxSwift
import Swinject
import LarkCore
import LarkUIKit
import LarkModel
import EENavigator
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import AsyncComponent
import RustPB
import LarkSuspendable
import LarkBadge
import LarkOpenChat
import LarkOpenIM
import AppContainer
import LarkBizAvatar
import LarkSceneManager
import LarkNavigator
import LarkContainer

final class ThreadChatPreviewByIDHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }

    func handle(_ body: ThreadPreviewByIDBody, req: EENavigator.Request, res: Response) throws {
        ThreadPerformanceTracker.startEnter(fromWhere: body.fromWhere)
        let viewController = try GenerateComponent.createContainerController(
            resolver: userResolver,
            chatID: body.chatID,
            position: body.position,
            fromWhere: body.fromWhere
        )
        if let sourceID = req.context[SuspendManager.sourceIDKey] as? String {
            viewController.sourceID = sourceID
        }
        //100ms用于数据拉取及组件生成
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            res.end(resource: viewController)
        }
        res.wait()
    }
}

private struct GenerateComponent {
    private static let logger = Logger.log(GenerateComponent.self, category: "LarkThread")

    static func createContainerController(
        resolver: UserResolver,
        chatID: String,
        chat: Chat? = nil,
        topicGroup: TopicGroup? = nil,
        position: Int32?,
        fromWhere: ChatFromWhere
    ) throws -> ThreadGroupPreviewContainerController {
        // 话题列表按照倒序展示
        // 监听Chat的Push
        let getChatWrapper: (Chat) throws -> ChatPushWrapper = { (chat) in
           return try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        }
        // 监听TopicGroup的Push，小组不希望依赖Chat模型，所以有了TopicGroup的概念
        let getTopicGroupPushWrapper: (TopicGroup) throws -> TopicGroupPushWrapper = { (topicGroup) in
            return try resolver.resolve(assert: TopicGroupPushWrapper.self, argument: topicGroup)
        }
        let container = Container(parent: BootLoader.container)
        let navigationModuleContext = ChatNavgationBarContext(parent: container,
                                                              store: Store(),
                                                              interceptor: IMMessageNavigationInterceptor(),
                                                              userStorage: resolver.storage,
                                                              compatibleMode: resolver.compatibleMode)
        let pushCenter = try resolver.userPushCenter

        // 获取全部话题列表控制器
        let getThreadController: GetThreadGroupPreviewControllerBlock = { (contentConfig) in
            return try self.createThreadChatController(
                resolver: resolver,
                contentConfig: contentConfig,
                position: position)
        }
        let viewModel = ThreadContainerViewModel(
            userResolver: resolver,
            chatID: chatID,
            dependency: try resolver.resolve(assert: ThreadDependency.self),
            chat: chat,
            fromWhere: fromWhere,
            topicGroup: topicGroup,
            pushCenter: pushCenter,
            getChatPushWarpper: getChatWrapper,
            getTopicGroupPushWarpper: getTopicGroupPushWrapper
        )

        // 获取导航栏
        let getNavigationBarBlock: (Chat, Bool) throws -> ChatNavigationBar = { (chat, blurEnabled) in
            let navBar = try GenerateComponent.createNavigationBar(
                resolver: resolver,
                chat: chat,
                blurEnabled: blurEnabled,
                context: navigationModuleContext
            )
            container.register(ChatOpenNavigationService.self) { [weak navBar] (_) -> ChatOpenNavigationService in
                return navBar ?? DefaultChatOpenNavigationService()
            }
            return navBar
        }

        // 中间态控制器
        let intermediateStateControl = InitialDataAndViewControl<(Chat, TopicGroup), Void>(
            blockPreLoadData: viewModel.fetchChatAndTopicGroup(by: chatID)
        )

        let threadContainerVC = ThreadGroupPreviewContainerController(
            viewModel: viewModel,
            intermediateStateControl: intermediateStateControl,
            getNaviBar: getNavigationBarBlock,
            getThreadsController: getThreadController)
        container.register(ChatOpenService.self) { [weak threadContainerVC] (_) -> ChatOpenService in
            return threadContainerVC ?? DefaultChatOpenService()
        }
        return threadContainerVC
    }

    static func createThreadChatController(
        resolver: UserResolver,
        contentConfig: ThreadPreviewContentConfig,
        position: Int32?) throws -> ThreadGroupPreviewController {
        let dependency = try ThreadChatViewModelDependency(userResolver: resolver, chatId: contentConfig.chat.id)
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: contentConfig.chat)
        let topicGroupPushWrapper = try resolver.resolve(assert: TopicGroupPushWrapper.self, argument: contentConfig.topicGroup)

        let threadChatVM = ThreadChatViewModel(dependency: dependency, chatWrapper: chatWrapper)

        // 构造menumanager
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }

        let pushCenter = try resolver.userPushCenter
        let pushHandlerRegister = ThreadChatPushHandlersRegister(
            channelId: contentConfig.chat.id,
            userResolver: resolver
        )

        let context = ThreadContext(
            resolver: resolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
        )
        context.isPreview = true
        context.showPreviewLimitTip = true
        var channel = RustPB.Basic_V1_Channel()
        channel.id = contentConfig.chat.id
        channel.type = .chat
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        let chat = chatWrapper.chat.value
        let forceNotEnabled = chat.isTeamVisitorMode
        let readService = try resolver.resolve(assert: ChatMessageReadService.self,
                                                arguments: PutReadScene.thread(chat),
                                                forceNotEnabled,
                                                false,
                                                chat.isRemind,
                                                chat.isInBox,
                                                ["chat": chatWrapper.chat.value] as [String: Any], { () -> Int32 in
                                                    return chatWrapper.chat.value.readThreadPosition
                                                }, { (info: PutReadInfo) in
                                                    let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                                                        return chatIDAndMessageID.messageID
                                                    }
                                                    GenerateComponent.logger.info("UnreadThread: put read \(channel.id) \(messageIDs), \(info.maxPosition) \(info.maxBadgeCount)")
                                                    threadAPI.updateThreadsMeRead(
                                                        channel: channel,
                                                        threadIds: messageIDs,
                                                        readPosition: info.maxPosition,
                                                        readPositionBadgeCount: info.maxBadgeCount
                                                    )
                                                })
        let threadMessageVM = ThreadPreviewMessagesViewModel(
            dependency: try ThreadChatMessagesViewModelDependency(
                userResolver: resolver,
                chatId: contentConfig.chat.id,
                readService: readService
            ),
            context: context,
            chatWrapper: chatWrapper,
            topicGroupPushWrapper: topicGroupPushWrapper,
            pushHandlerRegister: pushHandlerRegister,
            gcunit: GCUnit(limitWeight: 128, limitGCRoundSecondTime: 10, limitGCMSCost: 100)
        )

        let threadVC = ThreadGroupPreviewController(
            chatViewModel: threadChatVM,
            messageViewModel: threadMessageVM,
            context: context,
            router: try resolver.resolve(assert: ThreadChatRouter.self),
            specifiedPosition: position
        )
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            return ChatScreenProtectService(chat: chatWrapper.chat,
                                            getTargetVC: { [weak context] in return context?.pageAPI },
                                            userResolver: resolver)
        }
        context.pageAPI = threadVC
        context.dataSourceAPI = threadMessageVM
        context.chatPageAPI = threadVC
        return threadVC
    }

    private static func createNavigationBar(
        resolver: Resolver,
        chat: Chat,
        blurEnabled: Bool,
        context: ChatNavgationBarContext
    ) throws -> ChatNavigationBar {
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        TargetPreviewChatNavigationBarModule.onLoad(context: context)
        TargetPreviewChatNavigationBarModule.registGlobalServices(container: context.container)
        let navigationBarModule = TargetPreviewChatNavigationBarModule(context: context)
        let viewModel = ChatNavigationBarViewModel(
            chatWrapper: chatWrapper,
            module: navigationBarModule,
            isDark: !Display.pad
        )
        //注意此处darkStyle强制false，与上面viewModel.isDark规则并不一致; 从语义和设计上二者应该一致，二者目前负责的显示区域不同，暂时没想到好的、简单的调整方式能让二者统一一致
        let navBar = ChatNavigationBarImp(viewModel: viewModel, blurEnabled: blurEnabled, darkStyle: false)
        navBar.setBackgroundColor(UIColor.clear)
        return navBar
    }
}
