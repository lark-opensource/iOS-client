//
//  RectSortPageTests.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/5/8.
//

import XCTest
@testable import ByteView

final class RectSortPageTests: XCTestCase {

    var sut: RectSortPage!

    override func setUpWithError() throws {
        sut = RectSortPage(initialCapacity: 6, firstPageSize: 4)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testInsertIfNull() {
        let item1 = newItem(id: "1", rank: 1)
        let item2 = newItem(id: "2", rank: 2)
        let item3 = newItem(id: "3", rank: 3)

        XCTAssertFalse(sut.insertIfNull(item2, at: -1))
        XCTAssertFalse(sut.insertIfNull(item2, at: 100))
        XCTAssertTrue(sut.insertIfNull(item2, at: 5))
        XCTAssertEqual(sut.lastSortRankInFirstPage, .max)
        XCTAssertTrue(sut.insertIfNull(item3, at: 2))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 3)
        XCTAssertFalse(sut.insertIfNull(item1, at: 2))
        XCTAssertFalse(sut.insertIfNull(item1, at: 5))
        XCTAssertTrue(sut.insertIfNull(item1, at: 0))

        var expected = [(0, "1"), (2, "3"), (5, "2")]
        sut.enumerated(in: 0..<6).forEach { (index, item) in
            let top = expected.removeFirst()
            XCTAssertEqual(index, top.0)
            XCTAssertEqual(item.pid.id, top.1)
        }
    }

    func testInsertOnNull() {
        let item1 = newItem(id: "1", rank: 1)
        let item2 = newItem(id: "2", rank: 2)
        let item3 = newItem(id: "3", rank: 3)

        sut.insertOnNull([])
        XCTAssertEqual(sut.normalized, [])

        XCTAssertTrue(sut.insertIfNull(item2, at: 5))
        XCTAssertTrue(sut.insertIfNull(item3, at: 2))
        XCTAssertTrue(sut.insertIfNull(item1, at: 0))

        let items = (11..<19).map { newItem(id: String($0), rank: $0) }
        sut.insertOnNull(items)
        var expected = items
        expected.insert(item1, at: 0)
        expected.insert(item3, at: 2)
        expected.insert(item2, at: 5)
        XCTAssertEqual(sut.normalized, expected)
        XCTAssertEqual(sut.lastSortRankInFirstPage, 12)
    }

    func testReplaceAt() {
        let item1 = newItem(id: "1", rank: 1)
        let item2 = newItem(id: "2", rank: 2)
        let item3 = newItem(id: "3", rank: 3)

        XCTAssertNil(sut.replace(item1, at: 10))
        XCTAssertEqual(sut.lastSortRankInFirstPage, .max)
        XCTAssertNil(sut.replace(item1, at: 2))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 1)
        XCTAssertNil(sut.replace(item2, at: 5))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 1)
        XCTAssertEqual(sut.replace(item3, at: 2), item1)
        XCTAssertEqual(sut.lastSortRankInFirstPage, 3)
    }

    func testInsertOrReplace() {
        let item1 = newItem(id: "1", rank: 1)
        let item2 = newItem(id: "2", rank: 2)
        let item3 = newItem(id: "3", rank: 3)
        let item4 = newItem(id: "4", rank: 4)
        let item5 = newItem(id: "5", rank: 5)
        let item6 = newItem(id: "6", rank: 6)
        let item7 = newItem(id: "7", rank: 7)
        let item8 = newItem(id: "8", rank: 8)
        let item9 = newItem(id: "9", rank: 9)

        var range = 3..<6
        XCTAssertNil(sut.insertOrReplace(item1, in: range))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 1)
        XCTAssertNil(sut.insertOrReplace(item2, in: range))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 1)
        XCTAssertNil(sut.insertOrReplace(item3, in: range))
        XCTAssertEqual(sut.insertOrReplace(item4, in: range), item3)
        range = 3..<7
        XCTAssertNil(sut.insertOrReplace(item5, in: range))
        XCTAssertEqual(sut.normalized, [item1, item2, item4, item5])
        range = 0..<4
        XCTAssertNil(sut.insertOrReplace(item6, in: range))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 6)
        XCTAssertNil(sut.insertOrReplace(item7, in: range))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 7)
        XCTAssertNil(sut.insertOrReplace(item8, in: range))
        XCTAssertEqual(sut.lastSortRankInFirstPage, 8)
        XCTAssertEqual(sut.insertOrReplace(item9, in: range), item8)
        XCTAssertEqual(sut.lastSortRankInFirstPage, 9)
    }

    func testMiscellaneous() {
        let item1 = newItem(id: "1", rank: 1)
        let item2 = newItem(id: "2", rank: 2)
        let item3 = newItem(id: "3", rank: 3)
        let item4 = newItem(id: "4", rank: 4)
        let item5 = newItem(id: "5", rank: 5)

        sut.insertOnNull([item1, item2, item3])
        _ = sut.insertIfNull(item4, at: 4)
        _ = sut.insertIfNull(item5, at: 5)

        // swapAt(_:, _:)
        sut.swapAt(0, j: 1)
        XCTAssertEqual(sut.normalized, [item2, item1, item3, item4, item5])
        XCTAssertEqual(sut.lastSortRankInFirstPage, 3)
        sut.swapAt(2, j: 5)
        XCTAssertEqual(sut.normalized, [item2, item1, item5, item4, item3])
        XCTAssertEqual(sut.lastSortRankInFirstPage, 5)

        // remove(at:)
        XCTAssertNil(sut.remove(at: 3))
        XCTAssertEqual(sut.remove(at: 2), item5)
        XCTAssertEqual(sut.lastSortRankInFirstPage, 2)
        XCTAssertEqual(sut.remove(at: 5), item3)

        // index
        XCTAssertNil(sut.index(of: item3.pid))
        XCTAssertNil(sut.index(where: { $0.pid == item2.pid }, in: 1..<10))
        XCTAssertEqual(sut.index(where: { $0.rank > 1 }), 0)
        XCTAssertEqual(sut.index(of: item4.pid), 4)
    }

    // MARK: - Utils

    func newItem(id: String, rank: Int, action: CandidateAction = .none) -> GridSortInputEntry {
        GridSortInputEntry(participant: person(id), role: [], rank: rank, action: action)
    }
}
