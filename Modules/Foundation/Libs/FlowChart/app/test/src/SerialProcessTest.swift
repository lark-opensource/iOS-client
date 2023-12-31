//
//  SerialProcessTest.swift
//  FlowChartDevEEUnitTest
//
//  Created by JackZhao on 2022/4/12.
//

import Foundation
import XCTest
import FlowChart

class SerialProcessTest: XCTestCase {
    var serialProcess: FlowChartSerialProcess<String, SerialProcessTest>!
    lazy var task1 = TestTask(context: self)
    lazy var task2 = TestTask(context: self)
    lazy var process1 = TestProcess(context: self)
    lazy var process2 = TestProcess(context: self)
    var resCallbackCount = 0

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        serialProcess = nil
        resCallbackCount = 0
        super.tearDown()
    }

    // 测试SerialProcess连接异步任务, 并能响应成功
    func test_task_structure_success() {
        let expectation = self.expectation(description: "test_task_structure_success")
        serialProcess = FlowChartSerialProcess<String, SerialProcessTest>([task1, task2], context: self)
        task1.isSuccess = true
        task2.isSuccess = true
        serialProcess.onEnd { res in
            if case .success(_) = res {
                expectation.fulfill()
            }
        }
        serialProcess.run(input: "") { _ in }
        wait(for: [expectation], timeout: 2)
    }

    // 测试SerialProcess连接异步任务, 并能响应失败
    func test_task_structure_failure() {
        let expectation = self.expectation(description: "test_task_structure_failure")
        serialProcess = FlowChartSerialProcess<String, SerialProcessTest>([task1, task2], context: self)
        task1.isSuccess = false
        task2.isSuccess = false
        serialProcess.onEnd { res in
            if case .error(_) = res {
                expectation.fulfill()
            }
        }
        serialProcess.run(input: "") { _ in }
        wait(for: [expectation], timeout: 2)
    }

    // 测试SerialProcess连接异步流程(process), 并能响应成功
    func test_process_structure_success() {
        let expectation = self.expectation(description: "test_process_structure_success")
        serialProcess = FlowChartSerialProcess<String, SerialProcessTest>([process1, process2], context: self)
        task1.isSuccess = true
        task2.isSuccess = true
        process1.isSuccess = true
        process2.isSuccess = true
        serialProcess.onEnd { res in
            if case .success(_) = res {
                expectation.fulfill()
            }
        }
        serialProcess.run(input: "") { _ in }
        wait(for: [expectation], timeout: 2)
    }

    // 测试SerialProcess连接异步流程(process), 并能响应失败
    func test_process_structure_failure() {
        let expectation = self.expectation(description: "test_process_structure_failure")
        serialProcess = FlowChartSerialProcess<String, SerialProcessTest>([process1, process2], context: self)
        process1.isSuccess = false
        process2.isSuccess = false
        task1.isSuccess = false
        task2.isSuccess = false
        serialProcess.onEnd { res in
            if case .error(_) = res {
                expectation.fulfill()
            }
        }
        serialProcess.run(input: "") { _ in }
        wait(for: [expectation], timeout: 2)
    }

    // 测试SerialProcess连接异步任务, 并能响应每个任务的callback
    func test_task_structure_resCallback() {
        resCallbackCount = 0
        let expectation = self.expectation(description: "test_task_structure_resCallback")
        serialProcess = FlowChartSerialProcess<String, SerialProcessTest>([task1, task2], context: self)
        task1.isSuccess = true
        task2.isSuccess = true
        serialProcess.run(input: "") { [weak self] _ in
            self?.resCallbackCount += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.resCallbackCount == 2 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
    }
}

extension SerialProcessTest: FlowChartContext {
}
