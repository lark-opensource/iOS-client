//
//  ResetTaskManagerTests.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
@testable import LarkSettingsBundle

class ResetTaskManagerTests: XCTestCase {

    override func setUp() {
        ResetTaskManager.shared.tasks.removeAll()
    }

    func testTask() {
        let taskRun = expectation(description: "task run 3")
        taskRun.expectedFulfillmentCount = 4
        var result = ""
        ResetTaskManager.register(task: { complete in
            result += "2"
            taskRun.fulfill()
            complete()
        })

        ResetTaskManager.register(task: { complete in
            result += "2"
            taskRun.fulfill()
            complete()
        })

        ResetTaskManager.register(task: { complete in
            result += "3"
            taskRun.fulfill()
            complete()
        }, priority: .low)

        ResetTaskManager.register(task: { complete in
            result += "1"
            taskRun.fulfill()
            complete()
        }, priority: .high)

        let complete = expectation(description: "reset complete")
        ResetTaskManager.reset {
            XCTAssertNotEqual(Thread.current, Thread.main)
            complete.fulfill()
        }
        wait(for: [taskRun, complete], timeout: 2)
        let taskCount = ResetTaskManager.shared.tasks.reduce(0) { (sum, task) -> Int in
            return sum + task.value.count
        }
        XCTAssertEqual(taskCount, 4)
        XCTAssertEqual(result, "1223")
    }

    func testLowTask() {
        singleTask(.low)
    }

    func testDefaultTask() {
        singleTask(.default)
    }

    func testHighTask() {
        singleTask(.high)
    }

    func singleTask(_ priority: ResetTaskManager.Priority) {
        let task = expectation(description: "task run \(priority)")
        ResetTaskManager.register(task: { complete in
            task.fulfill()
            complete()
        }, priority: priority)

        let reset = expectation(description: "reset complete \(priority)")
        ResetTaskManager.reset {
            reset.fulfill()
        }
        wait(for: [task, reset], timeout: 1)
    }
}
