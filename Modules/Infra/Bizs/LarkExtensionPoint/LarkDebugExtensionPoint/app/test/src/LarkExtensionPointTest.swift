//
//  LarkExtensionPointTest.swift
//  LarkDebugExtensionPointDevEEUnitTest
//
//  Created by SuPeng on 2/20/20.
//

import Foundation
import XCTest
import LarkDebugExtensionPoint

struct TestCellItem1: DebugCellItem {
    static var initCount: Int = 0

    let title: String = "TestCellItem1"
    let type: DebugCellType = .disclosureIndicator

    init() {
        Self.initCount += 1
    }
}

struct TestCellItem2: DebugCellItem {
    let title: String = "TestCellItem2"
    let type: DebugCellType = .none
}

struct TestCellItem3: DebugCellItem {
    let title: String = "TestCellItem3"
    let type: DebugCellType = .switchButton
}

class LarkExtensionPointTest: XCTestCase {

    func testDebugRegistryWorks() {
        DebugCellItemRegistries = [:]

        DebugRegistry.registerDebugItem(TestCellItem1(), to: .basicInfo)
        DebugRegistry.registerDebugItem(TestCellItem2(), to: .dataInfo)
        DebugRegistry.registerDebugItem(TestCellItem2(), to: .debugTool)

        let expect = expectation(description: "DebugRegistry数目测试")
        DispatchQueue.main.async {
            XCTAssert(DebugCellItemRegistries.keys.count == 3)
            XCTAssert(DebugCellItemRegistries.values.allSatisfy { $0.count == 1 })
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        var initCount = TestCellItem1.initCount
        _ = TestCellItem1()
        assert(TestCellItem1.initCount == initCount + 1)

        // 测试DebugRegistry注册的时候不会初始化DebugCellItem
        DebugCellItemRegistries = [:]

        initCount = TestCellItem1.initCount
        DebugRegistry.registerDebugItem(TestCellItem1(), to: .basicInfo)
        assert(TestCellItem1.initCount == initCount)
    }

}
