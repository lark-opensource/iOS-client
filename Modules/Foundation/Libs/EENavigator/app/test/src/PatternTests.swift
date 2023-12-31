//
//  PatternTests.swift
//  EENavigatorDevEEUnitTest
//
//  Created by zhangwei on 2023/8/24.
//

import Foundation
import XCTest
@testable import EENavigator

class PatternTests: XCTestCase {

    func testSchemeAndHostLowercased() {
        var pattern = "HTTP://TOUTIAO.com/ABC?Name=lwl".asPattern()
        var lowercased = pattern.standardized().rawValue
        XCTAssert(lowercased == "http://toutiao.com/ABC?Name=lwl")

        pattern = "/ABC?Name=lwl".asPattern()
        lowercased = pattern.standardized().rawValue
        XCTAssert(lowercased == "/ABC?Name=lwl")

        pattern = "127.0.0.1:8080".asPattern()
        lowercased = pattern.standardized().rawValue
        XCTAssert(lowercased == "127.0.0.1:8080")

        pattern = "/chat/by/:id".asPattern()
        lowercased = pattern.standardized().rawValue
        XCTAssert(lowercased == "/chat/by/:id")

        pattern = "HTTP://FeiShu.com/chat/by/:id".asPattern()
        lowercased = pattern.standardized().rawValue
        XCTAssert(lowercased == "http://feishu.com/chat/by/:id")
    }

}
