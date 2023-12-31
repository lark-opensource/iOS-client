//
//  Leftslide.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/6/12.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkOpenFeed
import LarkModel
import RustPB

extension FeedTracker {
    struct Leftslide {}
}

extension FeedTracker.Leftslide {
    struct Click {
        static func Top(toShortcut: Bool,
                        feedPreview: FeedPreview,
                        basicData: IFeedPreviewBasicData?,
                        bizData: FeedPreviewBizData?) {
            let click = toShortcut ? "top" : "cancel_top"
            var params: [AnyHashable: Any] = [ "click": click,
                                               "target": "none"]
            params += FeedTracker.FeedCard.BaseParams(feedPreview: feedPreview, basicData: basicData, bizData: bizData)
            Tracker.post(TeaEvent(Homeric.FEED_LEFTSLIDE_DETAIL_CLICK, params: params))
        }

        static func Flag(toFlag: Bool,
                         feedPreview: FeedPreview,
                         basicData: IFeedPreviewBasicData?,
                         bizData: FeedPreviewBizData?) {
            let click = toFlag ? "mark" : "unmark"
            var params: [AnyHashable: Any] =
            [
                "click": click,
                "target": "none",
                "type": feedPreview.chatTotalType,
                "sub_type": feedPreview.chatSubType,
                "chat_id": feedPreview.id
            ]
            params += FeedTracker.FeedCard.BaseParams(feedPreview: feedPreview, basicData: basicData, bizData: bizData)
            Tracker.post(TeaEvent(Homeric.FEED_LEFTSLIDE_DETAIL_CLICK, params: params))
        }
    }
}
