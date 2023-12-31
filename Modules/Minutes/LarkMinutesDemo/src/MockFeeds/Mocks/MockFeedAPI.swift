//
//  MockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by bytedance on 2020/5/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift

public protocol MockFeedAPI: FeedAPI {
    // 涉及Feeds的都需要这个Observable，故拓展一下
    init(webSocketStatusPushOb: Observable<PushWebSocketStatus>,
         maxFeedsLimit: Int,
         maxShortcutsLimit: Int)
}
