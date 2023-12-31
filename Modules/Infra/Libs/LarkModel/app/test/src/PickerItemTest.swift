//
//  PickerItemTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/15.
//

import XCTest
import LarkModel
// swiftlint:disable all
final class PickerItemTest: XCTestCase {

    func testCodable() {
        let item = PickerItem(meta: .chatter(.init(id: "123")))
        let data = try! JSONEncoder().encode(item)
        XCTAssertFalse(data.isEmpty)
        let newItem = try! JSONDecoder().decode(PickerItem.self, from: data)
        XCTAssertEqual(newItem.id, "123")
    }


}
// swiftlint:enable all
