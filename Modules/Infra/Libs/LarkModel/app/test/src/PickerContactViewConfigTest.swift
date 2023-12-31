//
//  PickerContactViewConfigTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/5.
//

import XCTest
import LarkModel
// swiftlint:disable all
final class PickerContactViewConfigTest: XCTestCase {
    typealias OwnedGroup = PickerContactViewConfig.OwnedGroup
    typealias External = PickerContactViewConfig.External
    typealias Organization = PickerContactViewConfig.Organization

    func testConfigToJson() {
        let config = PickerContactViewConfig(entries: [
            OwnedGroup(),
            External(),
            Organization()
        ])
        let json = try! JSONEncoder().encode(config)
        let jsonString = String(data: json, encoding: .utf8)
        XCTAssertFalse(jsonString!.isEmpty)
    }

    func testJsonToConfig() {
        let config = PickerContactViewConfig(entries: [
            OwnedGroup(),
            External(),
            Organization()
        ])
        let json = try! JSONEncoder().encode(config)
        let jsonString = String(data: json, encoding: .utf8)!
//        let jsonString = "{\"entries\":{\"external\":[{\"type\":\"external\"}],\"organization\":[{\"type\":\"organization\"}]}}"
        let result = try! JSONDecoder().decode(PickerContactViewConfig.self, from: jsonString.data(using: .utf8)!)
        XCTAssertEqual(result.entries.count, 3)
    }
}
// swiftlint:enable all
