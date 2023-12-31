//
//  MentionStateTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/2/21.
//

import Foundation
import XCTest
@testable import LarkIMMention

final class MentionStateTest: XCTestCase {
    
    /// 无结果的报错文案
    func testNoResultErrorString() {
        let error = IMMentionState.VMError.noResult
        XCTAssertEqual(error.errorString, "No results found. Please try another keyword")
    }

    /// 无推荐内容的报错文案
    func testNoRecommendResultErrorString() {
        let error = IMMentionState.VMError.noRecommendResult
        XCTAssertEqual(error.errorString, "No suggestions. You can search for members or Docs")
    }
    /// 网络报错的报错文案
    func testNetworkErrorString() {
        let e = NSError(domain: "error", code: 500)
        let error = IMMentionState.VMError.network(e)
        XCTAssertEqual(error.errorString, "Unable to load. Please check your internet connection and try again")
    }
}
