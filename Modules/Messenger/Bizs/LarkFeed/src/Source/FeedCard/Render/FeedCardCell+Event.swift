//
//  FeedCardCell+Event.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/22.
//

import Foundation
import LarkFeedBase
import LarkOpenFeed

// MARK: - 事件相关
extension FeedCardCell {
    // 发送给订阅者关心的事件
    func postEvent(eventType: FeedCardEventType, value: FeedCardEventValue) {
        eventListeners[eventType]?.forEach { type in
            guard let componentView = componentViewsMap[type],
                  let view = subViewsMap[type] else { return }
            componentView.postEvent(type: eventType, value: value, object: view)
        }
    }
}
