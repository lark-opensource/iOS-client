//
//  PushFeedFilterHandler.swift
//  LarkFlag
//
//  Created by phoenix on 2022/7/11.
//

import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkStorage
import Foundation

public struct PushFeedFilterMessage: PushMessage {

    let flagSortingRule: Feed_V1_FlagSortingRule

    init(flagSortingRule: Feed_V1_FlagSortingRule = .default) {
        self.flagSortingRule = flagSortingRule
    }

    var description: String {
        let info = "PushFeedFilterMessage: flagSortingRule \(flagSortingRule)"
        return info
    }
}

final class PushFeedFilterHandler: UserPushHandler {
    static let logger = Logger.log(PushFeedFilterHandler.self, category: "flag.push.feed.filter")

    private var pushCenter: PushNotificationCenter? {
        try? userResolver.userPushCenter
    }
    private lazy var globalStore = KVStores.Flag.global()

    func process(push message: Feed_V1_PushFeedFilterSettings) throws {
        guard let pushCenter = self.pushCenter else { return }
        let pushFeedFilterMessage = PushFeedFilterMessage(flagSortingRule: message.flagSortingRule)
        let flagSortingRule: Int = message.flagSortingRule.rawValue
        globalStore[KVKeys.Flag.sortingRuleKey] = flagSortingRule
        PushFeedFilterHandler.logger.info("LarkFlag: [PushFeedFilter] flagSortingRule = \(message.flagSortingRule)")
        pushCenter.post(pushFeedFilterMessage)
    }
}
