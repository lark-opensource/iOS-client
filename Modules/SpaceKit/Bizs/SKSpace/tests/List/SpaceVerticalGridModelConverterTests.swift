//
//  SpaceVerticalGridModelConverterTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/6/16.
//

import Foundation
@testable import SKSpace
import SKCommon
import SKFoundation
import XCTest
import SKResource
import SKDrive
import LarkContainer

class SpaceVerticalGridModelConverterTests: XCTestCase {

    override class func setUp() {
        DriveModule().setup()
        super.setUp()
    }
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    private func convert(entry: SpaceEntry, isReachable: Bool = true) -> SpaceVerticalGridItem {
        let netMonitor = MockNetworkStatusMonitor()
        netMonitor.isReachable = isReachable
        return SpaceVerticalGridModelConverter.convert(entries: [entry], netMonitor: netMonitor).first!
    }

    // 这里逐个测试 SpaceVerticalGridItem 的各个属性生成逻辑是否符合预期

    func testConvertEnable() {
        let offlineEnableEntry = SpaceEntry(type: .doc,
                                            nodeToken: "fake_mock-node-token",
                                            objToken: "fake_mock-obj-token")
        let offlineDisableEntry = SpaceEntry(type: .unknownDefaultType,
                                             nodeToken: "mock-unknown-token",
                                             objToken: "mock-unknown-token")
        var item = convert(entry: offlineEnableEntry)
        XCTAssertTrue(item.enable)
        item = convert(entry: offlineDisableEntry)
        XCTAssertTrue(item.enable)

        item = convert(entry: offlineEnableEntry, isReachable: false)
        XCTAssertTrue(item.enable)
        item = convert(entry: offlineDisableEntry, isReachable: false)
        XCTAssertFalse(item.enable)
    }

    func testTitle() {
        let mockName = "mock-name"
        let entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateName(mockName)
        var item = convert(entry: entry)
        XCTAssertEqual(item.title, mockName)
        XCTAssertEqual(item.entry, entry)
    }

    func testGridIcon() {
        let entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        let item = convert(entry: entry)
        XCTAssertEqual(item.iconType, .icon(image: entry.quickAccessImage))
    }
}
