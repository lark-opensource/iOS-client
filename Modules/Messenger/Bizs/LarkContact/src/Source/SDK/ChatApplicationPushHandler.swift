//
//  ChatApplicationPushHandler.swift
//  LarkSDK
//
//  Created by 姚启灏 on 2018/8/16.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkModel
import LKCommonsLogging

final class ChatApplicationPushHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatApplications) throws {
        let applications = message.applications
            .map { (application) -> ChatApplication in
                return ChatApplication.transform(pb: application)
            }
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(
            PushChatApplicationGroup(applications: applications, hasMore: false)
        )
    }
}

// ChatApplicationBadge
public typealias PushChatApplicationBadege = ChatApplicationBadege
extension ChatApplicationBadege: PushMessage {}

final class ChatApplicationBadgePushHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    static var logger = Logger.log(ChatApplicationBadgePushHandler.self, category: "Rust.PushHandler")

    func process(push message: RustPB.Im_V1_GetChatApplicationBadgeResponse) throws {
        ChatApplicationBadgePushHandler.logger.info(
            "chatBadge: \(message.chatBadge), friendBadge: \(message.friendBadge)")
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(
            PushChatApplicationBadege(chatBadge: Int(message.chatBadge), friendBadge: Int(message.friendBadge))
        )
    }
}
