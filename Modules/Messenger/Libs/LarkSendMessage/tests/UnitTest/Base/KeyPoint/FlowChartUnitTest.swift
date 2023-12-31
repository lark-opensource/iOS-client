//
//  FlowChartUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import FlowChart // FlowChartSerialProcess

/// FlowChart新增单测
final class FlowChartUnitTest: CanSkipTestCase {
    /// 测试串行执行
    func testSerialProcess() {
        let expectation = LKTestExpectation(description: "@test serial process")
        // 3Task + 1自身onEnd
        expectation.expectedFulfillmentCount = 4
        let context = MyContext(); let input = MyInput()
        let serialProcess = FlowChartSerialProcess([MyTask1(context: context), MyTask2(context: context), MyTask3(context: context)], context: context)
        serialProcess.run(input: input) { response in
            switch response {
            case .failure(let id, let error):
                XCTExpectFailure("serial process error \(error) id \(id)")
            default: break
            }
            expectation.fulfill()
        }
        serialProcess.onEnd { _ in
            XCTAssertEqual(input.extraInfo["MyInput"] ?? "", "MyTask3")
            // FlowChartSerialProcess默认会加一个contextId的key
            XCTAssertFalse((input.extraInfo["contextId"] ?? "").isEmpty)
            expectation.fulfill()
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试条件执行
    func testConditionProcess() {
        let expectation = LKTestExpectation(description: "@test condition process")
        // 1Task + 1自身onEnd
        expectation.expectedFulfillmentCount = 2
        let input = MyInput()
        let process = FlowChartConditionProcess<MyInput, MyInput, MyContext>(context: MyContext()) { input in return (MyTask1(context: MyContext()), input) }
        process.run(input: input) { response in
            switch response {
            case .failure(let id, let error):
                XCTExpectFailure("condition process error \(error) id \(id)")
            default: break
            }
            expectation.fulfill()
        }
        process.onEnd { _ in
            XCTAssertEqual(input.extraInfo["MyInput"] ?? "", "MyTask1")
            // FlowChartConditionProcess不会默认会加一个contextId的key
            XCTAssertTrue((input.extraInfo["contextId"] ?? "").isEmpty)
            expectation.fulfill()
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}

final class MyContext: FlowChartContext {}
final class MyInput: FlowChartInput { var extraInfo: [String: String] = [:] }
final class MyTask1: FlowChartTask<MyInput, MyInput, MyContext> {
    override func run(input: MyInput) {
        input.extraInfo["MyInput"] = "MyTask1"
        DispatchQueue.global().async { self.accept(.success(input)) }
    }
}
final class MyTask2: FlowChartTask<MyInput, MyInput, MyContext> {
    override func run(input: MyInput) {
        XCTAssertEqual(input.extraInfo["MyInput"] ?? "", "MyTask1"); input.extraInfo["MyInput"] = "MyTask2"
        DispatchQueue.global().async { self.accept(.success(input)) }
    }
}
final class MyTask3: FlowChartTask<MyInput, MyInput, MyContext> {
    override func run(input: MyInput) {
        XCTAssertEqual(input.extraInfo["MyInput"] ?? "", "MyTask2"); input.extraInfo["MyInput"] = "MyTask3"
        DispatchQueue.global().async { self.accept(.success(input)) }
    }
}
