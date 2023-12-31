//
//  TaskTest.swift
//  FlowChartDevEEUnitTest
//
//  Created by JackZhao on 2022/4/12.
//

import Foundation
import XCTest
import FlowChart

class TaskTest: XCTestCase {
    var task: TestTask<TaskTest>!
    override func setUp() {
        super.setUp()
        task = TestTask(context: self)
    }

    override func tearDown() {
        super.tearDown()
        task = nil
    }

    // 测试异步任务执行成功
    func test_aync_success() {
        let expectation = self.expectation(description: "test_aync_success")
        task.onEnd { res in
            if case .success(_) = res {
                expectation.fulfill()
            }
        }
        task.isSuccess = true
        task.run(input: "")
        wait(for: [expectation], timeout: 1)
    }

    // 测试异步任务执行失败
    func test_async_failure() {
        let expectation = self.expectation(description: "test_async_failure")
        task.onEnd { res in
            if case .error(_) = res {
                expectation.fulfill()
            }
        }
        task.isSuccess = false
        task.run(input: "")
        wait(for: [expectation], timeout: 1)
    }
}

extension TaskTest: FlowChartContext {
}

class TestTask<C: FlowChartContext>: FlowChartTask<String, String, C> {
    var isSuccess = false
    override var identify: String {
        return "test"
    }

    public override func run(input: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            if self.isSuccess {
                self.accept(.success("success"))
            } else {
                self.accept(.error(.unknownError("fail")))
            }
        }
    }
}

extension String: FlowChartInput {
    public var extraInfo: [String: String] {
        get {
            [:]
        }
        set {
        }
    }
}
