//
//  ChatDataProviderProtocol.swift
//  LarkChat
//
//  Created by ByteDance on 2023/9/4.
//

import Foundation
import RxSwift
import LarkSDKInterface
import LarkModel
import LarkContainer
import LarkCore
import LarkMessageBase
import LarkMessengerInterface
import UIKit
import LarkMessageCore
import LarkTracing
import UniverseDesignToast
import RustPB

protocol ChatDataProviderProtocol: UserResolverWrapper {
    var identify: String { get } //仅用作日志，用于区分不同的Provider实现

    var messagesObservable: Observable<[Message]> { get }

    func fetchMessages(
        position: Int32,
        pullType: PullMessagesType,
        redundancyCount: Int32,
        count: Int32,
        expectDisplayWeights: Int32?,
        redundancyDisplayWeights: Int32?
    ) -> Observable<GetChatMessagesResult>

    func fetchSpecifiedMessage(position: Int32,
                               redundancyCount: Int32,
                               count: Int32,
                               expectDisplayWeights: Int32?,
                               redundancyDisplayWeights: Int32?
    ) -> RxSwift.Observable<LarkSDKInterface.GetChatMessagesResult>

    func fetchMissedMessages(positions: [Int32]) -> Observable<[Message]>

    func getMessageIdsByPosition(startPosition: Int32,
                                 count: Int32) -> Observable<Im_V1_GetMessageIdsByPositionResponse>

    static func fetchChat(by source: FetchChatSource) -> Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)>

    static func fetchFirstScreenMessages(
        chatId: String,
        positionStrategy: ChatMessagePositionStrategy?,
        userResolver: UserResolver,
        screenHeight: CGFloat,
        fetchChatData: Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)>
    ) throws -> Observable<GetChatMessagesResult>

    init(chatContext: ChatContext,
         chatWrapper: ChatPushWrapper,
         pushCenter: PushNotificationCenter)
}

extension ChatDataProviderProtocol {
    static func fetchChat(by source: FetchChatSource) -> Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)> {
        switch source {
        case .chat(let chat):
            return .just((chat, fetchChatCost: 0, fetchChatterCost: 0))
        case .chatId(let chatId, let chatAPI, let chatterAPI, let strategy):
            let forceRemote: Bool
            switch strategy {
            case .`default`: forceRemote = false
            case .forceRemote: forceRemote = true
            }
            var start: CFTimeInterval = CACurrentMediaTime()
            var fetchChatsOB = chatAPI
                .fetchChats(by: [chatId], forceRemote: forceRemote)
            if forceRemote {
                // 如果是强制从远端拉取chat，增加超时任务
                fetchChatsOB = fetchChatsOB.timeout(.seconds(5), scheduler: MainScheduler.instance)
            }
            return fetchChatsOB
                .do(onSubscribed: {
                    start = CACurrentMediaTime()
                    LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.fetchChatCost, parentName: LarkTracingUtil.firstRender)
                })
                .flatMap({ (chats) -> Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)> in
                    if let chat = chats[chatId] {
                        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.fetchChatCost)
                        let fetchChatCost = ChatKeyPointTracker.cost(startTime: start)
                        if chat.type == .p2P, chat.chatter == nil {
                            start = CACurrentMediaTime()
                            return chatterAPI.getChatter(id: chat.chatterId).map({ (chatter) -> (Chat, fetchChatCost: Int64, fetchChatterCost: Int64) in
                                chat.chatter = chatter
                                return (chat,
                                        fetchChatCost: fetchChatCost,
                                        fetchChatterCost: ChatKeyPointTracker.cost(startTime: start))
                            })
                        }
                        return .just((chat, fetchChatCost: fetchChatCost, fetchChatterCost: 0))
                    } else {
                        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.fetchChatCost, error: true)
                        return .error(FetchChatError.missChat)
                    }
                }).catchError({ _ -> Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)> in
                    guard forceRemote else {
                        return .error(FetchChatError.missChat)
                    }
                    // 降级处理：如果从远端获取chat失败，则取本地的chat
                    let info = "chatTrace/chatInit/fetchChat. chatId: \(chatId)"
                    if let chat = chatAPI.getLocalChat(by: chatId) {
                        ChatMessagesViewModel.logger.info("\(info), getLocalChat success")
                        return .just((chat, fetchChatCost: 0, fetchChatterCost: 0))
                    } else {
                        ChatMessagesViewModel.logger.error("\(info), getLocalChat failed")
                        return .error(FetchChatError.missChat)
                    }
                })
        }
    }
}

enum FetchChatSource {
    case chat(Chat)
    case chatId(String, ChatAPI, ChatterAPI, ChatSyncStrategy)
}

enum FetchMessagePosition {
    case position(Int32?)
    case latestMessagePosition(chatOB: Observable<Chat>)
}

enum FetchChatError: Error {
    case missChat
}
