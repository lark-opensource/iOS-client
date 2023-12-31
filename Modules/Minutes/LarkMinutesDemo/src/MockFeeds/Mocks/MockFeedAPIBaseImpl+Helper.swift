//
// Created by bytedance on 2020/5/19.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkSDKInterface
import LarkModel
import RustPB

extension MockFeedAPIBaseImpl {
    ///
    /// 返回Feeds到底的信号
    ///
    func getFeedCardsReachEnd() -> Observable<GetFeedCardsResult> {
        Observable<GetFeedCardsResult>.create { observer in
            let ret = GetFeedCardsResult(feeds: [], nextCursor: 0, cursors: [])
            observer.onNext(ret)
            return Disposables.create()
        }
    }

    /// 返回调用不同类型的Generator生成的Feeds, 第一个参数代表.inbox or .done, 第二个参数是 feed index
    typealias FeedContentGenerator = (FeedCard.FeedType, Int) -> FeedCardPreview
    typealias CardPairGenerator = () -> CardPair

    ///
    /// 生成一组按照rankTime降序排列的Feeds
    ///
    /// - Parameters:
    ///   - feedType:
    ///   - count:
    ///   - pairGenerator:
    ///   - contentGenerator:
    /// - Returns:
    func getFeedCardsWithGenerator(feedType: FeedCard.FeedType,
                                   count: Int,
                                   pairGenerator: @escaping CardPairGenerator,
                                   contentGenerator: @escaping FeedContentGenerator) -> Observable<GetFeedCardsResult> {
        // 返回给客户端小于等于count个feeds
        let feedsToReturn = min(maxFeedsLimit - curFeedIndex, count)

        // 如果达到生成feeds的上限，就返回结束状态, 让APP中的加载递归停止
        if feedsToReturn <= 0 {
            return getFeedCardsReachEnd()
        }

        return Observable<GetFeedCardsResult>.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }

            var feeds = [FeedCardPreview]()

            for _ in 0..<feedsToReturn {
                let pair = pairGenerator()
                var feed = contentGenerator(feedType, self.curFeedIndex)
                self.curFeedIndex += 1
                feed.pair = pair
                feeds.append(feed)

                // 记录所有生成的Feeds
                self.feedsGenerated.append(feed)
            }

            // 根据feeds计算有效CursorPair
            let cursorPair = MockFeedsGenerator.getCursorPairForFeeds(feeds)
            let ret = GetFeedCardsResult(feeds: feeds, nextCursor: Int(cursorPair.minCursor) - 1, cursors: [cursorPair])

            // 当加载超过100个Feeds时，触发随机delay 2-7秒，这样便于看到加载更多的效果
            if self.curFeedIndex >= 100 {
                // 注意这里没有去利用LarkFeed.LoadConfig，因为access level，而且LoadConfig确实可以不public，保持其内聚性
                let delay = TimeInterval(UInt.random(in: 2...7))
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
                    DispatchQueue.main.async {
                        observer.onNext(ret)
                    }
                }
            } else {
                observer.onNext(ret)
            }

            return Disposables.create()
        }
    }
}
