//
//  EntityParametersConfigEnumCodableTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/22.
//

import XCTest
import LarkModel
// swiftlint:disable all
final class EntityParametersConfigEnumCodableTest: XCTestCase {
    func testTimeRange() {
        let range = TimeRangeCondition.range(1, 2)
        let data = try! JSONEncoder().encode(range)
        let result = try! JSONDecoder().decode(TimeRangeCondition.self, from: data)
        if case .range(let start, let end) = result {
            XCTAssertEqual(start, 1)
            XCTAssertEqual(end, 2)
        } else {
            XCTFail()
        }
    }

    func testBelongUser() {
        let belong = BelongUserCondition.belong(["123"])
        let data = try! JSONEncoder().encode(belong)
        let result = try! JSONDecoder().decode(BelongUserCondition.self, from: data)
        if case .belong(let ids) = result {
            XCTAssertEqual(ids, ["123"])
        } else {
            XCTFail()
        }
    }

    func testBelongChat() {
        let belong = BelongChatCondition.belong(["123"])
        let data = try! JSONEncoder().encode(belong)
        let result = try! JSONDecoder().decode(BelongChatCondition.self, from: data)
        if case .belong(let ids) = result {
            XCTAssertEqual(ids, ["123"])
        } else {
            XCTFail()
        }
    }
}
// swiftlint:enable all
