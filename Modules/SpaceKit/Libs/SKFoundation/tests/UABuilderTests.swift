//
//  UABuilderTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class UABuilderTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testDarwinVersion() {
        let min = 7
        let res = darwinVersion()
        XCTAssertTrue(res.count > min)
    }

    func testCFNetworkVersion() {
        let expect = "CFNetwork/unknown"
        let res = CFNetworkVersion()
        XCTAssertEqual(res, expect)
    }

    func testDeviceVersion() {
        let res = deviceVersion()
        XCTAssertTrue(res.count > 0)
    }

    func testDeviceName() {
        let res = deviceName()
        XCTAssertTrue(res.count > 0)
    }

    func testAppNameAndVersion() {
        let res = appNameAndVersion()
        XCTAssertTrue(res.count > 0)
    }
}
