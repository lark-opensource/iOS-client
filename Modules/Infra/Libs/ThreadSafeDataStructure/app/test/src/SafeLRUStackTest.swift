//
//  SafeLRUStackTest.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by Saafo on 2021/5/26.
//

import Foundation
import XCTest
@testable import ThreadSafeDataStructure

class SafeLRUStackTest: XCTestCase {
    let data = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        3, 2, 5, 3, 1, 5, 6, 7, 3, 1
    ]

    func testUse() {
        let stack = SafeLRUStack<Int>(maxSize: 30)
        let random = data.shuffled()
        random.forEach { stack.use($0) }
        XCTAssertEqual(stack.top(), random.last)
    }

    func testPop() {
        let stack = SafeLRUStack<Int>(maxSize: 30)
        XCTAssertNil(stack.pop())
        data.forEach { stack.use($0) }
        XCTAssertEqual(stack.pop(), 1)
        XCTAssertEqual(stack.pop(), 3)
        XCTAssertEqual(stack.pop(), 7)
        XCTAssertEqual(stack.pop(), 6)
        XCTAssertEqual(stack.pop(), 5)
        XCTAssertEqual(stack.pop(), 2)
        XCTAssertEqual(stack.pop(), 30)
        stack.pop(to: 23)
        XCTAssertEqual(stack.cache.count, 23 - 6)
        stack.pop(to: 4)
        stack.remove(4)
        XCTAssertTrue(stack.isEmpty)
    }

    func testRemove() {
        let stack = SafeLRUStack<Int>(maxSize: 10)
        data.forEach { stack.use($0) }
        XCTAssertEqual(stack.tail?.value, 27)
        XCTAssertEqual(stack.cache.count, 10)
    }
}
