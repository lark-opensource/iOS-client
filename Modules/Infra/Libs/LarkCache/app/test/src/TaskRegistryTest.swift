//
//  TaskRegistryTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/8/17.
//

import Foundation
import XCTest
@testable import LarkCache

class TaskRegistryTest: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTaskRegistry() {
        XCTAssertTrue(!CleanTaskRegistry.allTasks.isEmpty)
        XCTAssertTrue(CleanTaskRegistry.allTasks.first!.task() is DefaultCacheCleanTask)

        CleanTaskRegistry.register(cleanTask: SimpleCleanTask())
        XCTAssertTrue(CleanTaskRegistry.allTasks.last!.task() is SimpleCleanTask)
    }
}
