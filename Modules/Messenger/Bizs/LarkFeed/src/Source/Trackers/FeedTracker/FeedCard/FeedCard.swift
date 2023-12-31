//
//  FeedCard.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/9/4.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkOpenFeed
import LarkModel

extension FeedTracker.FeedCard {
    /// 长按 Feed 的展示埋点
    static func View() {
    }
}

extension FeedTracker.FeedCard {
    struct Click {
        /// 点击某条 open feed(不区分新类型)
        public static func AppFeed(feedPreview: FeedPreview,
                                   basicData: IFeedPreviewBasicData,
                                   bizData: FeedPreviewBizData,
                                   iPadStatus: String?) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "leftclick_app_feed_card"
            if let iPadStatus = iPadStatus {
                params["status_ipad"] = iPadStatus
            }
            params += FeedTracker.FeedCard.BaseParams(feedPreview: feedPreview,
                                            basicData: basicData,
                                            bizData: bizData)
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        }
    }
}
