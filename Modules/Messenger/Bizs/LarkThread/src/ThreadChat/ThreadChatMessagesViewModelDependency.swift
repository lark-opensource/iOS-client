//
//  ThreadChatMessagesViewModelDataProviderImpl.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/14.
//

import Foundation
import RxSwift
import Swinject
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessageCore
import RustPB
import LarkContainer

final class ThreadChatMessagesViewModelDependency: UserResolverWrapper {
    let userResolver: UserResolver
    let chatAPI: ChatAPI
    let userUniversalSettingService: UserUniversalSettingService
    let chatId: String
    let threadAPI: ThreadAPI
    let messageAPI: MessageAPI
    /// 标题更新 message变更
    let threadObservable: Observable<[RustPB.Basic_V1_Thread]>
    /// 假消息 新来的消息
    let threadMessageObservable: Observable<[ThreadMessage]>
    /// 消息实体 更新
    let messagesObservable: Observable<[Message]>
    let myThreadsReplyPromptObservable: Observable<PushMyThreadsReplyPrompt>
    let is24HourTime: Observable<Bool>
    var currentChatterID: String { userResolver.userID }
    let readService: ChatMessageReadService
    let urlPreviewService: MessageURLPreviewService
    init(userResolver: UserResolver, chatId: String, readService: ChatMessageReadService) throws {
        self.userResolver = userResolver
        self.chatId = chatId
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.userUniversalSettingService = try userResolver.resolve(assert: UserUniversalSettingService.self)
        self.threadAPI = try userResolver.resolve(assert: ThreadAPI.self)
        self.messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        let pushCenter = try userResolver.userPushCenter
        self.urlPreviewService = try userResolver.resolve(assert: MessageURLPreviewService.self)
        self.myThreadsReplyPromptObservable = pushCenter.observable(for: PushMyThreadsReplyPrompt.self)
            .filter({ (prompt) -> Bool in
                return chatId == prompt.groupId
            })
        self.threadObservable = pushCenter.observable(for: PushThreads.self)
            .map({ (push) -> [RustPB.Basic_V1_Thread] in
                return push.threads.filter({ (thread) -> Bool in
                    return thread.channel.id == chatId
                })
            })
            .filter({ (threads) -> Bool in
                return !threads.isEmpty
            })
        self.threadMessageObservable = pushCenter.observable(for: PushThreadMessages.self)
            .map({ (push) -> [ThreadMessage] in
                return push.messages
                    .filter({ thread -> Bool in
                        return thread.channel.id == chatId
                    })
            })
            .filter({ (threadMessages) -> Bool in
                return !threadMessages.isEmpty
            })
        self.messagesObservable = pushCenter.observable(for: PushChannelMessages.self)
            .map({ (push) -> [Message] in
                return push.messages.filter({ (msg) -> Bool in
                    return msg.channel.id == chatId
                })
            })
            .filter({ (msgs) -> Bool in
                return !msgs.isEmpty
            })
        self.is24HourTime = try userResolver.resolve(assert: UserGeneralSettings.self).is24HourTime.asObservable()
        self.readService = readService
    }
}
