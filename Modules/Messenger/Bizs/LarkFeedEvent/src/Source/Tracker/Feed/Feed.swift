//
//  Feed.swift
//  LarkFeedEvent
//
//  Created by xiaruzhen on 2022/10/9.
//

import Foundation
import LKCommonsTracker
import Homeric

extension EventTracker {
    struct Feed {}
}

extension EventTracker.Feed {
    static func View(eventId: String, type: String) {
        let params = ["event_id": eventId,
                      "type": type]
        Tracker.post(TeaEvent("feed_event_bar_mobile_view",
                              params: params))
    }
}

extension EventTracker.Feed {
    struct Click {
        static func Title(eventId: String, type: String) {
            let params = ["click": "event_title",
                          "target": "none",
                          "event_id": eventId,
                          "type": type]
            Tracker.post(TeaEvent("feed_event_bar_mobile_click",
                                  params: params))
        }

        static func Close(eventId: String, type: String) {
            let params = ["click": "close",
                          "target": "none",
                          "event_id": eventId,
                          "type": type]
            Tracker.post(TeaEvent("feed_event_bar_mobile_click",
                                  params: params))
        }

        static func EnterList(eventId: String, type: String) {
            let params = ["click": "enter_list",
                          "target": "none",
                          "event_id": "navigation_event_list_view",
                          "type": type]
            Tracker.post(TeaEvent("feed_event_bar_mobile_click",
                                  params: params))
        }
    }
}
