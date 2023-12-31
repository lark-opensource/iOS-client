//
//  FeedPluginTracker.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2022/5/27.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import Homeric

final class FeedPluginTracker {
    static let log = Logger.log(FeedPluginTracker.self, category: "FeedPlugin")
}

extension FeedPluginTracker {
    struct Guide {}
}

extension FeedPluginTracker.Guide {
    static func cleanBadgeView(unReadCount: Int) {
        var params: [AnyHashable: Any] = [:]
        params["badge"] = unReadCount
        Tracker.post(TeaEvent(Homeric.FEED_CLEAN_BADGE_GUIDE_MOBILE_VIEW, params: params))
    }
}
