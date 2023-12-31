//
//  List.swift
//  LarkFeedEvent
//
//  Created by xiaruzhen on 2022/10/9.
//

import Foundation
import LKCommonsTracker
import Homeric

extension EventTracker {
    struct List {}
}

extension EventTracker.List {
    static func View(count: Int, listCount: [String: Int]) {
        var params = ["event_cnt": String(count)]
        listCount.forEach { (biz: String, count: Int) in
            params["\(biz)_cnt"] = String(count)
        }
        Tracker.post(TeaEvent("navigation_event_list_view",
                              params: params))
    }
}
