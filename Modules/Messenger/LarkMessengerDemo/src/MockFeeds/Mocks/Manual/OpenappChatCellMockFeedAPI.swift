//
// Created by bytedance on 2020/5/19.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkFeatureGating

class OpenappChatCellMockFeedAPI: MockFeedAPIBaseImpl {
    // .openappChat 类型的Cell受FG控制，还未全量
    // 如果fg未打开 FeatureGatingKey.feedOpenAppV2，则FeedListViewModel里面会过滤掉这种类型的feeds

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

        // 强制开启fg
        // 首次拉取到的feeds是不会被立即显示的，然后因为预加载触发了后续的拉取，即使拉取到0 elements，也会触发UITableView刷新，结果就刷出来了...
        LarkFeatureGating.shared.updateFeatureBoolValue(for: FeatureGatingKey.feedOpenAppV2.rawValue, value: true)
        LarkFeatureGating.shared.lockFeatureValue(for: .feedOpenAppV2)

        // 返回模拟的数据
        return getFeedCardsWithGenerator(feedType: feedType,
            count: count,
            pairGenerator: {
                MockFeedsGenerator.getRandomPairWithType(.openappChat)
            }) { feedType, index in

            var feed = MockFeedsGenerator.getRandomFeed(feedType, index)
            feed.name = "OpenappChat Cell #\(index)"
            feed.parentCardID = "0"
            feed.chatRole = .member
            feed.openAppCard.openAppType = Bool.random() ? .miniApp : .botChat

            // for mini app
            let url = "https://www.bytedance.com/"
            feed.openAppCard.appNotificationSchema = url
            feed.iosSchema = url
            feed.openAppCard.lastNotificationSeqID = MockFeedsGenerator.getRandomID(10)
            feed.lastNotificationSeqID = MockFeedsGenerator.getRandomID(5)

            // for bot chat
            feed.openAppCard.chatID = MockFeedsGenerator.getRandomID()

            return feed
        }
    }
}
