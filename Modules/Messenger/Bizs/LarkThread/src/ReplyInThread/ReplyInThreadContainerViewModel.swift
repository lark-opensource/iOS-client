//
//  ReplyInThreadContainerViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2022/4/21.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkMessageCore
import LarkSDKInterface
import LKCommonsLogging
import LarkContainer
import RustPB

final class ReplyInThreadContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let threadID: String
    private(set) var threadMessage: ThreadMessage?
    private(set) var chat: Chat?
    @ScopedInjectedLazy private var feedAPI: FeedAPI?

    init(userResolver: UserResolver, threadID: String) {
        self.userResolver = userResolver
        self.threadID = threadID
    }

    func ready(threadMessage: ThreadMessage, chat: Chat) {
        self.threadMessage = threadMessage
        self.chat = chat
    }

    static func fetchBlockData(
        threadID: String,
        threadAPI: ThreadAPI,
        strategy: RustPB.Basic_V1_SyncDataStrategy,
        chat: Chat?,
        chatAPI: ChatAPI
    ) -> Observable<ReplyInThreadDetailBlockData> {
        let observable: Observable<(threadMessages: [ThreadMessage], trackInfo: ThreadRequestTrackInfo)>
        if strategy == .forceServer {
            observable = threadAPI.fetchThreads([threadID], strategy: strategy, forNormalChatMessage: true)
                .timeout(.seconds(5), scheduler: MainScheduler.instance).catchError({ error in
                    Self.logger.error("LarkThread error: ReplyInThread enter error，fetchThreads forceServer \(threadID)", error: error)
                    return threadAPI.fetchThreads([threadID], strategy: .tryLocal, forNormalChatMessage: true)
                })
        } else {
            observable = threadAPI.fetchThreads([threadID], strategy: strategy, forNormalChatMessage: true)
        }

        return observable.flatMap { (result) -> Observable<ReplyInThreadDetailBlockData> in
            guard let thread = result.threadMessages.first else {
                Self.logger.error("LarkThread error: ReplyInThread enter error，miss thread \(threadID)")
                let error = NSError(
                    domain: "fetch thread error",
                    code: 0,
                    userInfo: ["threadID": threadID]
                ) as Error
                return .error(error)
            }

            if let chat = chat {
                return Observable.just((thread, chat))
            } else {
                return self.fetchChat(
                    thread: thread,
                    chatAPI: chatAPI
                )
            }
        }
    }

    private static let logger = Logger.log(ReplyInThreadContainerViewModel.self, category: "LarkThread")

    private static func fetchChat(
        thread: ThreadMessage,
        chatAPI: ChatAPI
    ) -> Observable<ReplyInThreadDetailBlockData> {
        return chatAPI.fetchChat(by: thread.channel.id, forceRemote: false)
            .flatMap { (chat) -> Observable<ReplyInThreadDetailBlockData> in
                guard let chat = chat else {
                    Self.logger.error("LarkThread error: ReplyInThread enter error，miss chat \(thread.channel.id)")
                    let error = NSError(
                        domain: "fetch chat error",
                        code: 1,
                        userInfo: ["chatID": thread.channel.id]
                    ) as Error
                    return .error(error)
                }

                return Observable.just((thread, chat))
            }
    }

    func removeFeedCard() {
        var channel = RustPB.Basic_V1_Channel()
        channel.type = .chat
        channel.id = self.threadID
        _ = self.feedAPI?.removeFeedCard(channel: channel, feedType: .thread).subscribe()
    }
}
