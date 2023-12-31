//
//  ConditionProcessTest.swift
//  FlowChartDevEEUnitTest
//
//  Created by JackZhao on 2022/4/12.
//

import Foundation
import XCTest
import FlowChart

class ConditionProcessTest: XCTestCase {
    var conditionProcess: FlowChartConditionProcess<String, String, ConditionProcessTest>!
    lazy var task1 = TestTask(context: self)
    lazy var process1 = TestProcess(context: self)
    lazy var successProcess = TestSuccessProcess(context: self)
    lazy var successTask = TestSuccessTask(context: self)

    var resCallbackCount = 0

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        conditionProcess = nil
        super.tearDown()
    }

    // 测试ConditionProcess返回异步任务, 并能响应成功
    func test_task_structure_success() {
        let expectation = self.expectation(description: "test_task_structure_success")
        task1.isSuccess = true
        conditionProcess = FlowChartConditionProcess<String, String, ConditionProcessTest>(context: self) { [weak self] res in
            guard let self = self else { return nil }
            return (self.task1, res)
        }
        conditionProcess.onEnd { res in
            if case .success(let value) = res, value == "success" {
                expectation.fulfill()
            }
        }
        conditionProcess.run(input: "", { _ in })
        wait(for: [expectation], timeout: 2)
    }

    // 测试ConditionProcess返回异步流程(process), 并能响应成功
    func test_process_structure_success() {
        let expectation = self.expectation(description: "test_task_structure_success")
        process1.isSuccess = true
        conditionProcess = FlowChartConditionProcess<String, String, ConditionProcessTest>(context: self) { [weak self] res in
            guard let self = self else { return nil }
            return (self.process1, res)
        }
        conditionProcess.onEnd { res in
            if case .success(let value) = res, value == "success" {
                expectation.fulfill()
            }
        }
        conditionProcess.run(input: "") { _ in }
        wait(for: [expectation], timeout: 2)
    }

    // 测试ConditionProcess返回异步任务, 并能响应失败
    func test_task_structure_failure() {
        let expectation = self.expectation(description: "test_task_structure_failure")
        task1.isSuccess = false
        conditionProcess = FlowChartConditionProcess<String, String, ConditionProcessTest>(context: self) { [weak self] res in
            guard let self = self else { return nil }
            return (self.task1, res)
        }
        conditionProcess.onEnd { res in
            if case .error(let error) = res, error.getDescription() == "fail" {
                expectation.fulfill()
            }
        }
        conditionProcess.run(input: "", { _ in })
        wait(for: [expectation], timeout: 2)
    }

    // 测试ConditionProcess返回异步流程(process), 并能响应失败
    func test_process_structure_failure() {
        let expectation = self.expectation(description: "test_process_structure_failure")
        task1.isSuccess = false
        conditionProcess = FlowChartConditionProcess<String, String, ConditionProcessTest>(context: self) { [weak self] res in
            guard let self = self else { return nil }
            return (self.task1, res)
        }
        conditionProcess.onEnd { res in
            if case .error(let error) = res, error.getDescription() == "fail" {
                expectation.fulfill()
            }
        }
        conditionProcess.run(input: "", { _ in })
        wait(for: [expectation], timeout: 2)
    }

    // 测试ConditionProcess返回异步流程, 改变输入能成功
    func test_process_change_input() {
        let expectation = self.expectation(description: "test_process_change_input")
        conditionProcess = FlowChartConditionProcess<String, String, ConditionProcessTest>(context: self) { [weak self] res in
            guard let self = self else { return nil }
            var res = res
            res = "123"
            return (self.successProcess, res)
        }
        conditionProcess.onEnd { res in
            if case .success(let value) = res, value == "123" {
                expectation.fulfill()
            }
        }
        conditionProcess.run(input: "", { _ in })
        wait(for: [expectation], timeout: 2)
    }

    // 测试ConditionProcess返回异步task, 改变输入能成功
    func test_task_change_input() {
        let expectation = self.expectation(description: "test_task_change_input")
        conditionProcess = FlowChartConditionProcess<String, String, ConditionProcessTest>(context: self) { [weak self] res in
            guard let self = self else { return nil }
            var res = res
            res = "123"
            return (self.successTask, res)
        }
        conditionProcess.onEnd { res in
            if case .success(let value) = res, value == "123" {
                expectation.fulfill()
            }
        }
        conditionProcess.run(input: "", { _ in })
        wait(for: [expectation], timeout: 2)
    }
}

extension ConditionProcessTest: FlowChartContext {

}

class TestSuccessProcess<C: FlowChartContext>: FlowChartProcess<String, String, C> {
    override var identify: String { "TestSuccessProcess" }
    public override func run(input: String, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        self.accept(.success(input))
    }
}

class TestSuccessTask<C: FlowChartContext>: FlowChartTask<String, String, C> {
    override var identify: String { "TestSuccessTask" }
    public override func run(input: String) {
        self.accept(.success(input))
    }
}
