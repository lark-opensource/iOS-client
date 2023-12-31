//
//  ThreadDetailHandler.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/1/6.
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
import LarkContainer
import LarkOpenChat
import LarkNavigator

final class ThreadDetailHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private static let logger = Logger.log(ThreadDetailHandler.self, category: "LarkThread")
    private let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: ThreadDetailByIDBody, req: EENavigator.Request, res: Response) throws {
        let feedApi = try userResolver.resolve(assert: FeedAPI.self)
        feedApi.markChatLaunch(feedId: body.threadId, entityType: .thread)
        Self.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(body.threadId), type: .thread")
        ThreadPerformanceTracker.startEnter()

        let resolver = self.userResolver
        let getDetailController = { (vc, threadMessage, chat, topicGroup) in
            return try GenarateComponent.generateViewController(
                parameters: GenarateComponent.Parameters(
                    resolver: resolver,
                    loadType: body.loadType,
                    position: body.position,
                    keyboardStartupState: body.keyboardStartupState,
                    threadMessage: threadMessage,
                    chat: chat,
                    topicGroup: topicGroup,
                    sourceType: body.sourceType,
                    isFromFeed: body.sourceType == .feed,
                    needUpdateBlockData: false,
                    containerVC: vc,
                    specificSource: body.specificSource
                )
            )
        }

        let viewModel = DetailContainerViewModel(
            userResolver: resolver,
            threadID: body.threadId
        )
        /// 如果是通知来的，强制是用forceServer
        var strategy: RustPB.Basic_V1_SyncDataStrategy = .tryLocal
        if body.sourceType == .notification {
            strategy = .forceServer
            Self.logger.info(logId: "thread detail notification load SyncDataStrategy forceServer \(body.threadId)")
        }
        let intermediateStateControl = InitialDataAndViewControl<DetailBlockData, Void>(
            blockPreLoadData: DetailContainerViewModel.fetchBlockData(
                threadID: body.threadId,
                strategy: strategy,
                threadAPI: try resolver.resolve(assert: ThreadAPI.self),
                chatAPI: try resolver.resolve(assert: ChatAPI.self)
            )
        )

        let vc = DetailContainerController(
            viewModel: viewModel,
            intermediateStateControl:
            intermediateStateControl,
            getDetailController: getDetailController
        )
        vc.pushInfo = ThreadDetailPushInfo(loadType: body.loadType,
                                           position: body.position,
                                           fromVC: req.from.fromViewController)
        if let sourceID = req.context[SuspendManager.sourceIDKey] as? String {
            vc.sourceID = sourceID
        }

        //100ms用于数据拉取及组件生成
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            res.end(resource: vc)
        }
        res.wait()
    }
}

final class ThreadDetailByModelHandler: UserTypedRouterHandler {
    private static let logger = Logger.log(ThreadDetailByModelHandler.self, category: "LarkThread")
    func handle(_ body: ThreadDetailByModelBody, req: EENavigator.Request, res: Response) throws {
        let feedAPI = try userResolver.resolve(assert: FeedAPI.self)
        let resolver = userResolver
        if body.threadMessage.isNoTraceDeleted {
            if let window = req.from.fromViewController?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkThread.Lark_Chat_TopicWasRecalledToast, on: window)
            }
            return res.end(error: nil)
        }
        feedAPI.markChatLaunch(feedId: body.threadMessage.id, entityType: .thread)
        Self.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(body.threadMessage.id), type: .thread")
        ThreadPerformanceTracker.startEnter()
        let vc = try GenarateComponent.generateViewController(
            parameters: GenarateComponent.Parameters(
                resolver: resolver,
                loadType: body.loadType,
                position: body.position,
                keyboardStartupState: body.keyboardStartupState,
                threadMessage: body.threadMessage,
                chat: body.chat,
                topicGroup: body.topicGroup,
                sourceType: body.sourceType,
                isFromFeed: false,
                needUpdateBlockData: body.needUpdateBlockData,
                containerVC: nil
            )
        )
        if let sourceID = req.context[SuspendManager.sourceIDKey] as? String {
            (vc as? ThreadDetailController)?.sourceID = sourceID
        }
        res.end(resource: vc)
    }
}

private struct GenarateComponent {
    private static let logger = Logger.log(GenarateComponent.self, category: "LarkThread")

    struct Parameters {
        let resolver: UserResolver
        let loadType: ThreadDetailLoadType
        let position: Int32?
        let keyboardStartupState: KeyboardStartupState
        let threadMessage: ThreadMessage
        let chat: Chat
        let topicGroup: TopicGroup
        let sourceType: ThreadDetailFromSourceType
        let isFromFeed: Bool
        let needUpdateBlockData: Bool
        weak var containerVC: UIViewController?
        var specificSource: SpecificSourceFromWhere?
    }

    static fileprivate func generateViewController(parameters: Parameters) throws -> UIViewController {
        let resolver = parameters.resolver
        // 构造menumanager
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: parameters.chat)
        let threadWrapper = try resolver.resolve(assert: ThreadPushWrapper.self, arguments: parameters.threadMessage.thread, parameters.chat, false)
        let topicGroupPushWrapper = try resolver.resolve(assert: TopicGroupPushWrapper.self, argument: parameters.topicGroup)

        // 构造context
        let context = ThreadDetailContext(
            resolver: resolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
        )

        // cell factory
        let factory = ThreadDetailMessageCellViewModelFactory(
            threadWrapper: threadWrapper,
            context: context,
            registery: ThreadDetailSubFactoryRegistery(context: context),
            threadMessage: parameters.threadMessage,
            cellLifeCycleObseverRegister: ThreadDetailCellLifeCycleObseverRegister()
        )

        let isFollow = threadWrapper.thread.value.isFollow

        let pushCenter = try resolver.userPushCenter
        let pushHandlers = ThreadDetailPushHandlersRegister(channelId: parameters.chat.id, userResolver: resolver)
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        var channel = RustPB.Basic_V1_Channel()
        channel.id = parameters.chat.id
        channel.type = .chat
        let chat = chatWrapper.chat.value
        let readService = try resolver.resolve( // user:checked
            assert: ChatMessageReadService.self,
            arguments: PutReadScene.thread(chat),
            false,
            false,
            chat.isRemind,
            chat.isInBox,
            ["chat": chatWrapper.chat.value] as [String: Any], { () -> Int32 in
                return threadWrapper.thread.value.readPosition
            }, { (info: PutReadInfo) in
                let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                    return chatIDAndMessageID.messageID
                }
                GenarateComponent.logger.info(
                    """
                    UnreadThreadDetail: put read
                    \(channel.id)
                    \(parameters.threadMessage.id)
                    \(messageIDs)
                    \(info.maxPosition)
                    \(info.maxBadgeCount)
                    """
                )
                let maxBadgeCount = max(0, info.maxBadgeCount)
                threadAPI.updateThreadMessagesMeRead(
                    channel: channel,
                    threadId: threadWrapper.thread.value.id,
                    messageIds: messageIDs,
                    maxPositionInThread: info.maxPosition,
                    maxPositionBadgeCountInThread: maxBadgeCount
                )
            })
        let vm = try ThreadDetailViewModel(
            userResolver: resolver,
            chatWrapper: chatWrapper,
            topicGroupPushWrapper: topicGroupPushWrapper,
            threadWrapper: threadWrapper,
            context: context,
            sendMessageAPI: try resolver.resolve(assert: SendMessageAPI.self),
            postSendService: try resolver.resolve(assert: PostSendService.self),
            videoMessageSendService: try resolver.resolve(assert: VideoMessageSendService.self),
            threadAPI: try resolver.resolve(assert: ThreadAPI.self),
            messageAPI: try resolver.resolve(assert: MessageAPI.self),
            draftCache: try resolver.resolve(assert: DraftCache.self),
            pushCenter: try resolver.userPushCenter,
            pushHandlers: pushHandlers,
            is24HourTime: try resolver.resolve(assert: UserGeneralSettings.self).is24HourTime.asObservable(),
            factory: factory,
            threadMessage: parameters.threadMessage,
            useIncompleteLocalData: isFollow, // 已订阅 才需要使用localData策略,
            userGeneralSettings: try resolver.resolve(assert: UserGeneralSettings.self),
            translateService: try resolver.resolve(assert: NormalTranslateService.self),
            readService: readService,
            needUpdateBlockData: parameters.needUpdateBlockData
        )
        let loadType: ThreadDetailLoadType = parameters.loadType
        let vcLoadType: ThreadDetailController.LoadType
        switch loadType {
        case .unread:
            vcLoadType = .unread
        case .position:
            let position = parameters.position ?? -1
            vcLoadType = .position(position)
        case .justReply:
            vcLoadType = .justReply
        case .root:
            vcLoadType = .root
        }

        // 构造vc
        let vc = ThreadDetailController(
            loadType: vcLoadType,
            viewModel: vm,
            context: context,
            currentChatterId: resolver.userID,
            keyboardStartupState: parameters.keyboardStartupState,
            chatAPI: try resolver.resolve(assert: ChatAPI.self),
            menuService: try resolver.resolve(assert: ThreadMenuService.self),
            sourceType: parameters.sourceType,
            isFromFeed: parameters.isFromFeed,
            keyboardBlock: { delegate in
                return try resolver.resolve( // user:checked
                    assert: ThreadKeyboard.self,
                    arguments: delegate,
                    chatWrapper,
                    threadWrapper,
                    false
                )
            },
            dependency: try resolver.resolve(assert: ThreadDependency.self),
            getContainerController: {
                return parameters.containerVC
            },
            specificSource: parameters.specificSource
        )

        context.pageContainer.register(ReactionPageService.self) {
            return ReactionPageService(service: try? resolver.resolve(assert: ReactionService.self))
        }

        context.pageAPI = vc
        context.dataSourceAPI = vm
        context.chatPageAPI = vc

        return vc
    }
}
