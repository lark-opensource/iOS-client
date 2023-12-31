//
// Created by bytedance on 2020/5/19.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB

class BoxCellMockFeedAPI: MockFeedAPIBaseImpl {

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

        // Box是靠parentID关联的，这也是为什么parentID > 0就被过滤掉的原因
        let feedsToReturn = min(maxFeedsLimit - curFeedIndex, count)

        // 仅在inbox中提供 .box 类型feeds
        if feedType != .inbox || feedsToReturn <= 0 || (pullType == .loadMore && feedCardID == nil) {
            // 拉取Done时
            // 已经提供足够的feeds时
            // inbox尝试拉取更多时
            //      这三种情况下，返回结束标志
            return getFeedCardsReachEnd()
        }

        // nil 表示拉取inbox中的数据，则返回1个BoxFeed cell，搭配(feedsToReturn - 1)个.chat类型的feeds
        guard let feedCardID = feedCardID else {
            // 返回一个box feed + 随机个(feedsToReturn - 1)数量的feeds
            return getInitialBox(feedsToReturn: feedsToReturn)
        }

        // 这里表示加载更多Box内部feeds - 需要累积超过10个feeds才会返回这里创建的feeds
        return getFeedCardsWithGenerator(feedType: feedType,
            count: count,
            pairGenerator: {
                MockFeedsGenerator.getRandomPairWithType(.chat)
            }) { feedType, index in

            // 后续获取的就是Box里面的分页加载，同一返回 .chat 类型
            var feed = MockFeedsGenerator.getRandomFeed(feedType, index)
            feed.name = "Box chat #\(index)"
            feed.parentCardID = feedCardID
            feed.chatRole = .member

            return feed
        }
    }

    ///
    /// 加载消息盒子的内容，1个BoxCell + 若干个ChatCells，ChatCell均属于BoxCell
    /// - Parameter feedsToReturn: 一定是大于等于1
    ///
    func getInitialBox(feedsToReturn: Int) -> Observable<GetFeedCardsResult> {
        Observable<GetFeedCardsResult>.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }

            var feeds = [FeedCardPreview]()

            var boxFeed = MockFeedsGenerator.getRandomFeed(.inbox, 1)
            boxFeed.pair = MockFeedsGenerator.getRandomPairWithType(.box)
            boxFeed.parentCardID = "0"
            boxFeed.chatRole = .member

            feeds.append(boxFeed)
            self.curFeedIndex += 1

            if feedsToReturn > 1 {
                for _ in 1..<feedsToReturn {
                    let pair = MockFeedsGenerator.getRandomPairWithType(.chat)
                    var feed = MockFeedsGenerator.getRandomFeed(.inbox, self.curFeedIndex)
                    feed.pair = pair
                    feed.name = "Box chat #\(self.curFeedIndex)"
                    // 其他feeds使用 boxFeed 作为parent
                    feed.parentCardID = boxFeed.pair.id
                    feed.chatRole = .member
                    feeds.append(feed)

                    self.curFeedIndex += 1
                }
            }

            let cursorPair = MockFeedsGenerator.getCursorPairForFeeds(feeds)
            let ret = GetFeedCardsResult(feeds: feeds, nextCursor: Int(cursorPair.minCursor) - 1, cursors: [cursorPair])
            observer.onNext(ret)

            return Disposables.create()
        }
    }

    ///
    /// getNewBoxFeedCards()是同 自动消息盒子 相关的接口，这个功能没有分页加载的逻辑
    ///
    override func getNewBoxFeedCards() -> Observable<[FeedCardPreview]> {
        _ = super.getNewBoxFeedCards()

        return Observable<[FeedCardPreview]>.create { [weak self] ob in
            // 如果未生成任何feeds，就直接返回
            guard let self = self, !self.feedsGenerated.isEmpty else {
                return Disposables.create()
            }

            let feedsCount = self.feedsGenerated.count
            // 随机选几个作为autochat生成的
            let prefixCount = Int.random(in: 1...feedsCount)
            let autoChats = [FeedCardPreview](self.feedsGenerated.shuffled().prefix(prefixCount))
            ob.onNext(autoChats)
            return Disposables.create()
        }
    }
}
