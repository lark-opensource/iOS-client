//
//  ShareServiceImpl.swift
//  Todo
//
//  Created by 张威 on 2021/1/22.
//

import RxSwift
import TodoInterface
import LarkContainer

final class ShareServiceImpl: ShareService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var shareApi: TodoShareApi?

    // 消息相关依赖
    @ScopedInjectedLazy private var messengerDependency: MessengerDependency?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    private func getIds(from items: [SelectSharingItemBody.SharingItem]) -> ([String], [String], [String]) {
        var (userIds, chatIds, filterIds) = ([String](), [String](), [String]())
        for item in items {
            switch item {
            case .bot(let botId): userIds.append(botId)
            case .user(let userId): userIds.append(userId)
            case .chat(let chatId): chatIds.append(chatId)
            case .generalFilter(let id): filterIds.append(id)
            case .thread, .replyThread: break
            }
        }
        return (userIds, chatIds, filterIds)
    }

    private func getThreadInfos(from items: [SelectSharingItemBody.SharingItem]) -> [Rust.ThreadInfo] {
        var infos = [Rust.ThreadInfo]()
        for item in items {
            switch item {
            case .thread(let threadId, let chatId):
                var info = Rust.ThreadInfo()
                info.threadID = threadId
                info.chatID = chatId
                info.isReplyInThread = false
                infos.append(info)
            case .replyThread(let threadId, let chatId):
                var info = Rust.ThreadInfo()
                info.threadID = threadId
                info.chatID = chatId
                info.isReplyInThread = true
                infos.append(info)
            case .bot, .user, .chat, .generalFilter:
                break
            }
        }
        return infos
    }

    func shareToLark(
        withTodoId todoGuid: String,
        items: [SelectSharingItemBody.SharingItem],
        type: Rust.TodoShareType,
        message: String?,
        completion: ((ShareToLarkResult) -> Void)?
    ) {
        var (userIds, chatIds, _) = getIds(from: items)
        let threadInfos = getThreadInfos(from: items)
        let sender = messengerDependency
        sender?.checkAndCreateChats(byUserIds: userIds)
            .catchErrorJustReturn([])
            .flatMap { [weak self] chatIds2 -> Observable<Rust.TodoShareResult> in
                guard let self = self, let api = self.shareApi else { return .just(.init()) }
                chatIds.append(contentsOf: chatIds2)
                return api.shareTodo(
                    withId: todoGuid,
                    chatIds: chatIds,
                    threadInfos: threadInfos,
                    type: type
                )
            }
            .take(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { result in
                    var blockAlert: ShareToLarkResult.BlockAlert?
                    if !result.failedChats.isEmpty {
                        let restrictedChatNames = result.failedChats.compactMap { failed -> String? in
                            if failed.errorCode == 4_042 {
                                return failed.chatName
                            }
                            return nil
                        }
                        // 分享 Todo 到会话时，会话秘钥被删除导致分享失败
                        let secureKeyDeletedChats = result.failedChats.filter { $0.errorCode == 311_100 }
                        if !restrictedChatNames.isEmpty {
                            let chatNames = restrictedChatNames.joined(separator: I18N.Todo_Common_DivideSymbol)
                            let message = I18N.Todo_Task_RestrictionContent(chatNames)
                            blockAlert = (message: message, preferToast: false)
                        } else if !secureKeyDeletedChats.isEmpty {
                            blockAlert = (message: I18N.Lark_IMSecureKey_KeyDeletedCantSentMessageContactAdmin_PopupText, preferToast: true)
                        } else {
                            blockAlert = (message: I18N.Todo_Task_FailToShare, preferToast: true)
                        }
                    }
                    let messageIds = Array(result.chatID2MessageIds.values) + result.message2Threads.values.map(\.threadID)
                    if let replayMsg = message?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !replayMsg.isEmpty,
                       !messageIds.isEmpty {
                        sender?.replyMessages(
                            byIds: messageIds,
                            with: replayMsg,
                            replyInThreadSet: Set(result.message2Threads.filter { $1.isReplyInThread }.map { $1.threadID })
                        )
                    }
                    completion?(.success(messageIds: messageIds, blockAlert: blockAlert))
                },
                onError: { _ in
                    completion?(.failure(message: I18N.Todo_Task_FailToShare))
                }
            )
    }

}
