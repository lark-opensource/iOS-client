//
//  AAAPreTestUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/24.
//

import XCTest
import Foundation
@testable import LarkSendMessage

/// 此case保证在其他case前执行，用于拉取一些必要配置
final class AAAPreTestUnitTest: XCTestCase {
    /// 提前进行自动登录
    func testAutoLogin() {
        let expectation = LKTestExpectation(description: "@test auto login")
        AutoLoginHandler().autoLogin {
            expectation.fulfill()
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        // 如果登陆都超时了，直接跳过所有case执行
        CanSkipTestCase.allCase = expectation.autoFulfill
    }

    /// 不使用Debug视频配置，使用Settings下发的
    func testCloseVideoDebugEnable() {
        VideoDebugKVStore.innerVideoDebugEnable = false
    }
}
