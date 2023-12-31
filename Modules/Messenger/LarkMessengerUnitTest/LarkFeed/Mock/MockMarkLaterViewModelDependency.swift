//
//  MockMarkLaterViewModelDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkAccountInterface
import RxSwift
import RustPB
import LarkModel
@testable import LarkFeed
@testable import LarkAccount

class MockMarkLaterViewModelDependency: MarkLaterViewModelDependency {
    var getDelayedFeedCardsBuilder: (() -> Observable<[FeedPreview]>)?
    var setFeedPushSubscriptionBuilder: ((_ on: Bool, _ scene: Feed_V1_SubscribeFeedPushSceneRequest.Scene) -> Void)?

    // 获取列表数据
    func getDelayedFeedCards() -> Observable<[FeedPreview]> {
        return getDelayedFeedCardsBuilder!()
    }

    func setFeedPushSubscription(_ on: Bool, for scene: Feed_V1_SubscribeFeedPushSceneRequest.Scene) {
        setFeedPushSubscriptionBuilder!(on, scene)
    }

    var userSpace: UserSpaceService {
        UserSpace()
    }
}
