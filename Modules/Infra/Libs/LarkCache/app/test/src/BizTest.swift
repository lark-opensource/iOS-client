//
//  BizTest.swift
//  LarkCacheDev
//
//  Created by Supeng on 2020/8/17.
//

import Foundation
import XCTest
import LarkCache

class BizTest: XCTestCase {
    func testBiz() {
        XCTAssertEqual(TestBiz1.fullPath, "messenger/test1")
        XCTAssertEqual(TestBiz2.fullPath, "messenger/test1/test2")
    }
}

enum Messenger: Biz {
    static var parent: Biz.Type?
    static var path: String = "messenger"
}

enum TestBiz1: Biz {
    static var parent: Biz.Type? = Messenger.self
    static var path: String = "test1"
}

enum TestBiz2: Biz {
    static var parent: Biz.Type? = TestBiz1.self
    static var path: String = "test2"
}
