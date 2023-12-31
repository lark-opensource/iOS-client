//
//  ZZZPostTestUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/6/15.
//

import XCTest
@testable import LarkSendMessage

/// 此case保证在其他case后执行，用于做一些清理工作
final class ZZZPostTestUnitTest: XCTestCase {

    /// 所有用例执行完毕后自动退登测试帐号
    func testAutoLogout() {
        let expectation = LKTestExpectation(description: "@test auto logout")
        LogoutHandler().logout {
            expectation.fulfill()
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
    }
}
