//
//  UtilsUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/2.
//

import XCTest
import Foundation
import LarkFoundation // Utils

/// Utils新增单测
final class UtilsUnitTest: CanSkipTestCase {
    func testTool() {
        XCTAssertTrue(Utils.isSimulator)
        XCTAssertTrue(((try? Utils.availableMemory) ?? 100) > 0)
        XCTAssertTrue(((try? Utils.averageCPUUsage) ?? 100) > 0)
    }
}
