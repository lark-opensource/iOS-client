//
//  SecurityPolicyFallbackResultTest.swift
//  LarkSecurityCompliance-Unit-Tests
//
//  Created by ByteDance on 2023/9/25.
//

import XCTest
import LarkContainer
@testable import LarkSecurityCompliance

let userResolver: UserResolver = Container.shared.getCurrentUserResolver()
let fallbackManager = SceneFallbackResultManager(userResolver: userResolver)

// 兜底Test
final class SecurityPolicyFallbackResultTest: XCTestCase {

    func testFallbackResult() throws {
        // 默认为true
        XCTAssertTrue(fallbackManager[22_222] == true)
        fallbackManager.merge([111_111: false])
        XCTAssertFalse(fallbackManager[111_111])
    }
}
