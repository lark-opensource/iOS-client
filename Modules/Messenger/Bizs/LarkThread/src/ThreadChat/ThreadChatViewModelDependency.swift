//
//  ThreadChatViewModelDependency.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/19.
//

import Foundation
import Swinject
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import LarkContainer
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkSendMessage

final class ThreadChatViewModelDependency: UserResolverWrapper {
    let userResolver: UserResolver
    let chatId: String
    let deleteMeFromChannelDriver: Driver<PushRemoveMeFromChannel>
    let localLeaveGroupChannel: Driver<PushLocalLeaveGroupChannnel>
    let feedAPI: FeedAPI
    let chatAPI: ChatAPI
    let messageAPI: MessageAPI
    let userGeneralSettings: UserGeneralSettings
    let translateService: NormalTranslateService
    let offlineChatUpdateDriver: Driver<Chat>
    let postSendService: PostSendService
    let pushCenter: PushNotificationCenter
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var modelService: ModelService?

    init(userResolver: UserResolver, chatId: String) throws {
        self.userResolver = userResolver
        self.chatId = chatId
        self.userGeneralSettings = try userResolver.resolve(assert: UserGeneralSettings.self)
        self.translateService = try userResolver.resolve(assert: NormalTranslateService.self)
        self.feedAPI = try userResolver.resolve(assert: FeedAPI.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        self.pushCenter = try userResolver.userPushCenter
        self.postSendService = try userResolver.resolve(assert: PostSendService.self)

        self.deleteMeFromChannelDriver = pushCenter
            .driver(for: PushRemoveMeFromChannel.self)
            .filter { (push) -> Bool in
                return push.channelId == chatId
            }

        self.localLeaveGroupChannel = pushCenter.driver(for: PushLocalLeaveGroupChannnel.self)
            .filter({ (push) -> Bool in
                return push.channelId == chatId
            })

        self.offlineChatUpdateDriver = pushCenter.driver(for: PushOfflineChats.self)
            .map({ (push) -> Chat? in
                return push.chats.first(where: { (chat) -> Bool in
                    return chat.id == chatId
                })
            })
            .compactMap { $0 }
    }
}
