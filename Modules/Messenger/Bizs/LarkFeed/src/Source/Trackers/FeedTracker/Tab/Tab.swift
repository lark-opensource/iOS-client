//
//  Tab.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/30.
//

import Foundation
import LKCommonsTracker
import Homeric

/// tab相关埋点
extension FeedTracker {
    struct Tab {}
}

extension FeedTracker.Tab {
    struct Click {
        /// 双击
        static func Double() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "message_double_click"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.NAVIGATION_MAIN_CLICK, params: params))
        }
    }
}
