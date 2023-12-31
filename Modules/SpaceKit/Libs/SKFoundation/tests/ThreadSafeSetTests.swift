//
//  ThreadSafeSetTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by CJ on 2022/4/6.
//

import XCTest
@testable import SKFoundation

class ThreadSafeSetTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPopFirst() {
        let set = ThreadSafeSet<String>()
        set.insert("0")
        set.insert("1")
        set.insert("2")
        let res = set.popFirst()
        XCTAssertNotNil(res)
        XCTAssertFalse(set.contains((res ?? "")))
    }

    func testFirst() {
        let set = ThreadSafeSet<String>()
        set.insert("0")
        set.insert("1")
        set.insert("2")
        let res = set.first()
        XCTAssertTrue(set.contains((res ?? "")))
    }

    func testIsEmpty() {
        let set = ThreadSafeSet<String>()
        var res = set.isEmpty()
        XCTAssertTrue(res)

        set.insert("0")
        set.insert("1")
        set.insert("2")
        res = set.isEmpty()
        XCTAssertFalse(res)
    }

    func testCount() {
        let set = ThreadSafeSet<String>()
        var res = set.count()
        XCTAssertEqual(res, 0)

        set.insert("0")
        set.insert("1")
        set.insert("2")
        res = set.count()
        XCTAssertEqual(res, 3)
    }

    func testInsert() {
        let set = ThreadSafeSet<String>()
        var res = set.count()
        XCTAssertEqual(res, 0)

        set.insert("0")
        set.insert("1")
        set.insert("2")
        res = set.count()
        XCTAssertEqual(res, 3)
    }

    func testRemoveAll() {
        let set = ThreadSafeSet<String>()
        var res = set.count()
        XCTAssertEqual(res, 0)

        set.insert("0")
        set.insert("1")
        set.insert("2")
        res = set.count()
        XCTAssertEqual(res, 3)

        set.removeAll()
        res = set.count()
        XCTAssertEqual(res, 0)
    }

    func testContains() {
        let set = ThreadSafeSet<String>()
        set.insert("0")
        set.insert("1")
        set.insert("2")

        var res = set.contains("2")
        XCTAssertTrue(res)

        res = set.contains("10")
        XCTAssertFalse(res)
    }

    func testSubtracting() {
        let set1 = ThreadSafeSet<String>()
        set1.insert("0")
        set1.insert("1")
        set1.insert("2")

        let set2 = ThreadSafeSet<String>()
        set2.insert("0")
        set2.insert("4")
        set2.insert("5")

        let res = set1.subtracting(set2)
        XCTAssertTrue(res.count() == 2)
        XCTAssertTrue(res.contains("1"))
        XCTAssertTrue(res.contains("2"))
        XCTAssertFalse(res.contains("0"))
    }
}
