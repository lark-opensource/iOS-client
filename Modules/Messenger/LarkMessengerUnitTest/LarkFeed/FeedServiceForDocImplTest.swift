//
//  FeedServiceForDocImplTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
@testable import LarkFeed

class FeedServiceForDocImplTest: XCTestCase {
    var docService: FeedServiceForDocImpl!
    var mockDependency: MockFeedServiceForDocDependency!

    override func setUp() {
        mockDependency = MockFeedServiceForDocDependency()
        docService = FeedServiceForDocImpl(mockDependency)
        super.setUp()
    }

    override func tearDown() {
        mockDependency = nil
        docService = nil
        super.tearDown()
    }

    // MARK: - isFeedCardShortcut
    func test_isFeedCardShortcut() {
        mockDependency.isFeedCardShortcutBuilder = { feedId -> Bool in
            return true
        }

        XCTAssert(docService.isFeedCardShortcut(feedId: "1") == true)
    }
}
