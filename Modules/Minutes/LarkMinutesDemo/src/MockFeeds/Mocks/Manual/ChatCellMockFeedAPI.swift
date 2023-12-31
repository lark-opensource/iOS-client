//
//  ChatCellOnlyMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by bytedance on 2020/5/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB

class ChatCellMockFeedAPI: MockFeedAPIBaseImpl {
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
                MockFeedsGenerator.getRandomPairWithType(.chat)
            }) { feedType, index in

            var feed = MockFeedsGenerator.getRandomFeed(feedType, index)
            feed.avatarKey = "834e000a1c1e7e1d71df"  // 暂时复用固定的avatarKey
            feed.name = "Chat Cell #\(index)"
            feed.chatType = .p2P
            feed.chatRole = .member  // 如果是其他role，就会触发 HideChannelAlert
            feed.entityStatus = Bool.random() ? .read : .unread  // 仅支持这两种状态
            feed.parentCardID = "0"
            return feed
        }
    }
}
