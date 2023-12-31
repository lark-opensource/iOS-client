//
// Created by bytedance on 2020/5/19.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB

class OpenappCellMockFeedAPI: MockFeedAPIBaseImpl {
    override func getFeedCards(feedType: FeedCard.FeedType,
                               pullType: FeedPullType,
                               feedCardID: String?,
                               cursor: Int,
                               count: Int) -> Observable<GetFeedCardsResult> {
        _ = super.getFeedCards(feedType: feedType,
            pullType: pullType,
            feedCardID: feedCardID,
            cursor: cursor,
            count: count)

        return getFeedCardsWithGenerator(feedType: feedType,
            count: count,
            pairGenerator: {
                MockFeedsGenerator.getRandomPairWithType(.openapp)
            }) { feedType, index in

            var feed = MockFeedsGenerator.getRandomFeed(feedType, index)
            feed.name = "Openapp Cell #\(index)"
            feed.parentCardID = "0"
            feed.chatRole = .member
            // 打开webview controller
            let url = "https://www.bytedance.com/"
            feed.openAppCard.appNotificationSchema = url
            feed.iosSchema = url
            feed.openAppCard.lastNotificationSeqID = MockFeedsGenerator.getRandomID(10)
            feed.lastNotificationSeqID = MockFeedsGenerator.getRandomID(5)
            return feed
        }
    }
}
