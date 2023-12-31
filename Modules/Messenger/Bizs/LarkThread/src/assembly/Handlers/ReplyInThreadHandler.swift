//
//  ReplyInThreadHandler.swift
//  LarkThread
//
//  Created by liluobin on 2022/4/11.
//

import UIKit
import Foundation
import RxSwift
import Swinject
import LarkCore
import LarkModel
import UniverseDesignToast
import EENavigator
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkSendMessage
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import AsyncComponent
import RustPB
import LarkSuspendable
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkSceneManager
import LarkContainer
import LarkOpenChat
import class AppContainer.BootLoader
import LarkNavigator

final class ReplyInThreadHandler: UserTypedRouterHandler {
    private static let logger = Logger.log(ReplyInThreadHandler.self, category: "ReplyInThreadByIDBody")
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }

    func handle(_ body: ReplyInThreadByIDBody, req: EENavigator.Request, res: Response) throws {
        let feedApi = try resolver.resolve(assert: FeedAPI.self)
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)

        feedApi.markChatLaunch(feedId: body.threadId, entityType: .thread)
        Self.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(body.threadId), type: .thread")
        let resolver = self.userResolver
        let getDetailController = { (vc, threadMessage, chat) in
            return try ReplyInThreadGenarateComponent.generateViewController(
                parameters: ReplyInThreadGenarateComponent.Parameters(
                    resolver: resolver,
                    loadType: body.loadType,
                    position: body.position,
                    keyboardStartupState: body.keyboardStartupState,
                    threadMessage: threadMessage,
                    chat: chat,
                    sourceType: body.sourceType,
                    showFromChat: true,
                    chatFromWhere: body.chatFromWhere,
                    containerVC: vc,
                    specificSource: body.specificSource
                )
            )
        }

        let viewModel = ReplyInThreadContainerViewModel(
            userResolver: resolver,
            threadID: body.threadId
        )
        /// 如果是通知来的，强制是用forceServer
        var strategy: RustPB.Basic_V1_SyncDataStrategy = .tryLocal
        if body.sourceType == .notification {
            strategy = .forceServer
        }
        let intermediateStateControl = InitialDataAndViewControl<ReplyInThreadDetailBlockData, Void>(
            blockPreLoadData: ReplyInThreadContainerViewModel.fetchBlockData(
                threadID: body.threadId,
                threadAPI: threadAPI,
                strategy: strategy,
                chat: nil,
                chatAPI: chatAPI
            )
        )

        let vc = ReplyInThreadContainerViewController(
            viewModel: viewModel,
            intermediateStateControl: intermediateStateControl,
            getDetailController: getDetailController
        )

        //100ms用于数据拉取及组件生成
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            res.end(resource: vc)
        }
        res.wait()
    }
}

final class ReplyInThreadByModelHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private static let logger = Logger.log(ReplyInThreadByModelHandler.self, category: "LarkThread")

    func handle(_ body: ReplyInThreadByModelBody, req: EENavigator.Request, res: Response) throws {
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let feedAPI = try resolver.resolve(assert: FeedAPI.self)

        feedAPI.markChatLaunch(feedId: body.message.id, entityType: .thread)
        Self.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(body.message.id), type: .thread")
        /// 咨询相关同学，暂时没有无痕删除，这个仅做个打印
        if body.message.isNoTraceDeleted {
            Self.logger.info("message - isNoTraceDeleted")
        }
        let resolver = self.userResolver

        let getDetailController = { (vc, threadMessage, chat) in
            return try ReplyInThreadGenarateComponent.generateViewController(
                parameters: ReplyInThreadGenarateComponent.Parameters(
                    resolver: resolver,
                    loadType: body.loadType,
                    position: body.position,
                    keyboardStartupState: body.keyboardStartupState,
                    threadMessage: threadMessage,
                    chat: chat,
                    sourceType: body.sourceType,
                    showFromChat: false,
                    chatFromWhere: body.chatFromWhere,
                    containerVC: vc
                )
            )
        }

        let viewModel = ReplyInThreadContainerViewModel(
            userResolver: resolver,
            threadID: body.threadId
        )

        let intermediateStateControl = InitialDataAndViewControl<ReplyInThreadDetailBlockData, Void>(
            blockPreLoadData: ReplyInThreadContainerViewModel.fetchBlockData(
                threadID: body.threadId,
                threadAPI: threadAPI,
                strategy: .tryLocal,
                chat: body.chat,
                chatAPI: chatAPI
            )
        )

        let vc = ReplyInThreadContainerViewController(
            viewModel: viewModel,
            intermediateStateControl: intermediateStateControl,
            getDetailController: getDetailController
        )

        //100ms用于数据拉取及组件生成
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            res.end(resource: vc)
        }
        res.wait()
    }

}

private struct ReplyInThreadGenarateComponent {
    private static let logger = Logger.log(ReplyInThreadGenarateComponent.self, category: "LarkThread")

    struct Parameters {
        let resolver: UserResolver
        let loadType: ThreadDetailLoadType
        let position: Int32?
        let keyboardStartupState: KeyboardStartupState
        let threadMessage: ThreadMessage
        let chat: Chat
        let sourceType: ReplyInThreadFromSourceType
        let showFromChat: Bool
        let chatFromWhere: ChatFromWhere
        weak var containerVC: UIViewController?
        var specificSource: SpecificSourceFromWhere? //细化fromWhere的二级来源
    }

    static func generateViewController(parameters: Parameters) throws -> UIViewController {
        let resolver = parameters.resolver
        // 构造menumanager
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: parameters.chat)
        let threadWrapper = try resolver.resolve(assert: ThreadPushWrapper.self, arguments: parameters.threadMessage.thread, parameters.chat, true)

        // 构造context
        let context = ThreadDetailContext(
            resolver: resolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
        )
        context.trackParams = [PageContext.TrackKey.sceneKey: parameters.chatFromWhere.rawValue]

        // cell factory
        let factory = ThreadReplyMessageCellViewModelFactory(
            threadWrapper: threadWrapper,
            context: context,
            registery: ReplyInThreadSubFactoryRegistery(context: context),
            threadMessage: parameters.threadMessage,
            cellLifeCycleObseverRegister: ThreadDetailCellLifeCycleObseverRegister()
        )

        let isFollow = threadWrapper.thread.value.isFollow
        let pushCenter = try resolver.userPushCenter
        let pushHandlers = ReplyInThreadPushHandlersRegister(channelId: parameters.chat.id, userResolver: resolver)
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        /// isMock 说明Thread还没有创建 需要使用chat中的已读
        let readServiceManager = ReplyInThreadReadServiceManager(resolver: resolver,
                                                                 chatWrapper: chatWrapper,
                                                                 threadWrapper: threadWrapper,
                                                                 threadMessage: parameters.threadMessage,
                                                                 fromWhere: parameters.chatFromWhere.rawValue)
        let vm = ReplyInThreadViewModel(
            userResolver: resolver,
            chatWrapper: chatWrapper,
            threadWrapper: threadWrapper,
            context: context,
            sendMessageAPI: try resolver.resolve(assert: SendMessageAPI.self),
            postSendService: try resolver.resolve(assert: PostSendService.self),
            videoMessageSendService: try resolver.resolve(assert: VideoMessageSendService.self),
            threadAPI: threadAPI,
            messageAPI: try resolver.resolve(assert: MessageAPI.self),
            draftCache: try resolver.resolve(assert: DraftCache.self),
            pushCenter: pushCenter,
            pushHandlers: pushHandlers,
            is24HourTime: try resolver.resolve(assert: UserGeneralSettings.self).is24HourTime.asObservable(),
            factory: factory,
            threadMessage: parameters.threadMessage,
            useIncompleteLocalData: isFollow, // 已订阅 才需要使用localData策略,
            userGeneralSettings: try resolver.resolve(assert: UserGeneralSettings.self),
            translateService: try resolver.resolve(assert: NormalTranslateService.self),
            readServiceManager: readServiceManager
        )
        let loadType: ThreadDetailLoadType = parameters.loadType
        let vcLoadType: ReplyInThreadViewController.LoadType
        /// 产品这里希望如果用户没有看到过replyInthread里面的评论，跳转跟消息而不是第一条评论
        let readPositionBadgeCount = parameters.threadMessage.thread.readPositionBadgeCount
        let unReadComments = (readPositionBadgeCount == 0)
        switch loadType {
        case .unread:
            vcLoadType = parameters.showFromChat ? .unread : (unReadComments ? .root : .unread)
            Self.logger.info("jump to unread reply in thread to root \(vcLoadType.rawValue) readPositionBadgeCount -- \(readPositionBadgeCount)")
        case .position:
            let position = parameters.position ?? -1
            vcLoadType = .position(position)
        case .justReply:
            vcLoadType = .justReply
        case .root:
            vcLoadType = .root
        }
        let messageActionContext = MessageActionContext(parent: Container(parent: BootLoader.container),
                                                        store: Store(),
                                                        interceptor: IMMessageActionInterceptor(),
                                                        userStorage: resolver.storage, compatibleMode: resolver.compatibleMode)
        // 构造vc
        let vc = ReplyInThreadViewController(
            loadType: vcLoadType,
            viewModel: vm,
            context: context,
            messageActionContext: messageActionContext,
            keyboardStartupState: parameters.keyboardStartupState,
            chatAPI: try resolver.resolve(assert: ChatAPI.self),
            menuService: try resolver.resolve(assert: ThreadMenuService.self),
            sourceType: parameters.sourceType,
            keyboardBlock: { delegate in
                return try resolver.resolve( // user:checked
                    assert: ThreadKeyboard.self,
                    arguments: delegate,
                    chatWrapper,
                    threadWrapper,
                    true
                )
            },
            dependency: try resolver.resolve(assert: ThreadDependency.self),
            getContainerController: {
                return parameters.containerVC
            },
            chatFromWhere: parameters.chatFromWhere,
            specificSource: parameters.specificSource
        )
        vc.showFromChat = parameters.showFromChat
        context.pageContainer.register(MessageURLTemplateService.self) { [weak context] in
            return MessageURLTemplateService(context: context, pushCenter: pushCenter)
        }
        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }
        context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
            return ChatScreenProtectService(chat: chatWrapper.chat,
                                            getTargetVC: { [weak context] in return context?.pageAPI },
                                            userResolver: resolver)
        }
        let chat = chatWrapper.chat.value
        context.pageAPI = vc
        context.dataSourceAPI = vm
        context.chatPageAPI = vc

        return vc
    }
}
