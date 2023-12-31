//
//  JoinChatViaKoulingHandler.swift
//  LarkChat
//
//  Created by 姜凯文 on 2020/4/23.
//

import Foundation
import LKCommonsLogging
import EENavigator
import LarkContainer
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignToast
import AnimatedTabBar
import LarkTab

struct JoinChatViaKoulingHandler {
    private static let logger = Logger.log(JoinChatViaKoulingHandler.self, category: "JoinChatViaKoulingHandler")

    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(map: [String: String]) {
        guard let token = map["token"], let userID = map["user_id"], let chatID = map["chat_id"], let isInChat = map["already_in_chat"] else {
            JoinChatViaKoulingHandler.logger.info("read koulin failed")
            return
        }
        ChatTracker.trackChatTokenClickThrough()

        guard let window = resolver.navigator.mainSceneWindow else {
            assertionFailure()
            return
        }

        UDToast.showLoading(on: window, disableUserInteraction: false)

        if isInChat == String(describing: true) {
            let body = ChatControllerByIdBody(chatId: chatID)
            var params = NaviParams()
            params.openType = .push
            params.switchTab = Tab.feed.url
            UDToast.removeToast(on: window)
            resolver.navigator.push(body: body, naviParams: params, from: window)
        } else {
            let body = JoinGroupApplyBody(
                chatId: chatID,
                way: .viaLink(inviterId: userID, token: token)
            )
            UDToast.removeToast(on: window)
            resolver.navigator.open(body: body, from: window)
        }
    }
}
