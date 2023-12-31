//
//  ThreadPostForwardDetailHander.swift
//  LarkThread
//
//  Created by liluobin on 2021/6/16.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Swinject
import RustPB
import LarkCore
import LarkModel
import EENavigator
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LKCommonsLogging
import LarkOpenChat
import LarkContainer
import class AppContainer.BootLoader
import LarkNavigator

final class threadWrappperItem: ThreadPushWrapper {
    let thread: BehaviorRelay<RustPB.Basic_V1_Thread>
    init(thread: RustPB.Basic_V1_Thread) {
        self.thread = BehaviorRelay<RustPB.Basic_V1_Thread>(value: thread)
    }
}

final class ThreadPostForwardDetailHander: UserTypedRouterHandler {
    static let logger = Logger.log(ThreadPostForwardDetailHander.self, category: "Module.ThreadPostForwardDetailHander")
    let disposeBag: DisposeBag = DisposeBag()
    func handle(_ body: ThreadPostForwardDetailBody, req: EENavigator.Request, res: Response) throws {
        var type: ThreadDetailBaseViewController.Type?
        var openWithMergeForwardContent = true //true表示使用MergeForwardContent的数据，false表示用MessageThread的数据

        let resolver = self.userResolver
        if let messageThread = body.message.mergeForwardInfo?.messageThread {
            type = ReplyInThreadForwardDetailViewController.self
            openWithMergeForwardContent = false
        }
        if (body.openWithMergeForwardContentPrior || openWithMergeForwardContent),
           let content = body.message.content as? MergeForwardContent,
           let thread = content.thread {
            type = thread.isReplyInThread ? ReplyInThreadForwardDetailViewController.self : ThreadPostForwardDetailViewController.self
            openWithMergeForwardContent = true
        }

        guard let type = type else {
            res.end(error: nil)
            Self.logger.error("ThreadPostForwardDetailHander miss info, messageID: \(body.message.id), messageType: \(body.message.type)")
            return
        }
        // 构造menumanager
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        // cell factory
        // 构造context
        let context = ThreadDetailContext(
            resolver: resolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
        )
        // 构造菜单
        let messageActionContext = PrivateThreadMessageActionContext(parent: Container(parent: BootLoader.container),
                                                                     store: Store(),
                                                                     originMergeForwardId: body.originMergeForwardId,
                                                                     interceptor: IMMessageActionInterceptor(),
                                                                     userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        PrivateThreadMessageActionModule.onLoad(context: messageActionContext)
        let actionModule = PrivateThreadMessageActionModule(context: messageActionContext)
        let messageMenuService = MessageMenuServiceImp(chat: body.chat,
                                                    actionModule: actionModule)
        context.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }

        if type == ReplyInThreadForwardDetailViewController.self {
            let forwardMessage: Message?
            let rootMessage: Message
            var replyMessages: [Message]
            let replyCount: Int
            var fromChatChatters = [String: Chatter]()
            let reactionSnapshots: [String: Basic_V1_MergeForwardContent.MessageReaction]
            var thread: RustPB.Basic_V1_Thread?
            if !openWithMergeForwardContent,
               let mergeForwardInfo = body.message.mergeForwardInfo,
               let messageThread = mergeForwardInfo.messageThread {
                forwardMessage = nil
                rootMessage = body.message
                replyMessages = messageThread.messages.map({ msg in
                    Message.transform(pb: msg)
                })
                replyCount = Int(messageThread.replyCount)
                if let chatters = mergeForwardInfo.fromChatChatters {
                    for key in chatters.keys {
                        if let pb = chatters[key] {
                            fromChatChatters[key] = Chatter.transform(pb: pb)
                        }
                    }
                }
                reactionSnapshots = messageThread.reactionSnapshots
                thread = RustPB.Basic_V1_Thread()
                thread?.id = rootMessage.id
            } else {
                guard let content = body.message.content as? MergeForwardContent,
                      !content.messages.isEmpty else {
                    res.end(error: nil)
                    assertionFailure("ThreadPostForwardDetailHander")
                    return
                }
                forwardMessage = body.message
                replyMessages = content.messages
                rootMessage = replyMessages.removeFirst()
                replyCount = replyMessages.count
                if let chatters = content.fromChatChatters {
                    for key in chatters.keys {
                        if let pb = chatters[key] {
                            fromChatChatters[key] = Chatter.transform(pb: pb)
                        }
                    }
                }
                reactionSnapshots = content.messageReactionInfo
                thread = content.thread
            }

            let viewModel = ReplyInThreadForwardDetailViewModel(userResolver: resolver,
                                                                originMergeForwardId: body.originMergeForwardId,
                                                                context: context,
                                                                chat: body.chat,
                                                                thread: thread ?? RustPB.Basic_V1_Thread(),
                                                                forwardMessage: forwardMessage,
                                                                rootMessage: rootMessage,
                                                                replyMessages: replyMessages,
                                                                replyCount: replyCount,
                                                                fromChatChatters: fromChatChatters,
                                                                reactionSnapshots: reactionSnapshots)
            let vc = ReplyInThreadForwardDetailViewController(viewModel: viewModel)
            context.pageAPI = vc
            context.dataSourceAPI = viewModel
            context.chatPageAPI = vc
            messageActionContext.container.register(ChatMessagesOpenService.self) { [weak vc] _ -> ChatMessagesOpenService in
                return vc ?? DefaultChatMessagesOpenService()
            }
            messageMenuService.delegate = vc
            res.end(resource: vc)
        } else {
            let viewModel = ThreadPostForwardDetailViewModel(userResolver: resolver,
                                                             originMergeForwardId: body.originMergeForwardId,
                                                             context: context,
                                                             chat: body.chat,
                                                             message: body.message)
            let vc = ThreadPostForwardDetailViewController(viewModel: viewModel)
            context.pageAPI = vc
            context.dataSourceAPI = viewModel
            context.chatPageAPI = vc
            messageActionContext.container.register(ChatMessagesOpenService.self) { [weak vc] _ -> ChatMessagesOpenService in
                return vc ?? DefaultChatMessagesOpenService()
            }
            messageMenuService.delegate = vc
            res.end(resource: vc)
        }
    }
}
