//
//  ThreadChatHandler.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/1/6.
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
import LarkContainer
import LarkNavigator

final class ThreadChatByIDHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private static let logger = Logger.log(ThreadChatByIDHandler.self, category: "LarkThread")

    func handle(_ body: ThreadChatByIDBody, req: EENavigator.Request, res: Response) throws {
        let feedApi = try userResolver.resolve(assert: FeedAPI.self)

        ThreadPerformanceTracker.startEnter(fromWhere: body.fromWhere)
        feedApi.markChatLaunch(feedId: body.chatID, entityType: .chat)
        Self.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(body.chatID), type: .chat")
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

final class ThreadChatHandler: UserTypedRouterHandler {
    private static let logger = Logger.log(ThreadChatHandler.self, category: "LarkThread")
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    func handle(_ body: ThreadChatByChatBody, req: EENavigator.Request, res: Response) throws {
        let feedApi = try userResolver.resolve(assert: FeedAPI.self)
        let threadAPI = try userResolver.resolve(assert: ThreadAPI.self)

        let chatID = body.chat.id
        feedApi.markChatLaunch(feedId: chatID, entityType: .chat)
        Self.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(chatID), type: .chat")
        ThreadPerformanceTracker.startEnter(fromWhere: body.fromWhere)
        threadAPI
            .fetchChatAndTopicGroup(chatID: chatID, forceRemote: false, syncUnsubscribeGroups: true)
            .observeOn(MainScheduler.instance)
            .subscribe { [userResolver] event in
                do {
                    switch event {
                    case .next(let resultTmp):
                        guard let result = resultTmp else {
                            struct InvalidNext: Error {}
                            throw InvalidNext()
                        }

                        let chat = result.chat
                        let topicGroup: TopicGroup
                        if let topicGroupTmp = result.topicGroup {
                            topicGroup = topicGroupTmp
                        } else {
                            // 兜底方案，服务端接口问题没有返回TopicGroup时，屏蔽依赖TopicGroup的 默认小组/观察者功能，需要保证小组其他功能正常使用。
                            ThreadChatHandler.logger.error("enter thread chat topicGroup is nil, use default topicgroup \(chatID)")
                            topicGroup = TopicGroup.defaultTopicGroup(id: chatID)
                        }

                        ThreadChatHandler.logger.info("enter thread: chatID: \(chatID) topicGroupRole: \(topicGroup.userSetting.topicGroupRole)")
                        ThreadTracker.trackEnterChat(chat: body.chat, from: body.fromWhere.rawValue)
                        ThreadPerformanceTracker.updateRequestCost(trackInfo: result.trackInfo)

                        let viewCtontroller = try GenerateComponent.createContainerController(
                            resolver: userResolver,
                            chatID: chat.id,
                            chat: chat,
                            topicGroup: topicGroup,
                            position: body.position,
                            fromWhere: body.fromWhere
                        )
                        res.end(resource: viewCtontroller)
                    case .error(let error):
                        throw error
                    default: break
                    }
                } catch {
                    ThreadChatHandler.logger.error("TopicGroup fetch fail", additionalData: ["topicGroupID": chatID], error: error)
                    res.end(error: error)
                }
            }.disposed(by: self.disposeBag)

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
    ) throws -> ThreadContainerController {
        // 话题列表按照倒序展示
        // 监听Chat的Push
        let getChatWrapper: (Chat) throws -> ChatPushWrapper = { (chat) in
           return try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        }
        // 监听TopicGroup的Push，小组不希望依赖Chat模型，所以有了TopicGroup的概念
        let getTopicGroupPushWrapper: (TopicGroup) throws -> TopicGroupPushWrapper = { (topicGroup) in
            return try resolver.resolve(assert: TopicGroupPushWrapper.self, argument: topicGroup)
        }
        let pushCenter = try resolver.userPushCenter
        let container = Container(parent: BootLoader.container)
        let bannerContext = ChatBannerContext(parent: container, store: Store(),
                                              userStorage: resolver.storage, compatibleMode: resolver.compatibleMode)
        let navigationModuleContext = ChatNavgationBarContext(parent: container,
                                                              store: Store(),
                                                              interceptor: IMMessageNavigationInterceptor(),
                                                              userStorage: resolver.storage,
                                                              compatibleMode: resolver.compatibleMode)
        let allThreadMessageActionContext = MessageActionContext(parent: container,
                                                        store: Store(),
                                                        interceptor: IMMessageActionInterceptor(),
                                                        userStorage: resolver.storage, compatibleMode: resolver.compatibleMode)
        let filterThreadMessageActionContext = MessageActionContext(parent: container,
                                                        store: Store(),
                                                        interceptor: IMMessageActionInterceptor(),
                                                        userStorage: resolver.storage, compatibleMode: resolver.compatibleMode)

        // 获取导航栏
        let getNavigationBar: GetNavigationBar = { (chat, blurEnabled) in
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

        // 获取全部话题列表控制器
        let getThreadController: GetThreadChatController = { (contentConfig, unreadTipViewClickedFunc) in
            return try self.createThreadChatController(
                resolver: resolver,
                contentConfig: contentConfig,
                position: position,
                bannerContext: bannerContext,
                messageActionContext: allThreadMessageActionContext,
                unreadTipViewClickedFunc: unreadTipViewClickedFunc
            )
        }

        // 获取已订阅话题列表控制器
        let getFilterController: GetFilterController = { contentConfig in
            return try self.createFilterThreadsController(resolver: resolver,
                                                          messageActionContext: filterThreadMessageActionContext,
                                                          contentConfig: contentConfig)
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
        // 中间态控制器
        let intermediateStateControl = InitialDataAndViewControl<(Chat, TopicGroup), Void>(
            blockPreLoadData: viewModel.fetchChatAndTopicGroup(by: chatID),
            otherPreLoadData: viewModel.preloadFirstScreenData(chatID: chatID, position: position)
        )

        let threadContainerVC = ThreadContainerController(
            viewModel: viewModel,
            intermediateStateControl: intermediateStateControl,
            getNaviBar: getNavigationBar,
            getThreadsController: getThreadController,
            getFilterThreadsController: getFilterController)
        container.register(ChatOpenService.self) { [weak threadContainerVC] (_) -> ChatOpenService in
            return threadContainerVC ?? DefaultChatOpenService()
        }
        container.register(ThreadNavgationBarContentDependency.self) { [weak threadContainerVC] (_) -> ThreadNavgationBarContentDependency in
            return threadContainerVC ?? DefaultThreadNavgationBarContentDependencyImpl()
        }
        return threadContainerVC
    }

    static func createThreadChatController(
        resolver: UserResolver,
        contentConfig: ThreadContentConfig,
        position: Int32?,
        bannerContext: ChatBannerContext,
        messageActionContext: MessageActionContext,
        unreadTipViewClickedFunc: @escaping () -> Void
    ) throws -> ThreadChatController {
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
        let threadMessageVM = ThreadChatMessagesViewModel(
            dependency: try ThreadChatMessagesViewModelDependency(
                userResolver: resolver,
                chatId: contentConfig.chat.id,
                readService: readService
            ),
            context: context,
            chatWrapper: chatWrapper,
            topicGroupPushWrapper: topicGroupPushWrapper,
            pushHandlerRegister: pushHandlerRegister,
            gcunit: GCUnit(limitWeight: 128, limitGCRoundSecondTime: 10, limitGCMSCost: 100),
            navBarHeight: contentConfig.navBarHeight
        )

        let threadVC = ThreadChatController(
            userResolver: resolver,
            specifiedPosition: position,
            chatViewModel: threadChatVM,
            messageViewModel: threadMessageVM,
            context: context,
            bannerContext: bannerContext,
            messageActionContext: messageActionContext,
            router: try resolver.resolve(assert: ThreadChatRouter.self),
            unreadTipViewClickedFunc: unreadTipViewClickedFunc
        )
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        context.pageAPI = threadVC
        context.dataSourceAPI = threadMessageVM
        return threadVC
    }

    static func createFilterThreadsController(
        resolver: UserResolver,
        messageActionContext: MessageActionContext,
        contentConfig: ThreadContentConfig
    ) throws -> ThreadFilterController {
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: contentConfig.chat)
        let topicGroupPushWrapper = try resolver.resolve(assert: TopicGroupPushWrapper.self, argument: contentConfig.topicGroup)

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

        let messagesViewModel = ThreadFilterMessagesViewModel(
            userResolver: resolver,
            userGeneralSettings: try resolver.resolve(assert: UserGeneralSettings.self),
            translateService: try resolver.resolve(assert: NormalTranslateService.self),
            vmFactory: ThreadCellViewModelFactory(
                context: context,
                registery: ThreadChatSubFactoryRegistery(context: context),
                cellLifeCycleObseverRegister: ThreadChatCellLifeCycleObseverRegister()
            ),
            chatWrapper: chatWrapper,
            topicPushWrapper: topicGroupPushWrapper,
            chatID: contentConfig.chat.id,
            threadAPI: try resolver.resolve(assert: ThreadAPI.self),
            pushCenter: try resolver.userPushCenter,
            pushHandlerRegister: pushHandlerRegister,
            navBarHeight: contentConfig.navBarHeight
        )

        let vc = ThreadFilterController(
            messagesViewModel: messagesViewModel,
            messageActionContext: messageActionContext,
            context: context
        )

        context.pageAPI = vc
        context.dataSourceAPI = messagesViewModel

        return vc
    }

    private static func createNavigationBar(
        resolver: UserResolver,
        chat: Chat,
        blurEnabled: Bool,
        context: ChatNavgationBarContext
    ) throws -> ChatNavigationBar {
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        ThreadNavigationBarModule.onLoad(context: context)
        ThreadNavigationBarModule.registGlobalServices(container: context.container)
        let navigationBarModule = ThreadNavigationBarModule(context: context)
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
