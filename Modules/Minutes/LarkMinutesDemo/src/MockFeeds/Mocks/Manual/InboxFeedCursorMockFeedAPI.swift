//
// Created by bytedance on 2020/5/21.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

class InboxFeedCursorMockFeedAPI: ChatCellMockFeedAPI {
    var recordedMaxCursor: Int?

    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        // 20秒后触发1次
        let timer = Timer(timeInterval: 20, repeats: false) { _ in
            var message = Feed_V1_PushFeedCursor()
            message.feedCardID = ""  // 为空表示非消息盒子的cursors
            message.feedType = .inbox

            var cursor = Feed_V1_Cursor()
            // 当前触发，意味着是拉取到新feeds
            cursor.maxCursor = Int64(Date().timeIntervalSince1970)
            self.recordedMaxCursor = Int(cursor.maxCursor)
            message.count = 10
            cursor.minCursor = cursor.maxCursor - Int64(message.count - 1)  // 保持cursor连续
            message.cursor = cursor

            MockInterceptionManager.shared.postMessage(command: .pushFeedCursor, message: message)
        }

        RunLoop.main.add(timer, forMode: .common)

        return ret
    }

    override func getFeedCards(feedType: FeedCard.FeedType,
                               pullType: FeedPullType,
                               feedCardID: String?,
                               cursor: Int,
                               count: Int) -> Observable<GetFeedCardsResult> {
        // 首次加载触发super的逻辑，或者后续非PushFeedCursor的加载也触发
        if cursor == 0 || cursor != (self.recordedMaxCursor ?? -1) {
            return super.getFeedCards(feedType: feedType, pullType: pullType, feedCardID: feedCardID, cursor: 0, count: count)
        }

        print("""
              \(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)
              - feedType: \(feedType) - pullType: \(pullType) - feedCardID: \(feedCardID ?? "")
              - cursor: \(cursor) - count: \(count)
              """)

        // 后续更新cursor拉取的feeds
        return getFeedCardsWithGenerator(feedType: feedType,
            count: count,
            pairGenerator: { MockFeedsGenerator.getRandomPairWithType(.chat) }) { feedType, index in

            var feed = MockFeedsGenerator.getRandomFeed(feedType, index)
            feed.avatarKey = "834e000a1c1e7e1d71df"  // 暂时复用固定的avatarKey
            feed.name = "Push Cursor #\(index)"
            feed.chatType = .p2P
            feed.chatRole = .member
            feed.entityStatus = Bool.random() ? .read : .unread
            feed.parentCardID = "0"
            // 这里的index是generated index，一直在累加的，不是当前批次的，它只能保证后一个比前一个大，但不是从0开始的
            feed.displayTime = Int64(Date().timeIntervalSince1970) - Int64(index)
            feed.rankTime = feed.displayTime
            feed.updateTime = feed.displayTime
            return feed
        }
    }
}
