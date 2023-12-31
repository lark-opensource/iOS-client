//
//  DetailPreviewContainerViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/3.
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

final class DetailPreviewContainerViewModel {
    let threadID: String
    private(set) var threadMessage: ThreadMessage?
    private(set) var chat: Chat?
    private(set) var topicGroup: TopicGroup?

    init(threadID: String) {
        self.threadID = threadID
    }

    func ready(threadMessage: ThreadMessage, chat: Chat, topicGroup: TopicGroup) {
        self.threadMessage = threadMessage
        self.chat = chat
        self.topicGroup = topicGroup
    }
    static func fetchBlockData(
        threadID: String,
        strategy: RustPB.Basic_V1_SyncDataStrategy,
        threadAPI: ThreadAPI,
        chatAPI: ChatAPI
    ) -> Observable<DetailBlockData> {
        let observable: Observable<(threadMessages: [ThreadMessage], trackInfo: ThreadRequestTrackInfo)>
        if strategy == .forceServer {
            observable = threadAPI.fetchThreads([threadID],
                                          strategy: .forceServer,
                                          forNormalChatMessage: false)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .catchError({ error in
                DetailPreviewContainerViewModel.logger.error("LarkThread error: fetchThreads forceServer \(threadID)", error: error)
                return threadAPI.fetchThreads([threadID],
                                              strategy: .tryLocal,
                                              forNormalChatMessage: false)
            })
        } else {
            observable = threadAPI.fetchThreads([threadID],
                                          strategy: strategy,
                                          forNormalChatMessage: false)

        }
        return observable.flatMap { (result) -> Observable<DetailBlockData> in
               guard let thread = result.threadMessages.first else {
                    DetailPreviewContainerViewModel.logger.error("LarkThread error: ThreadDetail enter thread \(threadID)")
                    let error = NSError(
                        domain: "fetch thread error",
                        code: 0,
                        userInfo: ["threadID": threadID]
                    ) as Error
                    return .error(error)
                }
                return self.fetchChatAndTopicGroup(
                    thread: thread,
                    threadAPI: threadAPI,
                    chatAPI: chatAPI
                )
        }
    }

    private static let logger = Logger.log(DetailPreviewContainerViewModel.self, category: "LarkThread")

    private static func fetchChatAndTopicGroup(
        thread: ThreadMessage,
        threadAPI: ThreadAPI,
        chatAPI: ChatAPI
    ) -> Observable<DetailBlockData> {
        return threadAPI.fetchChatAndTopicGroup(
            chatID: thread.channel.id,
            forceRemote: false,
            syncUnsubscribeGroups: false
        ).flatMap { (res) -> Observable<DetailBlockData> in
            guard let result = res else {
                // Chat为空时，使用默认TopicGroup并请求Chat数据。
                let topicGroup = TopicGroup.defaultTopicGroup(id: thread.channel.id)
                DetailPreviewContainerViewModel.logger.error("LarkThread error: ThreadDetail can't get chat \(thread.channel.id)")
                return self.fetchChat(
                    thread: thread,
                    topicGroup: topicGroup,
                    chatAPI: chatAPI
                )
            }

            let topicGroup: TopicGroup
            if let topicGroupTmp = result.1 {
                topicGroup = topicGroupTmp
            } else {
                // 兜底方案，服务端接口问题没有返回TopicGroup时，屏蔽依赖TopicGroup的 默认小组/观察者功能，需要保证小组其他功能正常使用。
                DetailPreviewContainerViewModel.logger.error("enter thread chat topicGroup is nil, use default topicgroup \(thread.channel.id)")
                topicGroup = TopicGroup.defaultTopicGroup(id: thread.channel.id)
            }
            return Observable.just((thread, result.chat, topicGroup))
        }
    }

    private static func fetchChat(
        thread: ThreadMessage,
        topicGroup: TopicGroup,
        chatAPI: ChatAPI
    ) -> Observable<DetailBlockData> {
        return chatAPI.fetchChat(by: thread.channel.id, forceRemote: false)
            .flatMap { (chat) -> Observable<DetailBlockData> in
                guard let chat = chat else {
                    DetailPreviewContainerViewModel.logger.error("LarkThread error: ThreadDetail fail to enter in，can't get chat \(thread.channel.id)")
                    let error = NSError(
                        domain: "fetch chat error",
                        code: 1,
                        userInfo: ["chatID": thread.channel.id]
                    ) as Error
                    return .error(error)
                }

                return Observable.just((thread, chat, topicGroup))
            }
    }
}
