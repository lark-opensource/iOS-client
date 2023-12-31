//
//  FeedPreview+Extensions.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/8/5.
//

import Foundation
import LarkModel

public extension FeedPreview {
    // 加急
    // TODO: open feed 属于chat逻辑，不应该放在feed里
    var isUrgent: Bool {
        return Feed.Feature.urgentEnabled && !self.preview.chatData.urgents.isEmpty
    }
}
