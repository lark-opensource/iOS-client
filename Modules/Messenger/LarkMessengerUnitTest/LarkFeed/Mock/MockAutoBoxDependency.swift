//
//  MockAutoBoxDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
@testable import LarkFeed

class MockAutoBoxDependency: AutoBoxDependency {
    func getNewBoxFeedCards() -> Observable<[FeedPreview]> {
        var feed1 = buildFeedPreview()
        feed1.parentCardID = "10"
        feed1.id = "10"
        var feed2 = buildFeedPreview()
        feed2.parentCardID = "20"
        feed2.id = "20"
        var feed3 = buildFeedPreview()
        feed3.parentCardID = "30"
        feed3.id = "30"
        return .just([feed1, feed2, feed3])
    }
}
