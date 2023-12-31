//
//  TileSortPageTests.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/5/5.
//

import XCTest
@testable import ByteView

final class TileSortRowTests: XCTestCase {

    var sut: TileSortPage!

    override func setUpWithError() throws {
        sut = TileSortPage()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Tests

    /// 给定待插入元素和位置，如果该位置为空，并且该行容量足够，则插入成功，否则插入失败。插入完成会维护本页最小和次小分数
    func testInsertAt() {
        // 输入检查
        var result = sut.insert(myself, at: _c(3, 0))
        XCTAssertFalse(result)
        XCTAssertEqual(sut.count, 0)
        result = sut.insert(myself, at: _c(0, 2))
        XCTAssertFalse(result)
        XCTAssertEqual(sut.count, 0)

        // person 类型参会人可以插入到指定空位上
        result = sut.insert(myself, at: _c(0, 0))
        XCTAssertTrue(result)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.lastSortRank, .max)

        // room 类型参会人在本行剩余空间足够的情况下，可以被插入到指定空位上
        let room = roomItem(id: "test_room_1", rank: 1)
        for invalidCoordinate in [_c(0, 1), _c(0, 0), _c(1, 1)] {
            result = sut.insert(room, at: invalidCoordinate)
            XCTAssertFalse(result)
            XCTAssertEqual(sut.count, 1)
        }
        result = sut.insert(room, at: GridCoordinate(row: 1, column: 0, pageIndex: 0))
        XCTAssertTrue(result)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.lastSortRank, room.rank)

        // 指定位置被占用时无法插入
        let person = personItem(id: "test_person_1", rank: 3)
        result = sut.insert(person, at: _c(0, 0))
        XCTAssertFalse(result)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.lastSortRank, room.rank)
    }

    /// 给定带插入元素和插入位置，将插入位置原来的元素移除，如果有必要则同时移除其相邻元素，然后把给定元素插入，保证插入成功，返回被移除元素
    func testReplaceAt() {
        // mock data
        let person1 = personItem(id: "test_person_1", rank: 1)
        let room1 = personItem(id: "test_room_1", rank: 2)

        // P O
        // O P
        // R R
        sut.insert(myself, at: _c(0, 0))
        sut.insert(person1, at: _c(1, 1))
        sut.insert(room1, at: _c(2, 0))

        let person2 = personItem(id: "test_person_2", rank: 3)
        let room2 = roomItem(id: "test_room_2", rank: 4)

        // 输入检查
        var result = sut.replace(person2, at: (3, 0))
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 2)
        result = sut.replace(room2, at: (2, 1))
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 2)

        // 插入到空位置，直接插入，无替换
        // P O
        // P P
        // R R
        result = sut.replace(person2, at: (1, 0))
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.lastSortRank, 3)

        // room 替换到有两个人的一行，则将两个人都替换下来
        // P O
        // R R
        // R R
        result = sut.replace(room2, at: (1, 0))
        XCTAssertEqual(result, [person2, person1])
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 4)

        // person 替换到 room 行，将 room 移除，另一个位置为空
        // P O
        // O P
        // R R
        result = sut.replace(person1, at: (1, 1))
        XCTAssertEqual(result, [room2])
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 2)

        // room 替换 room、person 替换 person，正常替换
        result = sut.replace(room2, at: (2, 0))
        XCTAssertEqual(result, [room1])
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 4)
        result = sut.replace(person2, at: (1, 1))
        XCTAssertEqual(result, [person1])
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 4)
    }

    /// pop() 从前往后移除首个元素；remove(with:) 移除指定 pid 元素
    func testPopAndRemove() {
        // mock data
        let p1 = personItem(id: "p1", rank: 2)
        let r1 = roomItem(id: "r1", rank: 1)

        sut.insert(myself, at: _c(0, 0))
        sut.insert(p1, at: _c(1, 0))
        sut.insert(r1, at: _c(2, 0))

        let first = sut.pop()
        XCTAssertEqual(first, myself)
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.lastSortRank, 2)

        let second = sut.pop()
        XCTAssertEqual(second, p1)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.lastSortRank, 1)

        let third = sut.pop()
        XCTAssertEqual(third, r1)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.lastSortRank, .max)

        let forth = sut.pop()
        XCTAssertNil(forth)

        sut.insert(p1, at: _c(1, 1))
        let removed = sut.remove(with: p1.pid)
        XCTAssertEqual(removed, p1)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.lastSortRank, .max)

        let another = sut.remove(with: r1.pid)
        XCTAssertNil(another)
    }

    func testInsert() {
        let p1 = personItem(id: "p1", rank: 1)
        let r1 = roomItem(id: "r1", rank: 2)
        let p2 = personItem(id: "p2", rank: 3)
        let r2 = roomItem(id: "r2", rank: 4)
        let p3 = personItem(id: "p3", rank: 5)
        let r3 = roomItem(id: "r3", rank: 6)

        // P O
        // O O
        // O O
        XCTAssertTrue(sut.insert(myself))
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.lastSortRank, .max)

        // P O
        // R R
        // O O
        XCTAssertTrue(sut.insert(r1))
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.lastSortRank, 2)

        // P P
        // R R
        // O O
        XCTAssertTrue(sut.insert(p1))
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut.lastSortRank, 2)

        // P P
        // R R
        // P O
        XCTAssertTrue(sut.insert(p2))
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.lastSortRank, 3)

        // P O
        // R R
        // P O
        _ = sut.remove(with: p1.pid)
        // P P
        // R R
        // R R
        XCTAssertTrue(sut.insert(r2))
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.lastSortRank, 4)
        XCTAssertFalse(sut.insert(p3))

        // O P
        // R R
        // R R
        _ = sut.pop()
        XCTAssertFalse(sut.insert(r3))
    }

    func testInsertOrReplace() {
        let p1 = personItem(id: "p1", rank: 1)
        let r1 = roomItem(id: "r1", rank: 2)
        let p2 = personItem(id: "p2", rank: 3)
        let r2 = roomItem(id: "r2", rank: 4)
        let p3 = personItem(id: "p3", rank: 5)
        let p4 = personItem(id: "p4", rank: 7)
        let r4 = roomItem(id: "r4", rank: 8)
        let p5 = personItem(id: "p5", rank: 9)
        let r5 = roomItem(id: "r5", rank: 10)
        let p6 = personItem(id: "p6", rank: 11)

        // 初始化：六个参会人，权重矩阵：
        // 1 11
        // 7 3
        // 0 5
        XCTAssertEqual(sut.insertOrReplace(p1), [])
        XCTAssertEqual(sut.insertOrReplace(p6), [])
        XCTAssertEqual(sut.insertOrReplace(p4), [])
        XCTAssertEqual(sut.insertOrReplace(p2), [])
        XCTAssertEqual(sut.insertOrReplace(myself), [])
        XCTAssertEqual(sut.insertOrReplace(p3), [])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 11)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [1, 11, 7, 3, 0, 5])

        // 新插入一个参会人时，替换当前页最小权重元素，并更新最小权重值
        // 1 9
        // 7 3
        // 0 5
        var removed = sut.insertOrReplace(p5)
        XCTAssertEqual(removed, [p6])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 9)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [1, 9, 7, 3, 0, 5])

        // ======== 测试通过纯替换元素来实现插入 room ========

        // 插入一个 room，此时将取出当前页最小和次小的元素，调整位置，并将 room 插入
        // 1 3
        // 8 8
        // 0 5
        removed = sut.insertOrReplace(r4)
        XCTAssertEqual(removed.map { $0.rank }.sorted(), [7, 9])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 8)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [1, 3, 8, 0, 5])

        // 插入一个 room，且当前最小权重是 room，则直接替换
        // 1 3
        // 4 4
        // 0 5
        XCTAssertEqual(sut.insertOrReplace(r2), [r4])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 5)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [1, 3, 4, 0, 5])

        // 插入一个 room，当前最小权重是 person，但次小权重是 room，直接替换次小权重
        // 1 3
        // 2 2
        // 0 5
        XCTAssertEqual(sut.insertOrReplace(r1), [r2])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 5)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [1, 3, 2, 0, 5])

        // ======== 测试通过调整位置来实现插入 room ========
        // X 3
        // 2 2
        // 0 5
        _ = sut.remove(with: p1.pid)

        // 只有一行不满，此时先把最小权重元素（person）放到不满的一行，然后整体替换待插入 room
        // 4 4
        // 2 2
        // 0 3
        XCTAssertEqual(sut.insertOrReplace(r2), [p3])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 4)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [4, 2, 0, 3])

        // 只有一行不满，且最小权重已经单独成一行
        // 11 X
        // 2 2
        // 0 3
        _ = sut.replace(p6, at: (0, 0))

        // 4 4
        // 2 2
        // 0 3
        XCTAssertEqual(sut.insertOrReplace(r2), [p6])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 4)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [4, 2, 0, 3])

        // 只有一行不满，最小权重是 room，把次小元素放到不满的一行，直接替换该行
        // 4 4
        // 1 X
        // 0 3
        _ = sut.replace(p1, at: (1, 0))

        // 4 4
        // 2 2
        // 0 1
        XCTAssertEqual(sut.insertOrReplace(r1), [p2])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 4)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [4, 2, 0, 1])

        // 两行不满，不用移除任何元素，直接把不满的两行放在一起，然后插入 room
        // 4 4
        // 3 X
        // X 1
        _ = sut.replace(p2, at: (1, 0))
        _ = sut.remove(with: myself.pid)

        // 4 4
        // 3 1
        // 10 10
        XCTAssertEqual(sut.insertOrReplace(r5), [])
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 10)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [4, 3, 1, 10])

        // 三行均不满，把第三行移动到第一行，然后底部插入 room
        // 11 X
        // X 1
        // 9 X
        _ = sut.replace(p6, at: (0, 0))
        _ = sut.replace(p5, at: (2, 0))
        _ = sut.remove(with: p2.pid)

        // 11 9
        // X 1
        // 2 2
        XCTAssertEqual(sut.insertOrReplace(r1), [])
        XCTAssertFalse(sut.isFull)
        XCTAssertEqual(sut.lastSortRank, 11)
        XCTAssertEqual(sut.enumerated.map { $0.rank }, [11, 9, 1, 2])
    }

    func testNormalize() {
        let p1 = personItem(id: "p1", rank: 1)
        let r1 = roomItem(id: "r1", rank: 2)
        let p2 = personItem(id: "p2", rank: 3)
        let r2 = roomItem(id: "r2", rank: 4)
        let p3 = personItem(id: "p3", rank: 5)

        // case 1: 空位往下移
        // 1 X
        // X 3
        // 2 2
        sut.insert(p1, at: _c(0, 0))
        sut.insert(p2, at: _c(1, 1))
        sut.insert(r1, at: _c(2, 0))

        // 1 3
        // 2 2
        // X X
        var result = sut.normalized()
        XCTAssertFalse(result.isFull)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.enumerated.map { $0.rank }, [1, 3, 2])

        // case 2: Room 放到 Person 后面
        // 1 X
        // 4 4
        // X 3
        _ = sut.replace(r2, at: (1, 0))
        _ = sut.replace(p2, at: (2, 1))

        // 1 3
        // 4 4
        // X X
        result = sut.normalized()
        XCTAssertFalse(result.isFull)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.enumerated.map { $0.rank }, [1, 3, 4])

        // case 3: 多个 room 的情况
        // 2 2
        // 5 X
        // 4 4
        _ = sut.replace(r1, at: (0, 0))
        _ = sut.replace(p3, at: (1, 0))
        _ = sut.replace(r2, at: (2, 0))

        // 5 X
        // 2 2
        // 4 4
        result = sut.normalized()
        XCTAssertFalse(result.isFull)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.enumerated.map { $0.rank }, [5, 2, 4])
    }

    // MARK: - Utils

    let myself = TileSortItem(participant: ParticipantMockData.myself, myself: ParticipantMockData.myself.user, asID: nil, focusedID: nil, rank: 0, action: .none)

    func personItem(id: String, rank: Int, action: CandidateAction = .none) -> TileSortItem {
        TileSortItem(participant: person(id), role: [], rank: rank, action: action)
    }

    func roomItem(id: String, rank: Int, action: CandidateAction = .none) -> TileSortItem {
        TileSortItem(participant: room(id), role: [], rank: rank, action: action)
    }

    func _c(_ row: Int, _ col: Int) -> GridCoordinate {
        GridCoordinate(row: row, column: col, pageIndex: 0)
    }
}
