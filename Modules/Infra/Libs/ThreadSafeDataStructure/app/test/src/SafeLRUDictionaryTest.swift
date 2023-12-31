//
//  SafeLRUDictionaryTest.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by Saafo on 2021/5/27.
//

import Foundation
import XCTest
@testable import ThreadSafeDataStructure

class SafeLRUDictionaryTest: XCTestCase {
    let key = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        3, 2, 5, 3, 1, 5, 6, 7, 3, 1
    ]
//    lazy var value: [Int] = {
//        key.map { $0 * 3 }
//    }()
    func value(for key: Int) -> Int {
        return key * 3
    }

    func testSetAndGetValue() {
        let dict = SafeLRUDictionary<Int, Int>(capacity: 20)
        key.forEach { dict.setValue(value(for: $0), for: $0) }
        XCTAssertEqual(dict.keys.count, 20)
        XCTAssertEqual(dict.values.count, 20)
        XCTAssertEqual(dict.getValue(for: 23), value(for: 23))
        XCTAssertNil(dict.getValue(for: 12))
        // set nil test
        XCTAssertEqual(dict[7], value(for: 7))
        XCTAssert(dict.count == 20)
        dict[7] = nil
        XCTAssert(dict.count == 19)
        XCTAssertNil(dict[7])
        // capacity test
        dict.capacity = 30
        XCTAssert(dict.capacity == 30)
        dict.capacity = 15
        XCTAssert(dict.capacity == 15)
        XCTAssert(dict.count == 15)
        dict.capacity = -1
        XCTAssert(dict.capacity == 0)
        XCTAssert(dict.isEmpty)
        dict.setValue(1, for: 1)
        XCTAssertNil(dict.getValue(for: 1))
        // remove test
        dict.capacity = 10
        key.forEach { dict[$0] = value(for: $0) }
        XCTAssertEqual(dict.removeValue(forKey: 1), value(for: 1))
        XCTAssertEqual(dict.count, 9)
        XCTAssertNil(dict.removeValue(forKey: 99))
        dict.removeAll()
        XCTAssert(dict.isEmpty)
        dict.removeAll(keepingCapacity: false)
        XCTAssertEqual(dict.capacity, 100)

    }

    func testSafeDoublyLinkedList() {
        let list = SafeDoublyLinkedList<Int>()
        let node1 = list.addHead(1)
        let node2 = list.addHead(2)
        let node3 = list.addHead(3)
        XCTAssert(list.count == 3)
        print(list.list)
        XCTAssert(list.removeLast() === node1)
        list.moveToHead(node2)
        list.moveToHead(node2)
        XCTAssert(list.removeLast() === node3)
        list.removeNode(node3)
        XCTAssert(!list.isEmpty)
        list.removeNode(node2)
        XCTAssert(list.isEmpty)
        XCTAssertNil(list.removeLast())

    }

    func testCircularReference() {
        let dic: SafeLRUDictionary<Int, Int>? = SafeLRUDictionary<Int, Int>(capacity: 10)
        dic?.setValue(1, for: 2)
        dic?.setValue(3, for: 4)
        weak var node1 = dic?.nodesDict[2]
        weak var node2 = dic?.nodesDict[4]
        XCTAssertNotNil(node1)
        XCTAssertNotNil(node2)
        dic?.removeAll()
        XCTAssertNil(node1)
        XCTAssertNil(node2)
    }
}
