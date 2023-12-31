//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
import EEAtomic

class AA {
    static var counter = 0
    static var counter2 = 0
    static func action() -> String {
        AA.counter2 += 1
        return "asdfsd"
    }
    @SafeLazy(expr: AA.action())
    var c
    // 后面表达式没有lazy执行，而是初始化立即执行了.. @SafeLazy的@autoclosure没生效..
    @SafeLazy var d: String = AA.action()

    var a = SafeLazy<String> {
        AA.counter += 1
        return "asdfsd"
    }
    lazy var b: String = {
        return "system lazy"
    }()
}

class OnceTestCase: XCTestCase {
    func testExample() {
        let a = AA()
        let counter = AA.counter
        let c2 = AA.counter2
        XCTAssertEqual(counter, 0)
        XCTAssertEqual(c2, 0)
        DispatchQueue.concurrentPerform(iterations: 8) { _ in
            for i in 0..<8 {
                _ = a.a.wrappedValue
                _ = a.c
                _ = a.d
            }
        }
        XCTAssertEqual(counter + 1, AA.counter)
        XCTAssertEqual(c2 + 2, AA.counter2)
        print(a.a.value, a.c, a.d)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
