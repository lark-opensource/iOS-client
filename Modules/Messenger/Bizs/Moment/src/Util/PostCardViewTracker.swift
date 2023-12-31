//
//  FeedCardViewTracker.swift
//  Moment
//
//  Created by zc09v on 2021/3/17.
//

import Foundation
import UIKit
import Homeric
import LKCommonsTracker

final class PostCardViewTracker {
    var displayPostIds: Set<String> = Set()
    private var trackedPostIds: Set<String> = Set()
    private let source: Tracer.FeedCardViewSource

    init(source: Tracer.FeedCardViewSource) {
        self.source = source
    }

    func trackCommunityFeedCardView() {
        var toTracePostIds = self.displayPostIds
        toTracePostIds.subtract(trackedPostIds)
        for postId in toTracePostIds {
            trackedPostIds.insert(postId)
            Tracker.post(TeaEvent(Homeric.COMMUNITY_FEED_CARD_VIEW, params: [
                "source": source.rawValue,
                "post_id": postId
            ]))
        }
    }
}
