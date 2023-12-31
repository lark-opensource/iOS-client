//
//  MsgThreadDetailPreviewHandler.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/6.
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
import LarkSceneManager
import LarkContainer
import LarkNavigator

final class MsgThreadDetailPreviewHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    private static let logger = Logger.log(MsgThreadDetailPreviewHandler.self, category: "LarkThread.MsgThreadDetailPreview")
    func handle(_ body: MsgThreadDetailPreviewByIDBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)

        let getDetailController = { (vc, threadMessage, chat) in
            return try MsgThreadDetailPreviewGenarateComponent.generateViewController(
                parameters: MsgThreadDetailPreviewGenarateComponent.Parameters(
                    resolver: resolver,
                    loadType: body.loadType,
                    position: body.position,
                    threadMessage: threadMessage,
                    chat: chat,
                    containerVC: vc
                )
            )
        }

        let viewModel = MsgThreadDetailPreviewContainerViewModel(
            userResolver: resolver,
            threadID: body.threadId
        )
        let intermediateStateControl = InitialDataAndViewControl<ReplyInThreadDetailBlockData, Void>(
            blockPreLoadData: MsgThreadDetailPreviewContainerViewModel.fetchBlockData(
                threadID: body.threadId,
                threadAPI: threadAPI,
                strategy: .tryLocal,
                chat: nil,
                chatAPI: chatAPI
            )
        )

        let vc = MsgThreadDetailPreviewContainerViewController(
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

private struct MsgThreadDetailPreviewGenarateComponent {
    private static let logger = Logger.log(MsgThreadDetailPreviewGenarateComponent.self, category: "LarkThread")

    struct Parameters {
        let resolver: UserResolver
        let loadType: ThreadDetailLoadType
        let position: Int32?
        let threadMessage: ThreadMessage
        let chat: Chat
        weak var containerVC: UIViewController?
    }

    static fileprivate func generateViewController(parameters: Parameters) throws -> UIViewController {
        let resolver = parameters.resolver
        let pushCenter = try resolver.userPushCenter
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
        context.trackParams = [PageContext.TrackKey.sceneKey: ChatFromWhere.default()]
        context.isPreview = true

        // cell factory
        let factory = ThreadReplyMessageCellViewModelFactory(
            threadWrapper: threadWrapper,
            context: context,
            registery: ReplyInThreadSubFactoryRegistery(context: context),
            threadMessage: parameters.threadMessage,
            cellLifeCycleObseverRegister: ThreadDetailCellLifeCycleObseverRegister()
        )

        let isFollow = threadWrapper.thread.value.isFollow
        let threadAPI = try resolver.resolve(assert: ThreadAPI.self)
        var channel = RustPB.Basic_V1_Channel()
        channel.id = parameters.chat.id
        channel.type = .chat
        let vm = MsgThreadDetailPreviewViewModel(
            userResolver: resolver,
            chatWrapper: chatWrapper,
            threadWrapper: threadWrapper,
            context: context,
            threadAPI: threadAPI,
            is24HourTime: try resolver.resolve(assert: UserGeneralSettings.self).is24HourTime.asObservable(),
            factory: factory,
            threadMessage: parameters.threadMessage,
            useIncompleteLocalData: isFollow // 已订阅 才需要使用localData策略
        )
        let loadType: ThreadDetailLoadType = parameters.loadType
        let vcLoadType: MsgThreadDetailPreviewViewController.LoadType
        /// 产品这里希望如果用户没有看到过replyInthread里面的评论，跳转跟消息而不是第一条评论
        let readPositionBadgeCount = parameters.threadMessage.thread.readPositionBadgeCount
        let unReadComments = (readPositionBadgeCount == 0)
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
        let vc = MsgThreadDetailPreviewViewController(
            loadType: vcLoadType,
            viewModel: vm,
            context: context,
            chatAPI: try resolver.resolve(assert: ChatAPI.self),
            dependency: try resolver.resolve(assert: ThreadDependency.self),
            getContainerController: {
                return parameters.containerVC
            }
        )
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
        context.pageAPI = vc
        context.dataSourceAPI = vm
        context.chatPageAPI = vc
        return vc
    }
}
