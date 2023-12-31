//
//  RustManagerTests.swift
//  LarkRustClientDevEEUnitTest
//
//  Created by liuwanlin on 2020/3/18.
//

import Foundation
import XCTest
@testable import LarkRustClient

class RustManagerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        UserDefaults.standard.set(nil, forKey: MockClientConfig.defaultsKey)
    }

    func testConfig() {
        let socketURL = "http://lark.com"
        let config = MockClientConfig(socketURL: socketURL, channel: "good", proxyRequests: [10000])
        MockClientConfig.save(config: config)
        let localConfig = MockClientConfig.load()
        XCTAssert(localConfig != nil && localConfig?.socketURL == socketURL)
    }

    func testManager() {
        let manager = MockRustManager(config: nil)
        XCTAssert(manager.socketConnected == false)

        let manager2 = MockRustManager(
            config: MockClientConfig(
                socketURL: "http://lark.com",
                channel: "test",
                proxyRequests: [10000]
            )
        )
        XCTAssert(manager2.socketConnected == false && manager2.proxyRequests.contains(10000))
    }
}
