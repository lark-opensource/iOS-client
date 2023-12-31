//
//  PushTopicGroupTabBadgeHandler.swift
//  LarkSDK
//
//  Created by lizhiqiang on 2019/12/9.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import LKCommonsLogging

final class PushTopicGroupTabBadgeHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private static var logger = Logger.log(PushTopicGroupTabBadgeHandler.self, category: "LarkThread")

    func process(push message: RustPB.Im_V1_PushTopicGroupTabBadge) {
        PushTopicGroupTabBadgeHandler.logger.info("tabBadge: hasNewContent: \(message.hasNewContent_p)")
        // replay: true. Guarantee to get the latest data when start observe.
        // replay: true. 因为时序问题，为了保证在开始监听时能拿到最新的的一条数据。
        self.pushCenter?.post(PushTopicGroupTabBadge(hasNewContent: message.hasNewContent_p), replay: true)
    }
}
