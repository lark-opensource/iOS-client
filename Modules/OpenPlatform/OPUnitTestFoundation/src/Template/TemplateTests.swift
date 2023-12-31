//
//  TemplateTests.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/3.
//  iOS 单测通用模板
/*
import XCTest

@available(iOS 16.0, *)
final class TemplateTests: XCTestCase {
    
    // MARK: - 异步超时接口测试范例
    func test_async() {
        let exp = XCTestExpectation(description: "async")
        
        Task {
            let result = try await sleepTwoSecond()
            XCTAssertTrue(result == ["1", "2", "3"])
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 3)
    }
    
    // MARK: - 每条测试case都会初始化当前XCTestCase实例
    var oneCaseOneValue = true
    func test_instanceProperty1() {
        XCTAssertTrue(oneCaseOneValue)
        pr_changeInstancePropertyValue()
    }
    func test_instanceProperty2() {
        XCTAssertTrue(oneCaseOneValue)
        pr_changeInstancePropertyValue()
    }
}

@available(iOS 16.0, *)
private extension TemplateTests {
    func sleepTwoSecond() async throws -> [String] {
        try await Task.sleep(until: .now + .seconds(2), clock: .continuous)
        return ["1", "2", "3"]
    }
    
    func pr_changeInstancePropertyValue() {
        if oneCaseOneValue {
            oneCaseOneValue = false
        }
    }
}

*/