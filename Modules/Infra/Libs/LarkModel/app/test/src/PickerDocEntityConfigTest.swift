//
//  PickerDocEntityConfigTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/17.
//

import XCTest
import RustPB
import LarkModel
// swiftlint:disable all
final class PickerDocEntityConfigTest: XCTestCase {
    func testCodable() {
        let config = PickerConfig.DocEntityConfig(belongUser: .belong(["123"]))
        let data = try! JSONEncoder().encode(config)
        let string = String(data: data, encoding: .utf8)!
        XCTAssertFalse(string.isEmpty)
        let result = try! JSONDecoder().decode(PickerConfig.DocEntityConfig.self, from: data)
        if case .belong(let ids) = result.belongUser {
            XCTAssertEqual(ids, ["123"])
        } else {
            XCTFail()
        }
    }
}
// swiftlint:enable all
