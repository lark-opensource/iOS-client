//
//  PushTopicGroupHandler.swift
//  LarkSDK
//
//  Created by lizhiqiang on 2020/1/6.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import LKCommonsLogging

final class PushTopicGroupHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private static let logger = Logger.log(PushTopicGroupHandler.self, category: "LarkThread")

    func process(push message: RustPB.Im_V1_PushTopicGroups) {
        let itemIDs = message.items.compactMap { (item) -> String? in
            return item.itemID
        }
        let topicGroups = TopicGroup.transform(fromEntity: message.entity, topicGroupIDs: itemIDs)

        PushTopicGroupHandler.logger.info("LarkThread push PushTopicGroupHandler: \(itemIDs)")
        if topicGroups.isEmpty {
            return
        }

        self.pushCenter?.post(LarkSDKInterface.PushTopicGroups(topicGroups: topicGroups))
    }
}
