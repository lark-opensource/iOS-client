//
//  ProcessTest.swift
//  FlowChartDevEEUnitTest
//
//  Created by JackZhao on 2022/4/12.
//

import Foundation
import XCTest
import FlowChart

class ProcessTest: XCTestCase {
    var process: TestProcess<ProcessTest>!
    override func setUp() {
        super.setUp()
        process = TestProcess(context: self)
    }

    override func tearDown() {
        super.tearDown()
        process = nil
    }

    // 测试process连接异步任务, 并能响应成功
    func test_aync_success() {
        let expectation = self.expectation(description: "test_aync_success")
        process.onEnd { res in
            if case .success(_) = res {
                expectation.fulfill()
            }
        }
        process.isSuccess = true
        process.run(input: "")
        wait(for: [expectation], timeout: 1)
    }

    // 测试process连接异步任务, 并能响应失败
    func test_async_failure() {
        let expectation = self.expectation(description: "test_async_failure")
        process.onEnd { res in
            if case .error(_) = res {
                expectation.fulfill()
            }
        }
        process.isSuccess = false
        process.run(input: "")
        wait(for: [expectation], timeout: 1)
    }
}

extension ProcessTest: FlowChartContext {
}

class TestProcess<C: FlowChartContext>: FlowChartProcess<String, String, C> {
    lazy var task1 = TestTask(context: self)
    lazy var task2 = TestTask(context: self)
    var isSuccess = false {
        willSet {
            task1.isSuccess = newValue
            task2.isSuccess = newValue
        }
    }
    override var identify: String {
        return "TestTask"
    }

    public override func run(input: String, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        task1.next(task2) { [weak self] res in
            if case .success(_) = res {
                return ""
            }
            self?.accept(.error(.unknownError("fail")))
            return nil
        }

        task2.onEnd { [weak self] res in
            guard let self = self else { return }
            if case .success(_) = res {
                if self.isSuccess {
                    self.accept(.success("success"))
                } else {
                    self.accept(.error(.unknownError("fail")))
                }
            }
        }

        task1.run(input: "")
    }
}

extension TestProcess: FlowChartContext {

}
