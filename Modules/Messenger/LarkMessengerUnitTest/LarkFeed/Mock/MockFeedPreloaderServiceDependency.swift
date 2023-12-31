//
//  MockFeedPreloaderServiceDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
@testable import LarkFeed

class MockFeedPreloaderServiceDependency: FeedPreloaderServiceDependency {
    var putUserColdBootRequestBuilder: (() -> Void)?

    func putUserColdBootRequest() {
        putUserColdBootRequestBuilder!()
    }
}
