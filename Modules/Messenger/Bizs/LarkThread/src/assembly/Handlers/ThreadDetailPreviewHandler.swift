//
//  ThreadDetailPreviewHandler.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/3.
//

import UIKit
import Foundation
import RxSwift
import Swinject
import LarkCore
import LarkModel
import EENavigator
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import AsyncComponent
import RustPB
import LarkSuspendable
import LarkContainer
import LarkNavigator

final class ThreadDetailPreviewHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private static let logger = Logger.log(ThreadDetailPreviewHandler.self, category: "LarkThread")
    private let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: ThreadDetailPreviewByIDBody, req: EENavigator.Request, res: Response) throws {
        ThreadPerformanceTracker.startEnter()
        let resolver = self.userResolver
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)

        let getDetailController = { (vc, threadMessage, chat, topicGroup) in
            return try ThreadDetailPreviewGenarateComponent.generateViewController(
                parameters: ThreadDetailPreviewGenarateComponent.Parameters(
                    resolver: resolver,
                    loadType: body.loadType,
                    position: body.position,
                    threadMessage: threadMessage,
                    chat: chat,
                    topicGroup: topicGroup,
                    needUpdateBlockData: false,
                    containerVC: vc
                )
            )
        }

        let viewModel = DetailPreviewContainerViewModel(
            threadID: body.threadId
        )
        let intermediateStateControl = InitialDataAndViewControl<DetailBlockData, Void>(
            blockPreLoadData: DetailPreviewContainerViewModel.fetchBlockData(
                threadID: body.threadId,
                strategy: .tryLocal,
                threadAPI: threadAPI,
                chatAPI: chatAPI
            )
        )

        let vc = DetailPreviewContainerController(
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

private struct ThreadDetailPreviewGenarateComponent {
    private static let logger = Logger.log(ThreadDetailPreviewGenarateComponent.self, category: "LarkThread")

    struct Parameters {
        let resolver: UserResolver
        let loadType: ThreadDetailLoadType
        let position: Int32?
        let threadMessage: ThreadMessage
        let chat: Chat
        let topicGroup: TopicGroup
        let needUpdateBlockData: Bool
        weak var containerVC: UIViewController?
    }

    static func generateViewController(parameters: Parameters) throws -> UIViewController {
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
        context.isPreview = true

        // cell factory
        let factory = ThreadDetailMessageCellViewModelFactory(
            threadWrapper: threadWrapper,
            context: context,
            registery: ThreadDetailSubFactoryRegistery(context: context),
            threadMessage: parameters.threadMessage,
            cellLifeCycleObseverRegister: ThreadDetailCellLifeCycleObseverRegister()
        )

        let isFollow = threadWrapper.thread.value.isFollow
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        var channel = RustPB.Basic_V1_Channel()
        channel.id = parameters.chat.id
        channel.type = .chat
        let chat = chatWrapper.chat.value
        let vm = ThreadDetailPreviewViewModel(
            userResolver: resolver,
            chatWrapper: chatWrapper,
            topicGroupPushWrapper: topicGroupPushWrapper,
            threadWrapper: threadWrapper,
            context: context,
            threadAPI: threadAPI,
            is24HourTime: try resolver.resolve(assert: UserGeneralSettings.self).is24HourTime.asObservable(),
            factory: factory,
            threadMessage: parameters.threadMessage,
            useIncompleteLocalData: isFollow, // 已订阅 才需要使用localData策略,
            needUpdateBlockData: parameters.needUpdateBlockData
        )
        let loadType: ThreadDetailLoadType = parameters.loadType
        let vcLoadType: ThreadDetailPreviewController.LoadType
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
        let vc = ThreadDetailPreviewController(
            loadType: vcLoadType,
            viewModel: vm,
            context: context,
            currentChatterId: resolver.userID,
            chatAPI: try resolver.resolve(assert: ChatAPI.self),
            dependency: try resolver.resolve(assert: ThreadDependency.self),
            getContainerController: {
                return parameters.containerVC
            }
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
