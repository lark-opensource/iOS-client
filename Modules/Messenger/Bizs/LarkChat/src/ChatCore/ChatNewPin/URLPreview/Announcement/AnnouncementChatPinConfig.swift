//
//  AnnouncementChatPinConfig.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/24.
//

import Foundation
import LarkOpenChat
import LKCommonsLogging
import RustPB
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface

struct AnnouncementChatPinConfig {
    private static let logger = Logger.log(ChatNewPinCardListViewModel.self, category: "Module.IM.ChatPin")

    static func onClick(useOpendoc: Bool,
                        pinURL: String?,
                        cardURL: Basic_V1_URL?,
                        targetVC: UIViewController,
                        chat: Chat,
                        userResolver: UserResolver,
                        pinId: Int64) {
        Self.logger.info("chatPinCardTrace useOpendoc: \(useOpendoc) chat: \(chat.id) pinId: \(pinId)")
        if useOpendoc {
            var targetURL: URL?
            if let urlStr = cardURL?.tcURL, !urlStr.isEmpty, let url = try? URL.forceCreateURL(string: urlStr) {
                targetURL = url
            } else if let pinURL = pinURL, !pinURL.isEmpty, let url = try? URL.forceCreateURL(string: pinURL) {
                targetURL = url
            }
            guard let targetURL = targetURL else {
                Self.logger.error("chatPinCardTrace chat: \(chat.id) pinId: \(pinId) announcement docURL is empty")
                return
            }
            let parameters = [
                "chat_id": chat.id,
                "from": "group_tab_notice",
                "open_type": "announce"
            ]
            // 发送群公告已读请求/
            (try? userResolver.resolve(assert: ChatAPI.self))?.readChatAnnouncement(by: chat.id, updateTime: chat.announcement.updateTime).subscribe().dispose()
            userResolver.navigator.open(targetURL.append(parameters: parameters), context: ["showTemporary": false], from: targetVC)
        } else {
            let body = ChatOldAnnouncementBody(chatId: chat.id)
            userResolver.navigator.push(body: body, from: targetVC)
        }
    }
}
