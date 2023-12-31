//
//  ComputeDoneUnreadBadgeMockFeedAPI.swift
//  Lark
//
//  Created by 夏汝震 on 2020/5/28.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB

class ComputeDoneUnreadBadgeMockFeedAPI: LoadShortcutsMockFeedAPI {

    /*
     通过 unreadCount 设置 filter 列表中【已完成】(done)的未读个数
     */
    override func computeDoneUnreadBadge() -> Observable<ComputeDoneCardsResponse> {
        Observable<ComputeDoneCardsResponse>.create { observer in
            var response = ComputeDoneCardsResponse()
            response.unreadCount = 32 // > 0 显示未读数字
            response.hasUnreadDot_p = true // unreadCount<=0 并且hasUnreadDot_p为true，显示灰色圆点
            observer.onNext(response)
            return Disposables.create()
        }
    }

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
            feed.avatarKey = "834e000a1c1e7e1d71df"
            feed.name = "Chat Cell #\(index)"
            feed.chatType = .p2P
            feed.chatRole = .member
            feed.entityStatus = .unread //
            feed.parentCardID = "0"
            return feed
        }
    }
}
