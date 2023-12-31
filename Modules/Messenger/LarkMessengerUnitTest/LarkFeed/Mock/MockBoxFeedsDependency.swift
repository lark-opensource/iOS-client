//
//  MockBoxFeedsDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import LarkModel
@testable import LarkFeed

class MockBoxFeedsDependency: BoxFeedsDependency {
    var getFeedCardsBuilder: ((_ feedType: Basic_V1_FeedCard.FeedType,
                                _ pullType: FeedPullType,
                                _ feedCardID: String?,
                                _ cursor: Int,
                                _ count: Int) -> Observable<GetFeedCardsResult>)?

    var cleanNewBoxFeedCardsBuilder: ((_ isNoticeHidden: Bool) -> Observable<Void>)?

    func getFeedSetting() -> Observable<Settings_V1_FeedSetting> {
        return .just(Settings_V1_FeedSetting())
    }

    func getNewBoxFeedCards() -> Observable<[FeedPreview]> {
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        return .just([feed1, feed2, feed3])
    }

    func cleanNewBoxFeedCards(isNoticeHidden: Bool) -> Observable<Void> {
        return cleanNewBoxFeedCardsBuilder!(isNoticeHidden)
    }

    func getFeedCards(feedType: Basic_V1_FeedCard.FeedType,
                      pullType: FeedPullType,
                      feedCardID: String?,
                      cursor: Int,
                      count: Int) -> Observable<GetFeedCardsResult> {
        getFeedCardsBuilder!(feedType, pullType, feedCardID, cursor, count)
    }

    func setFeedPushSubscription(_ on: Bool,
                                 for scene: Feed_V1_SubscribeFeedPushSceneRequest.Scene) -> Observable<Void> {
        return .just(())
    }
}
