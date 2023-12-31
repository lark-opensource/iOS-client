//
//  DoubleClickTabbarMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by 夏汝震 on 2020/5/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

class DoubleClickTabbarMockFeedAPI: ChatCellMockFeedAPI {

    private let pullMaxTimes = 3
    private var pullTimes = 0
    override func getNextUnreadFeedCardsBy(_ id: String?) -> Observable<NextUnreadFeedCardsResult> {

        /*
         如果该api返回了数据，那么数据集合中必定存在未读/稍后处理类型的数据
         //case1:当当前未读数据距离下一个未读数据的index diff 很大时，可能会拉取过多的数据
         //case2:当最后一屏数据存在多个未读/稍后处理时，UI可能不会发生跳转行为
         //case3:每次双击都会拉取数据，直到没有未读/稍后处理相关数据
         */
        _ = super.getNextUnreadFeedCardsBy(id)
        if pullTimes >= pullMaxTimes {
            // 限制多少次可以拉取完包含未读的数据，这里是限制了三次
            return getFeedCardsReachEnd().map { (feedCardsResult) -> NextUnreadFeedCardsResult in
                return NextUnreadFeedCardsResult(previews: feedCardsResult.feeds, nextCursor: feedCardsResult.nextCursor, continuousCursors: feedCardsResult.cursors)
            }
        }
        pullTimes += 1
        //  每次生成5个，生成的数据里必定至少有一个是未读/稍后处理
        return getFeedCardsWithGenerator(feedType: .inbox, count: 5, pairGenerator: { () -> CardPair in
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
        }.map { (feedCardsResult) -> NextUnreadFeedCardsResult in
            return NextUnreadFeedCardsResult(previews: feedCardsResult.feeds, nextCursor: feedCardsResult.nextCursor, continuousCursors: feedCardsResult.cursors)
        }
    }
}
