//
//  InitialInstallationMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by bytedance on 2020/5/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB

class InitialInstallationMockFeedAPI: MockFeedAPIBaseImpl {
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
            pairGenerator: MockFeedsGenerator.getRandomPair,
            contentGenerator: MockFeedsGenerator.getRandomFeed)
    }
}
