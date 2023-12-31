//
//  ChatVMDependency.swift
//  Lark
//
//  Created by zc09v on 2018/4/10.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import LarkModel
import LarkCore
import Swinject
import LarkFeatureGating
import LarkSDKInterface
import LarkMessengerInterface
import LarkAppLinkSDK
import LarkWaterMark
import LarkAccountInterface
import LarkMessageCore

final class ChatVMDependency: UserResolverWrapper {
    let userResolver: UserResolver
    let pinBadgeEnable: Bool
    let isMeetingBannerEnabled: Bool

    lazy var deleteMeFromChannelDriver: Driver<PushRemoveMeFromChannel> = {
        let chatId = self.chatId
        return pushCenter
            .driver(for: PushRemoveMeFromChannel.self)
            .filter { (push) -> Bool in
                return push.channelId == chatId
            }
    }()
    lazy var localLeaveGroupChannel: Driver<PushLocalLeaveGroupChannnel> = {
        let chatId = self.chatId
        return pushCenter.driver(for: PushLocalLeaveGroupChannnel.self)
            .filter({ (push) -> Bool in
                return push.channelId == chatId
            })
    }()
    lazy var pinReadStatusObservable: Observable<PushChatPinReadStatus> = {
        let chatId = self.chatId
        return pushCenter.observable(for: PushChatPinReadStatus.self)
            .filter({ (push) -> Bool in
                return push.chatId == chatId
            })
    }()

    lazy var offlineChatUpdateDriver: Driver<Chat> = {
        let chatId = self.chatId
        return pushCenter.driver(for: PushOfflineChats.self)
            .map({ (push) -> Chat? in
                return push.chats.first(where: { (chat) -> Bool in
                    return chat.id == chatId
                })
            })
            .compactMap { $0 }
    }()

    lazy var is24HourTime: Driver<Bool> = {
        return self.userGeneralSettings?.is24HourTime.asDriver() ?? Driver.just(false)
    }()

    // 导致IM会话的引导banner状态发生变化的实时事件的推送
    var pushContactApplicationBannerAffectEvent: Observable<PushContactApplicationBannerAffectEvent> {
        return self.pushCenter.observable(for: PushContactApplicationBannerAffectEvent.self)
    }

    // 添加好友成功push
    var pushAddContactSuccessMessage: Observable<PushAddContactSuccessMessage> {
        return self.pushCenter.observable(for: PushAddContactSuccessMessage.self)
    }

    var currentAccountChatterId: String { userResolver.userID }
    let tenantId: String
    let chatId: String
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var pinAPI: PinAPI?
    @ScopedInjectedLazy var feedAPI: FeedAPI?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var externalContactsAPI: ExternalContactsAPI?
    @ScopedInjectedLazy var chatService: ChatService?
    @ScopedInjectedLazy var appLinkService: AppLinkService?
    @ScopedInjectedLazy var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy var byteViewService: ChatByteViewDependency?
    @ScopedInjectedLazy var translateService: NormalTranslateService?
    @ScopedInjectedLazy var userRelationService: UserRelationService?
    @ScopedInjectedLazy var contactControlService: ContactControlService?
    @ScopedInjectedLazy var userUniversalSettingService: UserUniversalSettingService?

    let pushCenter: PushNotificationCenter

    init(userResolver: UserResolver, chat: Chat) throws {
        self.pushCenter = try userResolver.userPushCenter
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        self.userResolver = userResolver
        self.chatId = chat.id
        self.tenantId = passportUserService.user.tenant.tenantID
        self.pinBadgeEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .pinBadgeEnable)) && !ChatNewPinConfig.checkEnable(chat: chat, self.userResolver.fg)
        self.isMeetingBannerEnabled = userResolver.fg.staticFeatureGatingValue(with: .init(key: .byteviewMeetingBanner))
    }
}
